(function () {
  const CANVAS_ID = 'canvas';
  const STATE_DIAMETER = 60;
  const STATE_RADIUS = STATE_DIAMETER / 2;
  const canvasElement = document.getElementById(CANVAS_ID);
  let canvasInstance = null;
  const stateFigures = new Map();
  const transitionFigures = new Map();
  const highlightedStates = new Set();
  const highlightedTransitions = new Set();
  const moveQueue = new Map();
  let moveTimer = null;
  let currentModelType = 'fsa';

  const HIGHLIGHT_STROKE_WIDTH = 4;
  const HIGHLIGHT_STATE_COLOR = '#ff9800';
  const HIGHLIGHT_STATE_BACKGROUND = '#fff3e0';
  const HIGHLIGHT_TRANSITION_COLOR = '#ff9800';
  const HIGHLIGHT_TRANSITION_STROKE = 3;

  function sendMessage(type, payload) {
    const message = JSON.stringify({ type, payload });
    if (window.JFlutterBridge && window.JFlutterBridge.postMessage) {
      window.JFlutterBridge.postMessage(message);
    } else if (window.Draw2DFlutterBridge && window.Draw2DFlutterBridge.postMessage) {
      window.Draw2DFlutterBridge.postMessage(message);
    }
  }

  function ensureCanvas() {
    if (canvasInstance) {
      return canvasInstance;
    }

    canvasInstance = new draw2d.Canvas(CANVAS_ID);
    canvasInstance.setScrollArea('#' + CANVAS_ID);
    canvasInstance.installEditPolicy(
      new draw2d.policy.connection.DragConnectionCreatePolicy({
        createConnection: function () {
          return new draw2d.Connection({
            stroke: 2,
            color: '#546e7a',
            router: new draw2d.layout.connection.SplineConnectionRouter(),
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

// <<<<<<< codex/add-draw2d-backed-pda-canvas-widget
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
      } else {
        sendMessage('transition.add', {
          id: `t_${Date.now()}`,
          fromStateId: sourceData.sourceId,
          toStateId: targetData.sourceId,
          label: '',
        });
      }
// =======
      sendMessage('transition.add', {
        id: `t_${Date.now()}`,
        fromStateId: sourceData.sourceId,
        toStateId: targetData.sourceId,
        readSymbol: '',
        writeSymbol: '',
        direction: 'R',
      });
// >>>>>>> 003-ui-improvement-taskforce

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

    return canvasInstance;
  }

  function clearCanvas() {
    const canvas = ensureCanvas();
    canvas.getLines().each(function (_, line) {
      line.remove();
    });
    canvas.getFigures().each(function (_, figure) {
      figure.remove();
    });
    stateFigures.clear();
    transitionFigures.clear();
    highlightedStates.clear();
    highlightedTransitions.clear();
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
    const position = state.position || {};
    const x = typeof position.x === 'number' ? position.x : 0;
    const y = typeof position.y === 'number' ? position.y : 0;

    const baseStroke = 2;
    const baseColor = state.isInitial ? '#3949ab' : '#1e88e5';
    const baseBackground = state.isAccepting ? '#c8e6c9' : '#ffffff';

    const figure = new draw2d.shape.basic.Circle({
      diameter: STATE_DIAMETER,
      stroke: baseStroke,
      color: baseColor,
      bgColor: baseBackground,
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

    const label = new draw2d.shape.basic.Label({
      text: state.label,
      fontColor: '#263238',
      padding: 5,
      stroke: 0,
      bgColor: '#ffffff',
    });
    label.setSelectable(false);
    figure.add(label, new draw2d.layout.locator.CenterLocator());

    figure.on('dragend', function () {
      scheduleMove(state.sourceId, figure);
    });

    figure.on('dblclick', function () {
      const current = label.getText();
      const result = window.prompt('State label', current);
      if (typeof result === 'string' && result !== current) {
        sendMessage('state.label', {
          id: state.sourceId,
          label: result,
        });
      }
    });

    canvas.add(figure);
    stateFigures.set(state.id, {
      figure: figure,
      label: label,
      sourceId: state.sourceId,
      baseStyle: {
        stroke: baseStroke,
        color: baseColor,
        bgColor: baseBackground,
      },
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

    const baseStroke = 2;
    const baseColor = '#546e7a';

    const connection = new draw2d.Connection({
      stroke: baseStroke,
      color: baseColor,
      router: new draw2d.layout.connection.SplineConnectionRouter(),
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
        connection.addPoint(new draw2d.geo.Point(point.x, point.y));
      }
    }

    const isPda = isPdaTransition(transition);
    const labelText = isPda
      ? formatPdaTransitionLabel(transition)
      : transition.label;

    const label = new draw2d.shape.basic.Label({
// <<<<<<< codex/add-draw2d-backed-pda-canvas-widget
      text: labelText,
// =======
      text: formatTransitionLabel(transition),
// >>>>>>> 003-ui-improvement-taskforce
      fontColor: '#263238',
      padding: 4,
      bgColor: '#ffffff',
      stroke: 0,
    });
    label.setSelectable(false);
    connection.add(
      label,
      new draw2d.layout.locator.ManhattanMidpointLocator(),
    );

    connection.on('dblclick', function () {
// <<<<<<< codex/add-draw2d-backed-pda-canvas-widget
      const entry = transitionFigures.get(transition.id);
      if (!entry) {
        return;
      }

      if (isPdaTransition(entry.data)) {
        const metadata = promptForPdaTransition(entry.data);
        if (!metadata) {
          return;
        }
        entry.data = {
          ...entry.data,
          readSymbol: metadata.readSymbol,
          popSymbol: metadata.popSymbol,
          pushSymbol: metadata.pushSymbol,
          isLambdaInput: metadata.isLambdaInput,
          isLambdaPop: metadata.isLambdaPop,
          isLambdaPush: metadata.isLambdaPush,
        };
        const formatted = formatPdaTransitionLabel(entry.data);
        entry.data.label = formatted;
        label.setText(formatted);
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
      } else {
        const currentText = label.getText();
        const result = window.prompt('Transition label', currentText);
        if (typeof result === 'string' && result !== currentText) {
          entry.data.label = result;
          label.setText(result);
          sendMessage('transition.label', {
            id: entry.sourceId,
            label: result,
          });
        }
// =======
      const entry = transitionFigures.get(transition.id) || {};
      const currentRead = entry.readSymbol || transition.readSymbol || '';
      const currentWrite = entry.writeSymbol || transition.writeSymbol || '';
      const currentDirection = (entry.direction || transition.direction || 'R').toUpperCase();

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
// >>>>>>> 003-ui-improvement-taskforce
      }

      const normalisedDirection = (directionResult || 'R').trim().toUpperCase();

      const updatedData = {
        ...entry,
        readSymbol: readResult,
        writeSymbol: writeResult,
        direction: normalisedDirection,
      };

      label.setText(formatTransitionLabel(updatedData));
      transitionFigures.set(transition.id, {
        ...updatedData,
        connection: connection,
        label: label,
        sourceId: transition.sourceId,
        baseStyle: entry.baseStyle || {
          stroke: baseStroke,
          color: baseColor,
        },
      });

      sendMessage('transition.label', {
        id: transition.sourceId,
        readSymbol: readResult,
        writeSymbol: writeResult,
        direction: normalisedDirection,
        label: label.getText(),
      });
    });

    ensureCanvas().add(connection);
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
    }

    transitionFigures.set(transition.id, {
      connection: connection,
      label: label,
      sourceId: transition.sourceId,
      baseStyle: {
        stroke: baseStroke,
        color: baseColor,
      },
// <<<<<<< codex/add-draw2d-backed-pda-canvas-widget
      data: data,
// =======
      readSymbol: transition.readSymbol || '',
      writeSymbol: transition.writeSymbol || '',
      direction: (transition.direction || 'R').toUpperCase(),
// >>>>>>> 003-ui-improvement-taskforce
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

  function loadModel(model) {
    if (!model || !Array.isArray(model.states)) {
      return;
    }

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

  window.draw2dBridge = {
    loadModel: loadModel,
    highlight: highlight,
    clearHighlight: clearHighlight,
  };

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

    if (type === 'highlight') {
      highlight(payload || {});
    } else if (type === 'clear_highlight') {
      clearHighlight();
    }
  });
})();
