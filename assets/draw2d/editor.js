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
