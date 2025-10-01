(function () {
  'use strict';

  const HIGHLIGHT_COLORS = {
    state: 'rgba(33, 150, 243, 0.85)',
    transition: 'rgba(255, 193, 7, 0.85)',
  };

  const activeAnimations = new Map(); // HTMLElement -> Animation
  const desiredKeys = new Set(); // kind:id currently requested

  function cssEscape(value) {
    if (window.CSS && typeof window.CSS.escape === 'function') {
      return window.CSS.escape(value);
    }
    return value.replace(/([\.\#\[\]:])/g, '\\$1');
  }

  function buildSelectors(id, kind) {
    const safeId = cssEscape(id);
    return [
      `[data-${kind}-id="${id}"]`,
      `[data-id="${id}"]`,
      `#${safeId}`,
      `#${kind}-${safeId}`,
      `.draw2d-${kind}-${safeId}`,
    ];
  }

  function findTargets(id, kind) {
    const selectors = buildSelectors(id, kind);
    const elements = new Set();
    selectors.forEach((selector) => {
      document.querySelectorAll(selector).forEach((element) => {
        elements.add(element);
      });
    });
    return Array.from(elements);
  }

  function cancelAnimation(element) {
    const animation = activeAnimations.get(element);
    if (animation) {
      animation.cancel();
      activeAnimations.delete(element);
    }
  }

  function finishHighlight(element) {
    cancelAnimation(element);
    element.style.filter = '';
    element.style.opacity = '';
    element.style.willChange = '';
    delete element.dataset.draw2dHighlightKey;
  }

  function fadeOut(element) {
    cancelAnimation(element);
    const fade = element.animate(
      [
        {
          filter: element.style.filter || 'drop-shadow(0 0 0 rgba(0,0,0,0))',
          opacity: element.style.opacity || 1,
        },
        { filter: 'drop-shadow(0 0 0 rgba(0,0,0,0))', opacity: 1 },
      ],
      { duration: 200, easing: 'ease-out', fill: 'forwards' },
    );

    fade.addEventListener('finish', () => {
      finishHighlight(element);
    });
    activeAnimations.set(element, fade);
  }

  function pulse(element, key, kind) {
    cancelAnimation(element);
    element.dataset.draw2dHighlightKey = key;
    element.style.willChange = 'filter, opacity';

    const color = HIGHLIGHT_COLORS[kind] || 'rgba(33, 150, 243, 0.85)';
    const animation = element.animate(
      [
        { filter: `drop-shadow(0 0 0 ${color})`, opacity: 1 },
        { filter: `drop-shadow(0 0 12px ${color})`, opacity: 0.85 },
        { filter: `drop-shadow(0 0 0 ${color})`, opacity: 1 },
      ],
      { duration: 1200, easing: 'ease-in-out', iterations: Infinity },
    );

    activeAnimations.set(element, animation);
  }

  function updateDesiredKeys(states, transitions) {
    desiredKeys.clear();
    states.forEach((id) => desiredKeys.add(`state:${id}`));
    transitions.forEach((id) => desiredKeys.add(`transition:${id}`));
  }

  function reconcileHighlights(states, transitions) {
    const targets = new Map(); // key -> {kind, id}

    states.forEach((id) => {
      const key = `state:${id}`;
      targets.set(key, { kind: 'state', id });
    });
    transitions.forEach((id) => {
      const key = `transition:${id}`;
      targets.set(key, { kind: 'transition', id });
    });

    // Fade out highlights that are no longer desired.
    Array.from(activeAnimations.keys()).forEach((element) => {
      const key = element.dataset.draw2dHighlightKey;
      if (!key || !targets.has(key)) {
        fadeOut(element);
      }
    });

    // Apply highlights for new keys.
    targets.forEach(({ kind, id }, key) => {
      const existing = Array.from(activeAnimations.keys()).some(
        (element) => element.dataset.draw2dHighlightKey === key,
      );
      if (existing) {
        return;
      }

      const elements = findTargets(id, kind);
      elements.forEach((element) => {
        pulse(element, key, kind);
      });
    });
  }

  function clearHighlights() {
    Array.from(activeAnimations.keys()).forEach((element) => {
      fadeOut(element);
    });
    desiredKeys.clear();
  }

  function extractIds(value) {
    if (!Array.isArray(value)) {
      return [];
    }
    return value.filter((entry) => typeof entry === 'string');
  }

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || typeof data !== 'object') {
      return;
    }

    const { type, payload } = data;

    if (type === 'highlight') {
      const states = new Set(extractIds(payload && payload.states));
      const transitions = new Set(
        extractIds(payload && payload.transitions),
      );

      if (states.size === 0 && transitions.size === 0) {
        clearHighlights();
        return;
      }

      updateDesiredKeys(states, transitions);
      reconcileHighlights(states, transitions);
    } else if (type === 'clear_highlight') {
      clearHighlights();
    }
  });

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') {
      clearHighlights();
    }
  });
})();
