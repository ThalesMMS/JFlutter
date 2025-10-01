// <<<<<<< codex/document-bridge-envelope-and-message-schemas
(function () {
  const SUPPORTED_VERSION = 1;

  function ensureEnvelope(rawEnvelope) {
    try {
      const envelope =
        typeof rawEnvelope === 'string' ? JSON.parse(rawEnvelope) : rawEnvelope;
      if (!envelope || typeof envelope !== 'object') {
        console.warn('[Draw2D][JS] Ignored malformed envelope', rawEnvelope);
        return null;
      }
      if (typeof envelope.version !== 'number') {
        console.warn('[Draw2D][JS] Missing version on envelope', envelope);
        return null;
      }
      if (envelope.version > SUPPORTED_VERSION) {
        console.warn(
          `[Draw2D][JS] Unsupported envelope version ${envelope.version}`,
          envelope,
        );
        return null;
      }
      return envelope;
    } catch (error) {
      console.error('[Draw2D][JS] Failed to parse envelope', rawEnvelope, error);
      return null;
    }
  }

  function emitToFlutter(type, payload) {
    const envelope = {
      type,
      version: SUPPORTED_VERSION,
      payload,
      id: `js-${Date.now()}-${Math.random().toString(16).slice(2)}`,
      timestamp: new Date().toISOString(),
    };
    console.log(`[Draw2D][JS] ⇒ ${type}`, envelope);
    if (window.Draw2DBridge && typeof window.Draw2DBridge.postMessage === 'function') {
      window.Draw2DBridge.postMessage(JSON.stringify(envelope));
    } else {
      console.warn('[Draw2D][JS] Draw2DBridge.postMessage is unavailable');
    }
  }

  window.Draw2DHost = window.Draw2DHost || {};
  window.Draw2DHost.receiveMessage = function receiveMessage(rawEnvelope) {
    const envelope = ensureEnvelope(rawEnvelope);
    if (!envelope) {
      return;
    }
    console.log(`[Draw2D][JS] ⇐ ${envelope.type}`, envelope);
    switch (envelope.type) {
      case 'load_model':
        console.log('[Draw2D][JS] Loading model', envelope.payload);
        break;
      case 'highlight':
        console.log('[Draw2D][JS] Highlight request', envelope.payload);
        break;
      case 'clear_highlight':
        console.log('[Draw2D][JS] Clear highlight command received');
        break;
      case 'patch':
        console.log('[Draw2D][JS] Applying patch operations', envelope.payload);
        break;
      default:
        console.log('[Draw2D][JS] Unhandled command', envelope);
        break;
    }
  };

  window.Draw2DTest = {
    triggerSamples() {
      emitToFlutter('node_added', {
        id: 'n1',
        label: 'q0',
        position: { x: 160, y: 96 },
      });
      emitToFlutter('node_moved', {
        id: 'n1',
        position: { x: 220, y: 140 },
      });
      emitToFlutter('edge_added', {
        id: 'e1',
        from: 'n1',
        to: 'n2',
        label: 'a',
      });
      emitToFlutter('label_edited', {
        id: 'n1',
        entityType: 'state',
        label: 'q1',
      });
    },
  };
})();
// =======
// <<<<<<< codex/add-draw2d-mapping-and-event-handling
(function () {
  const CANVAS_ID = 'canvas';
  const canvasElement = document.getElementById(CANVAS_ID);
  let canvasInstance = null;
  const stateFigures = new Map();
  const transitionFigures = new Map();
  const moveQueue = new Map();
  let moveTimer = null;

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

      sendMessage('transition.add', {
        id: `t_${Date.now()}`,
        fromStateId: sourceData.sourceId,
        toStateId: targetData.sourceId,
        label: '',
      });

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
  }

  function scheduleMove(sourceId, figure) {
    moveQueue.set(sourceId, {
      id: sourceId,
      x: figure.getX(),
      y: figure.getY(),
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

  function createStateFigure(state) {
    const canvas = ensureCanvas();
    const figure = new draw2d.shape.basic.Circle({
      diameter: 60,
      stroke: 2,
      color: state.isInitial ? '#3949ab' : '#1e88e5',
      bgColor: state.isAccepting ? '#c8e6c9' : '#ffffff',
      x: state.position.x,
      y: state.position.y,
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
    stateFigures.set(state.id, { figure: figure, label: label });
  }

  function createTransitionFigure(transition) {
    const from = stateFigures.get(transition.from);
    const to = stateFigures.get(transition.to);
    if (!from || !to) {
      return;
    }

    const connection = new draw2d.Connection({
      stroke: 2,
      color: '#546e7a',
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

    const label = new draw2d.shape.basic.Label({
      text: transition.label,
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
      const current = label.getText();
      const result = window.prompt('Transition label', current);
      if (typeof result === 'string' && result !== current) {
        sendMessage('transition.label', {
          id: transition.sourceId,
          label: result,
        });
      }
    });

    ensureCanvas().add(connection);
    transitionFigures.set(transition.id, { connection: connection, label: label });
  }

  function loadModel(model) {
    if (!model || !Array.isArray(model.states)) {
      return;
    }

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
  };
})();
// =======
const READY_MESSAGE = 'Draw2D placeholder booted';

function emitReadySignal(message) {
  if (window.Draw2dReadyChannel &&
      typeof window.Draw2dReadyChannel.postMessage === 'function') {
    window.Draw2dReadyChannel.postMessage(message);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  console.log(READY_MESSAGE);
  emitReadySignal(READY_MESSAGE);
});

// Simulate Draw2D boot sequence placeholder
setTimeout(() => {
  const placeholder = document.getElementById('draw2d-placeholder');
  if (!placeholder) {
    return;
  }

  placeholder.querySelector('p').textContent =
    'Draw2D placeholder is ready.';
  placeholder.classList.add('ready');
}, 300);
// >>>>>>> 003-ui-improvement-taskforce
// >>>>>>> 003-ui-improvement-taskforce
