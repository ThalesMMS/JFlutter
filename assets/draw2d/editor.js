(function () {
  const CANVAS_ID = 'canvas';
  const STATE_DIAMETER = 60;
  const STATE_RADIUS = STATE_DIAMETER / 2;
  const canvasElement = document.getElementById(CANVAS_ID);
  let canvasInstance = null;
  let hasLoggedMissingDraw2dWarning = false;
  const stateFigures = new Map();
  const transitionFigures = new Map();
  const highlightedStates = new Set();
  const highlightedTransitions = new Set();
  const moveQueue = new Map();
  let moveTimer = null;
  let pendingCanvasRetryHandle = null;
  let currentModelType = 'fsa';
  let pendingModel = null;
  const pendingCanvasTasks = [];
  let hasLoggedDraw2dDetected = false;

  const HIGHLIGHT_STROKE_WIDTH = 4;
  const HIGHLIGHT_STATE_COLOR = '#ff9800';
  const HIGHLIGHT_STATE_BACKGROUND = '#fff3e0';
  const HIGHLIGHT_TRANSITION_COLOR = '#ff9800';
  const HIGHLIGHT_TRANSITION_STROKE = 3;

  function logDebug(message, ...details) {
    try {
      console.info(`[Draw2D] ${message}`, ...details);
    } catch (_) {
      // Swallow logging failures silently.
    }
  }

  function postToFlutter(type, payload) {
    const serialized = JSON.stringify({ type, payload });
    let posted = false;
    try {
      if (window.JFlutterBridge && window.JFlutterBridge.postMessage) {
        window.JFlutterBridge.postMessage(serialized);
        posted = true;
      }
      if (!posted && window.Draw2DFlutterBridge && window.Draw2DFlutterBridge.postMessage) {
        window.Draw2DFlutterBridge.postMessage(serialized);
        posted = true;
      }
    } catch (error) {
      console.warn('[Draw2D] Failed to post message to Flutter', error);
    }
    return posted;
  }

  function sendLog(level, message, details) {
    const payload = { level, message };
    if (typeof details !== 'undefined') {
      payload.details = details;
    }
    logDebug(`LOG[${level}] ${message}`, details);
    postToFlutter('log', payload);
  }

  logDebug('Editor script boot initialised');
  sendLog('debug', 'Editor script boot initialised', {
    userAgent: navigator.userAgent,
    readyState: document.readyState,
    location: window.location.href,
  });

  function attemptDraw2dLoad() {
    if (window.draw2d && typeof window.draw2d.Canvas === 'function') {
      sendLog('debug', 'Draw2D runtime already present at boot');
      return;
    }

    const candidates = [
      'vendor/draw2d.js',
      './vendor/draw2d.js',
      '/assets/draw2d/vendor/draw2d.js',
      window.location.href.replace(/[^/]+$/, '') + 'vendor/draw2d.js',
    ];

    let attemptIndex = 0;

    function tryNext() {
      if (window.draw2d && typeof window.draw2d.Canvas === 'function') {
        sendLog('debug', 'Draw2D runtime became available before fetch attempts completed');
        return;
      }
      if (attemptIndex >= candidates.length) {
        sendLog('error', 'All draw2d runtime fetch attempts failed');
        return;
      }
      const path = candidates[attemptIndex++];
      sendLog('debug', 'Attempting to fetch Draw2D runtime', { path: path });
      fetch(path)
        .then(function (response) {
          if (!response.ok) {
            sendLog('warn', 'Draw2D runtime fetch returned non-200', {
              path: path,
              status: response.status,
            });
            tryNext();
            return;
          }
          response.text().then(function (source) {
            try {
              // eslint-disable-next-line no-eval
              eval(source);
              sendLog('info', 'Draw2D runtime loaded via fetch', { path: path });
            } catch (error) {
              sendLog('error', 'Failed to evaluate Draw2D runtime', {
                path: path,
                message: String(error && error.message ? error.message : error),
              });
              tryNext();
            }
          });
        })
        .catch(function (error) {
          sendLog('warn', 'Draw2D runtime fetch failed', {
            path: path,
            message: String(error && error.message ? error.message : error),
          });
          tryNext();
        });
    }

    tryNext();
  }

  attemptDraw2dLoad();

  function computeStateBaseStyle(flags) {
    return {
      stroke: 2,
      color: flags && flags.isInitial ? '#3949ab' : '#1e88e5',
      bgColor: flags && flags.isAccepting ? '#c8e6c9' : '#ffffff',
    };
  }

  function applyStateBaseStyle(entry) {
    if (!entry || !entry.figure) {
      return;
    }
    entry.figure.setStroke(entry.baseStyle.stroke);
    entry.figure.setColor(entry.baseStyle.color);
    entry.figure.setBackgroundColor(entry.baseStyle.bgColor);
  }

  function updateStateBaseStyle(entry) {
    if (!entry) {
      return;
    }
    entry.baseStyle = computeStateBaseStyle(entry.data);
    if (!highlightedStates.has(entry.sourceId)) {
      applyStateBaseStyle(entry);
    }
  }

  function removeTransitionEntry(entry) {
    if (!entry) {
      return;
    }
    if (entry.connection) {
      entry.connection.remove();
    }
    highlightedTransitions.delete(entry.sourceId);
    transitionFigures.delete(entry.draw2dId);
  }

  function removeStateEntry(entry) {
    if (!entry) {
      return;
    }
    const draw2dId = entry.draw2dId;
    if (entry.figure) {
      entry.figure.remove();
    }
    highlightedStates.delete(entry.sourceId);
    stateFigures.delete(draw2dId);

    const transitionsToDelete = [];
    transitionFigures.forEach(function (transitionEntry) {
      if (
        transitionEntry &&
        transitionEntry.data &&
        (transitionEntry.data.from === draw2dId ||
          transitionEntry.data.to === draw2dId)
      ) {
        transitionsToDelete.push(transitionEntry);
      }
    });

    transitionsToDelete.forEach(function (transitionEntry) {
      removeTransitionEntry(transitionEntry);
    });
  }

  function handleStateContextMenu(stateId, rawEvent) {
    const entry = stateFigures.get(stateId);
    if (!entry) {
      return;
    }

    const event = rawEvent && rawEvent.event ? rawEvent.event : rawEvent;
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }

    const message = [
      'State actions:',
      `1) Toggle initial (${entry.data.isInitial ? 'on' : 'off'})`,
      `2) Toggle accepting (${entry.data.isAccepting ? 'on' : 'off'})`,
      '3) Delete state',
    ].join('\n');

    const input = window.prompt(message, '');
    if (input === null) {
      return;
    }

    const normalized = String(input).trim().toLowerCase();
    if (normalized === '1' || normalized === 'initial' || normalized === 'toggle initial') {
      toggleStateInitial(entry);
    } else if (
      normalized === '2' ||
      normalized === 'accepting' ||
      normalized === 'toggle accepting'
    ) {
      toggleStateAccepting(entry);
    } else if (
      normalized === '3' ||
      normalized === 'delete' ||
      normalized === 'remove'
    ) {
      const shouldDelete = window.confirm(
        'Delete this state and its connected transitions?',
      );
      if (!shouldDelete) {
        return;
      }
      removeStateEntry(entry);
      sendMessage('state.remove', { id: entry.sourceId });
    }
  }

  function handleTransitionContextMenu(transitionId, rawEvent) {
    const entry = transitionFigures.get(transitionId);
    if (!entry) {
      return;
    }

    const event = rawEvent && rawEvent.event ? rawEvent.event : rawEvent;
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }

    const input = window.prompt('Transition actions:\n1) Delete transition', '');
    if (input === null) {
      return;
    }

    const normalized = String(input).trim().toLowerCase();
    if (normalized === '1' || normalized === 'delete' || normalized === 'remove') {
      const shouldDelete = window.confirm('Delete this transition?');
      if (!shouldDelete) {
        return;
      }
      removeTransitionEntry(entry);
      sendMessage('transition.remove', { id: entry.sourceId });
    }
  }

  function toggleStateInitial(entry) {
    if (!entry || !entry.data) {
      return;
    }
    const newInitial = !entry.data.isInitial;
    entry.data.isInitial = newInitial;

    if (newInitial) {
      stateFigures.forEach(function (otherEntry) {
        if (!otherEntry || otherEntry === entry || !otherEntry.data) {
          return;
        }
        if (otherEntry.data.isInitial) {
          otherEntry.data.isInitial = false;
          updateStateBaseStyle(otherEntry);
        }
      });
    }

    updateStateBaseStyle(entry);
    sendMessage('state.updateFlags', {
      id: entry.sourceId,
      isInitial: newInitial,
      isAccepting: entry.data.isAccepting,
    });
  }

  function toggleStateAccepting(entry) {
    if (!entry || !entry.data) {
      return;
    }
    const newAccepting = !entry.data.isAccepting;
    entry.data.isAccepting = newAccepting;
    updateStateBaseStyle(entry);
    sendMessage('state.updateFlags', {
      id: entry.sourceId,
      isInitial: entry.data.isInitial,
      isAccepting: newAccepting,
    });
  }

  function sendMessage(type, payload) {
    logDebug(`Sending message to Flutter: ${type}`, payload);
    postToFlutter(type, payload);
  }

  function notifyFlutterReady() {
    if (!canvasInstance) {
      logDebug('notifyFlutterReady skipped: canvas not yet available');
      sendLog('debug', 'notifyFlutterReady skipped: canvas not ready');
      return;
    }
    const readyPayload = JSON.stringify({ type: 'editor_ready', payload: {} });
    try {
      logDebug('Notifying Flutter that editor is ready');
      sendLog('info', 'Draw2D editor ready');
      if (window.JFlutterBridge && typeof window.JFlutterBridge.postMessage === 'function') {
        window.JFlutterBridge.postMessage(readyPayload);
      } else if (window.Draw2DFlutterBridge && typeof window.Draw2DFlutterBridge.postMessage === 'function') {
        window.Draw2DFlutterBridge.postMessage(readyPayload);
      }
    } catch (error) {
      console.warn('[Draw2D] Failed to notify Flutter about readiness', error);
    }
  }

  function flushPendingCanvasTasks() {
    logDebug(`Flushing ${pendingCanvasTasks.length} pending canvas task(s)`);
    if (pendingCanvasTasks.length > 0 && !canvasInstance) {
      sendLog('debug', 'Pending canvas tasks flushed without active canvas');
    }
    if (!canvasInstance || pendingCanvasTasks.length === 0) {
      return;
    }
    const tasks = pendingCanvasTasks.splice(0, pendingCanvasTasks.length);
    tasks.forEach(function (task) {
      try {
        task(canvasInstance);
      } catch (error) {
        console.error('[Draw2D] Deferred canvas task failed', error);
      }
    });
  }

  function ensureCanvas() {
    sendLog('debug', 'Ensuring canvas', {
      hasCanvas: Boolean(canvasInstance),
      hasDraw2d: typeof window.draw2d !== 'undefined',
      readyState: document.readyState,
    });
    if (canvasInstance) {
      logDebug('Canvas already initialised; flushing queued tasks');
      sendLog('debug', 'Canvas already initialised');
      flushPendingCanvasTasks();
      return canvasInstance;
    }

    if (typeof window.draw2d === 'undefined' || !window.draw2d || typeof window.draw2d.Canvas !== 'function') {
      if (!hasLoggedMissingDraw2dWarning) {
        console.warn('[Draw2D] Canvas requested before draw2d runtime was ready. Deferring command.');
        hasLoggedMissingDraw2dWarning = true;
      }
      if (!pendingCanvasRetryHandle) {
        logDebug('Scheduling retry while waiting for draw2d runtime');
        sendLog('warn', 'Draw2D runtime not yet available; scheduling retry', {
          readyState: document.readyState,
          hasDraw2d: typeof window.draw2d !== 'undefined',
        });
        pendingCanvasRetryHandle = window.setTimeout(function () {
          pendingCanvasRetryHandle = null;
          ensureCanvas();
          notifyFlutterReady();
        }, 100);
      }
      return null;
    }

    if (!hasLoggedDraw2dDetected) {
      hasLoggedDraw2dDetected = true;
      sendLog('info', 'Draw2D runtime detected', {
        version:
            window.draw2d && window.draw2d.VERSION ? window.draw2d.VERSION : null,
        sampleKeys: Object.keys(window.draw2d || {}).slice(0, 8),
      });
    }

    try {
      logDebug('Creating new draw2d canvas instance');
      sendLog('info', 'Creating Draw2D canvas instance');
      canvasInstance = new window.draw2d.Canvas(CANVAS_ID);
    } catch (error) {
      console.error('[Draw2D] Failed to create canvas instance', error);
      if (!pendingCanvasRetryHandle) {
        logDebug('Scheduling retry after canvas creation failure');
        sendLog('error', 'Failed to create Draw2D canvas instance; retry scheduled', {
          message: String(error && error.message ? error.message : error),
        });
        pendingCanvasRetryHandle = window.setTimeout(function () {
          pendingCanvasRetryHandle = null;
          ensureCanvas();
          notifyFlutterReady();
        }, 100);
      }
      return null;
    }

    hasLoggedMissingDraw2dWarning = false;
    if (pendingCanvasRetryHandle) {
      window.clearTimeout(pendingCanvasRetryHandle);
      pendingCanvasRetryHandle = null;
    }
    logDebug('Configuring canvas policies');
    sendLog('info', 'Draw2D canvas configured', {
      scrollArea: '#' + CANVAS_ID,
      clientWidth: canvasElement ? canvasElement.clientWidth : null,
      clientHeight: canvasElement ? canvasElement.clientHeight : null,
    });
    canvasInstance.setScrollArea('#' + CANVAS_ID);
    canvasInstance.installEditPolicy(
      new window.draw2d.policy.connection.DragConnectionCreatePolicy({
        createConnection: function () {
          return new window.draw2d.Connection({
            stroke: 2,
            color: '#546e7a',
            router: new window.draw2d.layout.connection.SplineConnectionRouter(),
          });
        },
      }),
    );

    canvasInstance.on('connect', function (_, event) {
      const connection = event.connection;
      if (!connection) {
        return;
      }
      const sourceFigure = connection.getSource()?.getParent();
      const targetFigure = connection.getTarget()?.getParent();
      if (!sourceFigure || !targetFigure) {
        return;
      }

      const sourceData = sourceFigure.getUserData() || {};
      const targetData = targetFigure.getUserData() || {};
      if (!sourceData.sourceId || !targetData.sourceId) {
        return;
      }

      if (currentModelType === 'pda') {
        const metadata = promptForPdaTransition();
        if (!metadata) {
          connection.remove();
          return;
        }
        sendMessage('transition.add', {
          id: `t_${Date.now()}`,
          fromStateId: sourceData.sourceId,
          toStateId: targetData.sourceId,
          label: metadata.label,
          readSymbol: metadata.readSymbol,
          popSymbol: metadata.popSymbol,
          pushSymbol: metadata.pushSymbol,
          isLambdaInput: metadata.isLambdaInput,
          isLambdaPop: metadata.isLambdaPop,
          isLambdaPush: metadata.isLambdaPush,
        });
      } else if (currentModelType === 'tm') {
        sendMessage('transition.add', {
          id: `t_${Date.now()}`,
          fromStateId: sourceData.sourceId,
          toStateId: targetData.sourceId,
          readSymbol: '',
          writeSymbol: '',
          direction: 'R',
        });
      } else {
        sendMessage('transition.add', {
          id: `t_${Date.now()}`,
          fromStateId: sourceData.sourceId,
          toStateId: targetData.sourceId,
          label: '',
        });
      }

      connection.remove();
    });

    canvasElement.addEventListener('dblclick', function (event) {
      if (!canvasInstance) {
        return;
      }

      const canvasPoint = canvasInstance.fromDocumentToCanvasCoordinate(
        event.clientX,
        event.clientY,
      );

      sendMessage('state.add', {
        id: `q_${Date.now()}`,
        label: `q${stateFigures.size}`,
        x: canvasPoint.x,
        y: canvasPoint.y,
      });
    });

    notifyFlutterReady();
    flushPendingCanvasTasks();
    renderPendingModel();
    return canvasInstance;
  }

  function withCanvas(task) {
    const canvas = ensureCanvas();
    if (canvas) {
      try {
        logDebug('Executing canvas task immediately');
        sendLog('debug', 'Executing canvas task immediately');
        task(canvas);
      } catch (error) {
        console.error('[Draw2D] Canvas task failed', error);
        sendLog('error', 'Canvas task failed', {
          message: String(error && error.message ? error.message : error),
        });
      }
      return canvas;
    }
    logDebug('Queueing canvas task until canvas is ready');
    sendLog('debug', 'Queueing canvas task until canvas is ready');
    pendingCanvasTasks.push(task);
    return null;
  }

  function clearCanvas() {
    withCanvas(function (canvas) {
      logDebug('Clearing existing canvas figures and lines');
      sendLog('info', 'Clearing Draw2D canvas');
      canvas.getLines().each(function (_, line) {
        line.remove();
      });
      canvas.getFigures().each(function (_, figure) {
        figure.remove();
      });
    });
    stateFigures.clear();
    transitionFigures.clear();
    highlightedStates.clear();
    highlightedTransitions.clear();
  }

  function getViewportRect() {
    const rect = canvasElement.getBoundingClientRect();
    return { left: rect.left, top: rect.top, width: rect.width, height: rect.height };
  }

  function addStateAtCenter() {
    withCanvas(function (canvas) {
      logDebug('Adding state at viewport centre');
      sendLog('info', 'Adding state at centre');
      const vp = getViewportRect();
      const cx = vp.left + vp.width / 2;
      const cy = vp.top + vp.height / 2;
      const point = canvas.fromDocumentToCanvasCoordinate(cx, cy);
      sendMessage('state.add', {
        id: `q_${Date.now()}`,
        label: `q${stateFigures.size}`,
        x: point.x,
        y: point.y,
      });
    });
  }

  function computeContentBounds() {
    const bounds = { left: Infinity, top: Infinity, right: -Infinity, bottom: -Infinity };
    let hasAny = false;
    stateFigures.forEach(function (entry) {
      if (!entry || !entry.figure) return;
      hasAny = true;
      const b = entry.figure.getBoundingBox();
      bounds.left = Math.min(bounds.left, b.x);
      bounds.top = Math.min(bounds.top, b.y);
      bounds.right = Math.max(bounds.right, b.x + b.w);
      bounds.bottom = Math.max(bounds.bottom, b.y + b.h);
    });
    transitionFigures.forEach(function (entry) {
      if (!entry || !entry.connection) return;
      hasAny = true;
      const b = entry.connection.getBoundingBox();
      bounds.left = Math.min(bounds.left, b.x);
      bounds.top = Math.min(bounds.top, b.y);
      bounds.right = Math.max(bounds.right, b.x + b.w);
      bounds.bottom = Math.max(bounds.bottom, b.y + b.h);
    });
    if (!hasAny) {
      return null;
    }
    return bounds;
  }

  function setZoomInternal(canvas, zoom, animate) {
    try {
      canvas.setZoom(zoom, !!animate);
    } catch (_) {
      // Ignore if zoom helpers are unavailable
    }
  }

  function getZoomInternal(canvas) {
    try {
      return typeof canvas.getZoom === 'function' ? canvas.getZoom() : 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  function setZoom(zoom, animate) {
    withCanvas(function (canvas) {
      logDebug(`Applying zoom ${zoom} (animate=${Boolean(animate)})`);
      sendLog('debug', 'Applying zoom', {
        zoom: zoom,
        animate: Boolean(animate),
      });
      setZoomInternal(canvas, zoom, animate);
    });
  }

  function zoomIn() {
    withCanvas(function (canvas) {
      const current = getZoomInternal(canvas);
      logDebug(`Zoom in requested; current=${current}`);
      sendLog('debug', 'Zoom in requested', { currentZoom: current });
      setZoomInternal(canvas, Math.min(current * 1.1, 4.0), true);
    });
  }

  function zoomOut() {
    withCanvas(function (canvas) {
      const current = getZoomInternal(canvas);
      logDebug(`Zoom out requested; current=${current}`);
      sendLog('debug', 'Zoom out requested', { currentZoom: current });
      setZoomInternal(canvas, Math.max(current / 1.1, 0.1), true);
    });
  }

  function resetView() {
    withCanvas(function (canvas) {
      logDebug('Resetting zoom to 1.0');
      sendLog('info', 'Resetting view to default zoom');
      setZoomInternal(canvas, 1.0, true);
    });
  }

  function fitToContent() {
    withCanvas(function (canvas) {
      const vp = getViewportRect();
      const content = computeContentBounds();
      if (!content) {
        logDebug('Fit to content requested but no content available; resetting view');
        sendLog('warn', 'Fit to content requested with no content; resetting view');
        setZoomInternal(canvas, 1.0, true);
        return;
      }
      logDebug('Fitting viewport to content bounds', content);
      sendLog('info', 'Fitting view to content', content);
      const contentWidth = Math.max(1, content.right - content.left);
      const contentHeight = Math.max(1, content.bottom - content.top);
      const padding = 40;
      const scaleX = (vp.width - padding) / contentWidth;
      const scaleY = (vp.height - padding) / contentHeight;
      const zoom = Math.max(0.1, Math.min(4.0, Math.min(scaleX, scaleY)));
      setZoomInternal(canvas, zoom, true);
      const centerX = content.left + contentWidth / 2;
      const centerY = content.top + contentHeight / 2;
      try {
        canvas.scrollTo(
          centerX - vp.width / (2 * zoom),
          centerY - vp.height / (2 * zoom),
        );
      } catch (_) {
        // Ignore if scroll helpers are unavailable
      }
    });
  }

  function scheduleMove(sourceId, figure) {
    moveQueue.set(sourceId, {
      id: sourceId,
      x: figure.getX() + STATE_RADIUS,
      y: figure.getY() + STATE_RADIUS,
    });

    if (moveTimer) {
      return;
    }

    moveTimer = setTimeout(function () {
      moveTimer = null;
      const updates = Array.from(moveQueue.values());
      moveQueue.clear();
      updates.forEach(function (update) {
        sendMessage('state.move', update);
      });
    }, 80);
  }

  function hasOwn(object, key) {
    return Object.prototype.hasOwnProperty.call(object || {}, key);
  }

  function isPdaTransition(transition) {
    if (currentModelType === 'pda') {
      return true;
    }
    if (!transition) {
      return false;
    }
    return (
      hasOwn(transition, 'readSymbol') ||
      hasOwn(transition, 'popSymbol') ||
      hasOwn(transition, 'pushSymbol') ||
      hasOwn(transition, 'isLambdaInput') ||
      hasOwn(transition, 'isLambdaPop') ||
      hasOwn(transition, 'isLambdaPush')
    );
  }

  function isTmTransition(transition) {
    if (currentModelType === 'tm') {
      return true;
    }
    if (!transition) {
      return false;
    }
    return (
      hasOwn(transition, 'readSymbol') ||
      hasOwn(transition, 'writeSymbol') ||
      hasOwn(transition, 'direction')
    );
  }

  function formatPdaTransitionLabel(data) {
    if (!data) {
      return '';
    }
    const read = data.isLambdaInput ? 'λ' : (data.readSymbol || '');
    const pop = data.isLambdaPop ? 'λ' : (data.popSymbol || '');
    const push = data.isLambdaPush ? 'λ' : (data.pushSymbol || '');
    return `${read}, ${pop}/${push}`;
  }

  function normaliseStackResponse(raw) {
    const text = typeof raw === 'string' ? raw.trim() : '';
    const lower = text.toLowerCase();
    const isLambda =
      text === 'λ' || lower === 'lambda' || lower === 'epsilon' || lower === 'eps';
    return {
      symbol: isLambda ? '' : text,
      isLambda: isLambda,
    };
  }

  function promptForPdaTransition(existing) {
    const readDefault = existing
      ? existing.isLambdaInput
        ? 'λ'
        : existing.readSymbol || ''
      : '';
    const readInput = window.prompt(
      'Input symbol (use λ for epsilon)',
      readDefault,
    );
    if (readInput === null) {
      return null;
    }
    const read = normaliseStackResponse(readInput);

    const popDefault = existing
      ? existing.isLambdaPop
        ? 'λ'
        : existing.popSymbol || 'Z'
      : 'Z';
    const popInput = window.prompt(
      'Stack pop symbol (use λ for epsilon)',
      popDefault,
    );
    if (popInput === null) {
      return null;
    }
    const pop = normaliseStackResponse(popInput);

    const pushDefault = existing
      ? existing.isLambdaPush
        ? 'λ'
        : existing.pushSymbol || ''
      : '';
    const pushInput = window.prompt(
      'Stack push symbol (use λ for epsilon)',
      pushDefault,
    );
    if (pushInput === null) {
      return null;
    }
    const push = normaliseStackResponse(pushInput);

    const metadata = {
      readSymbol: read.symbol,
      popSymbol: pop.symbol,
      pushSymbol: push.symbol,
      isLambdaInput: read.isLambda,
      isLambdaPop: pop.isLambda,
      isLambdaPush: push.isLambda,
    };
    metadata.label = formatPdaTransitionLabel(metadata);
    return metadata;
  }

  function createStateFigure(state) {
    const canvas = ensureCanvas();
    if (!canvas || !window.draw2d) {
      return null;
    }
    const position = state.position || {};
    const x = typeof position.x === 'number' ? position.x : 0;
    const y = typeof position.y === 'number' ? position.y : 0;

    const entryData = {
      id: state.id,
      sourceId: state.sourceId,
      label: state.label,
      isInitial: Boolean(state.isInitial),
      isAccepting: Boolean(state.isAccepting),
      position: { x: x, y: y },
    };
    const baseStyle = computeStateBaseStyle(entryData);

    const figure = new window.draw2d.shape.basic.Circle({
      diameter: STATE_DIAMETER,
      stroke: baseStyle.stroke,
      color: baseStyle.color,
      bgColor: baseStyle.bgColor,
      x: x,
      y: y,
    });

    figure.setUserData({
      type: 'state',
      id: state.id,
      sourceId: state.sourceId,
    });

    figure.createPort('input');
    figure.createPort('output');

    const label = new window.draw2d.shape.basic.Label({
      text: state.label,
      fontColor: '#263238',
      padding: 5,
      stroke: 0,
      bgColor: '#ffffff',
    });
    label.setSelectable(false);
    figure.add(label, new window.draw2d.layout.locator.CenterLocator());

    figure.on('dragend', function () {
      scheduleMove(state.sourceId, figure);
      const stored = stateFigures.get(state.id);
      if (stored && stored.data) {
        stored.data.position = {
          x: figure.getX(),
          y: figure.getY(),
        };
      }
    });

    figure.on('dblclick', function () {
      const current = label.getText();
      const result = window.prompt('State label', current);
      if (typeof result === 'string' && result !== current) {
        label.setText(result);
        const stored = stateFigures.get(state.id);
        if (stored && stored.data) {
          stored.data.label = result;
        }
        sendMessage('state.label', {
          id: state.sourceId,
          label: result,
        });
      }
    });

    figure.on('contextmenu', function (_, event) {
      handleStateContextMenu(state.id, event);
    });

    canvas.add(figure);
    stateFigures.set(state.id, {
      figure: figure,
      label: label,
      sourceId: state.sourceId,
      draw2dId: state.id,
      baseStyle: baseStyle,
      data: entryData,
    });
  }

  function formatTransitionLabel(transition) {
    if (!transition) {
      return '';
    }

    const read = (transition.readSymbol || '').trim();
    const write = (transition.writeSymbol || '').trim();
    const direction = (transition.direction || '').trim().toUpperCase();
    const readableRead = read.length > 0 ? read : '∅';
    const readableWrite = write.length > 0 ? write : '∅';
    const directionSymbol = direction === 'L'
      ? 'L'
      : direction === 'S'
        ? 'S'
        : 'R';

    return `${readableRead}/${readableWrite},${directionSymbol}`;
  }

  function createTransitionFigure(transition) {
    const from = stateFigures.get(transition.from);
    const to = stateFigures.get(transition.to);
    if (!from || !to) {
      return;
    }

    const canvas = ensureCanvas();
    if (!canvas || !window.draw2d) {
      return;
    }

    const baseStroke = 2;
    const baseColor = '#546e7a';

    const connection = new window.draw2d.Connection({
      stroke: baseStroke,
      color: baseColor,
      router: new window.draw2d.layout.connection.SplineConnectionRouter(),
    });
    connection.setUserData({
      type: 'transition',
      id: transition.id,
      sourceId: transition.sourceId,
    });

    connection.setSource(from.figure.getOutputPort(0));
    connection.setTarget(to.figure.getInputPort(0));

    if (transition.controlPoint) {
      const point = transition.controlPoint;
      if (typeof point.x === 'number' && typeof point.y === 'number') {
        connection.addPoint(new window.draw2d.geo.Point(point.x, point.y));
      }
    }

    const isPda = isPdaTransition(transition);
    const isTm = isTmTransition(transition);
    const labelText = isPda
      ? formatPdaTransitionLabel(transition)
      : isTm
        ? formatTransitionLabel(transition)
        : transition.label;

    const label = new window.draw2d.shape.basic.Label({
      text: labelText,
      fontColor: '#263238',
      padding: 4,
      bgColor: '#ffffff',
      stroke: 0,
    });
    label.setSelectable(false);
    connection.add(
      label,
      new window.draw2d.layout.locator.ManhattanMidpointLocator(),
    );

    connection.on('dblclick', function () {
      const entry = transitionFigures.get(transition.id);
      if (!entry) {
        return;
      }

      if (isPdaTransition(entry.data)) {
        const metadata = promptForPdaTransition(entry.data);
        if (!metadata) {
          return;
        }
        const updatedData = {
          ...entry.data,
          readSymbol: metadata.readSymbol,
          popSymbol: metadata.popSymbol,
          pushSymbol: metadata.pushSymbol,
          isLambdaInput: metadata.isLambdaInput,
          isLambdaPop: metadata.isLambdaPop,
          isLambdaPush: metadata.isLambdaPush,
        };
        const formatted = formatPdaTransitionLabel(updatedData);
        updatedData.label = formatted;
        entry.data = updatedData;
        label.setText(formatted);
        transitionFigures.set(transition.id, entry);
        sendMessage('transition.label', {
          id: entry.sourceId,
          label: formatted,
          readSymbol: metadata.readSymbol,
          popSymbol: metadata.popSymbol,
          pushSymbol: metadata.pushSymbol,
          isLambdaInput: metadata.isLambdaInput,
          isLambdaPop: metadata.isLambdaPop,
          isLambdaPush: metadata.isLambdaPush,
        });
        return;
      }

      if (isTmTransition(entry.data)) {
        const currentRead = entry.data.readSymbol || '';
        const currentWrite = entry.data.writeSymbol || '';
        const currentDirection = (entry.data.direction || 'R').toUpperCase();

        const readResult = window.prompt('Read symbol', currentRead);
        if (readResult === null) {
          return;
        }

        const writeResult = window.prompt('Write symbol', currentWrite);
        if (writeResult === null) {
          return;
        }

        const directionResult = window.prompt(
          'Direction (L, R, S)',
          currentDirection,
        );
        if (directionResult === null) {
          return;
        }

        const normalisedDirection = (directionResult || 'R')
          .trim()
          .toUpperCase();

        const updatedData = {
          ...entry.data,
          readSymbol: readResult,
          writeSymbol: writeResult,
          direction: normalisedDirection,
        };
        const formatted = formatTransitionLabel(updatedData);
        updatedData.label = formatted;
        entry.data = updatedData;
        label.setText(formatted);
        transitionFigures.set(transition.id, entry);

        sendMessage('transition.label', {
          id: entry.sourceId,
          readSymbol: readResult,
          writeSymbol: writeResult,
          direction: normalisedDirection,
          label: formatted,
        });
        return;
      }

      const currentText = entry.data && typeof entry.data.label === 'string'
        ? entry.data.label
        : label.getText();
      const result = window.prompt('Transition label', currentText);
      if (typeof result !== 'string' || result === currentText) {
        return;
      }

      entry.data = {
        ...entry.data,
        label: result,
      };
      label.setText(result);
      transitionFigures.set(transition.id, entry);
      sendMessage('transition.label', {
        id: entry.sourceId,
        label: result,
      });
    });

    connection.on('contextmenu', function (_, event) {
      handleTransitionContextMenu(transition.id, event);
    });

    canvas.add(connection);
    const data = {
      id: transition.id,
      sourceId: transition.sourceId,
      from: transition.from,
      to: transition.to,
      label: labelText,
    };

    if (isPda) {
      data.readSymbol = hasOwn(transition, 'readSymbol')
        ? transition.readSymbol
        : '';
      data.popSymbol = hasOwn(transition, 'popSymbol')
        ? transition.popSymbol
        : '';
      data.pushSymbol = hasOwn(transition, 'pushSymbol')
        ? transition.pushSymbol
        : '';
      data.isLambdaInput = hasOwn(transition, 'isLambdaInput')
        ? Boolean(transition.isLambdaInput)
        : false;
      data.isLambdaPop = hasOwn(transition, 'isLambdaPop')
        ? Boolean(transition.isLambdaPop)
        : false;
      data.isLambdaPush = hasOwn(transition, 'isLambdaPush')
        ? Boolean(transition.isLambdaPush)
        : false;
    } else if (isTm) {
      data.readSymbol = hasOwn(transition, 'readSymbol')
        ? transition.readSymbol || ''
        : '';
      data.writeSymbol = hasOwn(transition, 'writeSymbol')
        ? transition.writeSymbol || ''
        : '';
      data.direction = hasOwn(transition, 'direction')
        ? String(transition.direction || 'R').toUpperCase()
        : 'R';
      if (hasOwn(transition, 'tapeNumber')) {
        data.tapeNumber = transition.tapeNumber;
      }
    }

    transitionFigures.set(transition.id, {
      connection: connection,
      label: label,
      sourceId: transition.sourceId,
      draw2dId: transition.id,
      baseStyle: {
        stroke: baseStroke,
        color: baseColor,
      },
      data: data,
    });
  }

  function normaliseIds(values) {
    if (!Array.isArray(values)) {
      return [];
    }
    return values
      .map(function (value) {
        return typeof value === 'string' ? value.trim() : String(value || '').trim();
      })
      .filter(function (value) {
        return value.length > 0;
      });
  }

  function setStateHighlight(entry, shouldHighlight) {
    if (!entry || !entry.figure) {
      return;
    }
    if (shouldHighlight) {
      entry.figure.setStroke(HIGHLIGHT_STROKE_WIDTH);
      entry.figure.setColor(HIGHLIGHT_STATE_COLOR);
      entry.figure.setBackgroundColor(HIGHLIGHT_STATE_BACKGROUND);
      highlightedStates.add(entry.sourceId);
    } else {
      entry.figure.setStroke(entry.baseStyle.stroke);
      entry.figure.setColor(entry.baseStyle.color);
      entry.figure.setBackgroundColor(entry.baseStyle.bgColor);
      highlightedStates.delete(entry.sourceId);
    }
  }

  function setTransitionHighlight(entry, shouldHighlight) {
    if (!entry || !entry.connection) {
      return;
    }
    if (shouldHighlight) {
      entry.connection.setStroke(HIGHLIGHT_TRANSITION_STROKE);
      entry.connection.setColor(HIGHLIGHT_TRANSITION_COLOR);
      highlightedTransitions.add(entry.sourceId);
    } else {
      entry.connection.setStroke(entry.baseStyle.stroke);
      entry.connection.setColor(entry.baseStyle.color);
      highlightedTransitions.delete(entry.sourceId);
    }
  }

  function highlight(payload) {
    const stateIds = new Set(normaliseIds(payload && payload.states));
    const transitionIds = new Set(
      normaliseIds(payload && payload.transitions),
    );

    stateFigures.forEach(function (entry) {
      setStateHighlight(entry, stateIds.has(entry.sourceId));
    });

    transitionFigures.forEach(function (entry) {
      setTransitionHighlight(entry, transitionIds.has(entry.sourceId));
    });
  }

  function clearHighlight() {
    stateFigures.forEach(function (entry) {
      setStateHighlight(entry, false);
    });
    transitionFigures.forEach(function (entry) {
      setTransitionHighlight(entry, false);
    });
  }

  function renderModel(model) {
    currentModelType = typeof model.type === 'string' ? model.type : 'fsa';
    clearHighlight();
    clearCanvas();
    model.states.forEach(function (state) {
      createStateFigure(state);
    });
    (model.transitions || []).forEach(function (transition) {
      createTransitionFigure(transition);
    });
  }

  function renderPendingModel() {
    if (!pendingModel) {
      return;
    }
    withCanvas(function () {
      logDebug('Rendering pending automaton model', pendingModel);
      sendLog('info', 'Rendering automaton model', {
        states: Array.isArray(pendingModel.states)
          ? pendingModel.states.length
          : null,
        transitions: Array.isArray(pendingModel.transitions)
          ? pendingModel.transitions.length
          : null,
        type: pendingModel.type || 'fsa',
      });
      renderModel(pendingModel);
    });
  }

  function loadModel(model) {
    if (!model || !Array.isArray(model.states)) {
      logDebug('loadModel called with invalid model payload', model);
      sendLog('error', 'Received invalid automaton model payload', {
        hasStates: Boolean(model && Array.isArray(model.states)),
      });
      return;
    }

    logDebug('Received model from Flutter', model);
    sendLog('info', 'Received automaton model from Flutter', {
      states: model.states.length,
      transitions: Array.isArray(model.transitions)
        ? model.transitions.length
        : null,
      type: model.type || 'fsa',
    });
    pendingModel = model;
    renderPendingModel();
  }

  window.draw2dBridge = {
    loadModel: loadModel,
    highlight: highlight,
    clearHighlight: clearHighlight,
    addStateAtCenter: addStateAtCenter,
    zoomIn: zoomIn,
    zoomOut: zoomOut,
    fitToContent: fitToContent,
    resetView: resetView,
  };

  // Signal readiness to Flutter once the bridge and canvas are available
  try {
    logDebug('Bootstrapping canvas immediately after load');
    sendLog('debug', 'Bootstrapping canvas immediately after load');
    ensureCanvas();
    notifyFlutterReady();
    renderPendingModel();
  } catch (_) {
    // Ignore readiness failure
  }

  window.addEventListener('message', function (event) {
    const data = event && event.data;
    if (!data) {
      return;
    }

    let payload = data.payload;
    let type = data.type;

    if (typeof data === 'string') {
      try {
        const parsed = JSON.parse(data);
        type = parsed.type;
        payload = parsed.payload;
      } catch (error) {
        return;
      }
    }

    logDebug(`Received window message type=${type}`, payload);

    logDebug(`Received window message type=${type}`, payload);

    if (type === 'highlight') {
      highlight(payload || {});
    } else if (type === 'clear_highlight') {
      clearHighlight();
    } else if (type === 'zoom_in') {
      zoomIn();
    } else if (type === 'zoom_out') {
      zoomOut();
    } else if (type === 'fit_content') {
      fitToContent();
    } else if (type === 'reset_view') {
      resetView();
    } else if (type === 'add_state_center') {
      addStateAtCenter();
    }
  });

  window.addEventListener('load', function () {
    sendLog('info', 'Window load event fired', {
      hasDraw2d: typeof window.draw2d !== 'undefined',
      readyState: document.readyState,
      canvasMetrics: canvasElement
        ? { width: canvasElement.clientWidth, height: canvasElement.clientHeight }
        : null,
    });
  });
})();
