// <<<<<<< codex/enhance-editor.js-with-new-features
const SVG_NS = 'http://www.w3.org/2000/svg';
const STATE_RADIUS = 36;
const SELF_LOOP_OFFSET = 48;
const VIEWBOX_SIZE = { width: 1200, height: 800 };

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const createSvg = (tag, attributes = {}) => {
  const element = document.createElementNS(SVG_NS, tag);
  for (const [key, value] of Object.entries(attributes)) {
    if (value !== undefined && value !== null) {
      element.setAttribute(key, value);
    }
  }
  return element;
};

class LabelEditor {
  constructor(root) {
    this.root = root;
    this.dialog = root.querySelector('.editor-dialog');
    this.input = root.querySelector('#label-editor-input');
    this.title = root.querySelector('#label-editor-title');
    this.cancelButton = root.querySelector('button[data-action="cancel"]');
    this.saveButton = root.querySelector('button[data-action="save"]');
    this.activeContext = null;

    this.cancelButton.addEventListener('click', () => this.close());
    this.saveButton.addEventListener('click', () => this._submit());
    this.root.addEventListener('click', (event) => {
      if (event.target === this.root) {
        this.close();
      }
    });
    this.input.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
        this._submit();
      } else if (event.key === 'Escape') {
        this.close();
      }
    });
  }

  open({ title, value, onSubmit }) {
    this.activeContext = { onSubmit };
    this.title.textContent = title;
    this.input.value = value ?? '';
    this.root.classList.remove('hidden');
    requestAnimationFrame(() => {
      this.input.focus({ preventScroll: true });
      this.input.select();
    });
  }

  close() {
    this.activeContext = null;
    this.root.classList.add('hidden');
  }

  _submit() {
    if (!this.activeContext) {
      return;
    }
    const value = this.input.value.trim();
    this.activeContext.onSubmit?.(value);
    this.close();
  }
}

class AutomatonEditor {
  constructor() {
    this.svg = document.getElementById('editor-canvas');
    this.toolbar = document.getElementById('toolbar');
    this.statusOverlay = document.getElementById('status-overlay');
    this.marqueeEl = document.getElementById('marquee');
    this.labelEditor = new LabelEditor(
      document.getElementById('label-editor'),
    );

    this.automaton = {
      states: new Map(),
      transitions: new Map(),
      alphabet: new Set(),
      viewport: { pan: { x: 0, y: 0 }, zoom: 1 },
    };

    this.routingMode = 'bezier';
    this.selectedStates = new Set();
    this.selectedTransitions = new Set();
    this.undoStack = [];
    this.redoStack = [];
    this.historyLimit = 60;
    this.dragContext = null;
    this.interaction = null;
    this.viewBox = {
      x: 0,
      y: 0,
      width: VIEWBOX_SIZE.width,
      height: VIEWBOX_SIZE.height,
    };
    this._dragFrameRequested = false;
    this._statusTimeout = null;

    this._setupEventHandlers();
    this._applyViewBox();
  }

  handleMessage(event) {
    const data = event.data;
    if (!data || typeof data !== 'object') {
      return;
    }

    switch (data.type) {
      case 'load_automaton':
        this._loadAutomaton(data.payload || {});
        break;
      case 'apply_patch':
        this.applyPatch(data.payload || {}, { pushHistory: false });
        break;
      case 'set_routing':
        this.setRoutingMode(data.mode || 'bezier', { silent: true });
        break;
      default:
        break;
    }
  }

  setRoutingMode(mode, { silent = false } = {}) {
    if (mode !== 'bezier' && mode !== 'manhattan') {
      return;
    }
    this.routingMode = mode;
    this.toolbar
      .querySelectorAll('button[data-routing]')
      .forEach((button) => {
        button.classList.toggle('active', button.dataset.routing === mode);
      });
    this.render();
    if (!silent) {
      window.parent?.postMessage(
        { type: 'routing_changed', payload: { mode } },
        '*',
      );
      this._showStatus(`${mode === 'bezier' ? 'Bézier' : 'Manhattan'} routing`);
    }
  }

  applyPatch(patch, { pushHistory = true } = {}) {
    const previousSnapshot = this._serialize();
    this._applyPatchLocally(patch);
    this.render();
    if (pushHistory) {
      const currentSnapshot = this._serialize();
      const diff = computePatch(previousSnapshot, currentSnapshot);
      if (!isPatchEmpty(diff)) {
        this._pushUndo(previousSnapshot);
        this._emitPatch(diff);
      }
    }
  }

  undo() {
    if (this.undoStack.length === 0) {
      return;
    }
    const snapshot = this.undoStack.pop();
    const current = this._serialize();
    this.redoStack.push(current);
    const patch = computePatch(current, snapshot);
    this._applySnapshot(snapshot);
    this.render();
    if (!isPatchEmpty(patch)) {
      this._emitPatch(patch);
    }
    this._showStatus('Undo');
  }

  redo() {
    if (this.redoStack.length === 0) {
      return;
    }
    const snapshot = this.redoStack.pop();
    const current = this._serialize();
    this.undoStack.push(current);
    const patch = computePatch(current, snapshot);
    this._applySnapshot(snapshot);
    this.render();
    if (!isPatchEmpty(patch)) {
      this._emitPatch(patch);
    }
    this._showStatus('Redo');
  }

  render() {
    const defs = this.svg.querySelector('defs')?.cloneNode(true);
    this.svg.textContent = '';
    if (defs) {
      this.svg.appendChild(defs);
    }

    const background = createSvg('rect', {
      x: this.viewBox.x,
      y: this.viewBox.y,
      width: this.viewBox.width,
      height: this.viewBox.height,
      fill: 'transparent',
    });
    background.classList.add('canvas-background');
    this.svg.appendChild(background);

    const transitionsLayer = createSvg('g', { class: 'transitions-layer' });
    const statesLayer = createSvg('g', { class: 'states-layer' });
    const arrowsLayer = createSvg('g', { class: 'initial-layer' });

    this._renderTransitions(transitionsLayer);
    this._renderStates(statesLayer, arrowsLayer);

    this.svg.appendChild(transitionsLayer);
    this.svg.appendChild(arrowsLayer);
    this.svg.appendChild(statesLayer);
  }

  _renderStates(layer, arrowLayer) {
    for (const state of this.automaton.states.values()) {
      const group = createSvg('g', {
        class: 'node',
        'data-id': state.id,
      });
      if (this.selectedStates.has(state.id)) {
        group.classList.add('selected');
      }

      const outline = createSvg('circle', {
        class: 'state-outline',
        cx: state.x,
        cy: state.y,
        r: STATE_RADIUS,
      });
      group.appendChild(outline);

      if (state.isAccepting) {
        const inner = createSvg('circle', {
          class: 'state-inner',
          cx: state.x,
          cy: state.y,
          r: STATE_RADIUS - 6,
        });
        group.appendChild(inner);
      }

      const label = createSvg('text', {
        class: 'state-label',
        x: state.x,
        y: state.y + 1,
      });
      label.textContent = state.label;
      group.appendChild(label);

      group.addEventListener('mousedown', (event) =>
        this._beginStateDrag(event, state.id),
      );
      group.addEventListener('dblclick', (event) => {
        event.stopPropagation();
        this._openStateLabelEditor(state);
      });

      layer.appendChild(group);

      if (state.isInitial) {
        const arrow = this._createInitialArrow(state);
        arrowLayer.appendChild(arrow);
      }
    }
  }

  _renderTransitions(layer) {
    const grouped = new Map();
    for (const transition of this.automaton.transitions.values()) {
      const key = `${transition.from}->${transition.to}`;
      if (!grouped.has(key)) {
        grouped.set(key, []);
      }
      grouped.get(key).push(transition);
    }

    for (const transition of this.automaton.transitions.values()) {
      const from = this.automaton.states.get(transition.from);
      const to = this.automaton.states.get(transition.to);
      if (!from || !to) continue;

      const groupKey = `${transition.from}->${transition.to}`;
      const siblings = grouped.get(groupKey) || [];
      const index = siblings.indexOf(transition);
      const geometry = this._computeTransitionGeometry(
        from,
        to,
        transition,
        index,
        siblings.length,
      );

      const group = createSvg('g', {
        class: 'transition',
        'data-id': transition.id,
      });
      if (this.selectedTransitions.has(transition.id)) {
        group.classList.add('selected');
      }

      const path = createSvg('path', {
        class: 'transition-path',
        d: geometry.path,
      });
      group.appendChild(path);

      const label = createSvg('text', {
        class: 'transition-label',
        x: geometry.label.x,
        y: geometry.label.y,
      });

      const parts = [];
      if (transition.labels.length > 0) {
        parts.push(transition.labels.join(', '));
      }
      if (transition.lambdaSymbol) {
        parts.push(transition.lambdaSymbol);
      }
      label.textContent = parts.join(', ');
      group.appendChild(label);

      group.addEventListener('mousedown', (event) =>
        this._handleTransitionPointer(event, transition.id),
      );
      label.addEventListener('dblclick', (event) => {
        event.stopPropagation();
        this._openTransitionLabelEditor(transition);
      });

      layer.appendChild(group);
    }
  }

  _computeTransitionGeometry(from, to, transition, index, count) {
    if (from.id === to.id) {
      return this._computeSelfLoopGeometry(from, index);
    }

    if (this.routingMode === 'manhattan') {
      return this._computeManhattanGeometry(from, to, index, count);
    }

    const dx = to.x - from.x;
    const dy = to.y - from.y;
    const distance = Math.hypot(dx, dy) || 1;
    const ux = dx / distance;
    const uy = dy / distance;
    const start = {
      x: from.x + ux * STATE_RADIUS,
      y: from.y + uy * STATE_RADIUS,
    };
    const end = {
      x: to.x - ux * STATE_RADIUS,
      y: to.y - uy * STATE_RADIUS,
    };

    const normal = { x: -uy, y: ux };
    const curvature = 60 + count * 12;
    const offset = (index - (count - 1) / 2) * curvature;
    const midpoint = {
      x: (start.x + end.x) / 2,
      y: (start.y + end.y) / 2,
    };

    const control = {
      x: midpoint.x + normal.x * offset,
      y: midpoint.y + normal.y * offset,
    };

    const path = `M ${start.x} ${start.y} Q ${control.x} ${control.y} ${end.x} ${end.y}`;
    const labelPoint = this._quadraticPoint(start, control, end, 0.5);
    const labelOffset = {
      x: normal.x * (offset >= 0 ? 18 : -18),
      y: normal.y * (offset >= 0 ? 18 : -18),
    };

    return {
      path,
      label: {
        x: labelPoint.x + labelOffset.x,
        y: labelPoint.y + labelOffset.y,
      },
    };
  }

  _computeSelfLoopGeometry(state, index) {
    const sweep = 60 + index * 12;
    const start = { x: state.x, y: state.y - STATE_RADIUS };
    const control1 = {
      x: state.x - SELF_LOOP_OFFSET,
      y: state.y - SELF_LOOP_OFFSET - sweep,
    };
    const control2 = {
      x: state.x + SELF_LOOP_OFFSET,
      y: state.y - SELF_LOOP_OFFSET - sweep,
    };
    const end = { x: state.x + 0.1, y: state.y - STATE_RADIUS };

    const path = `M ${start.x} ${start.y} C ${control1.x} ${control1.y} ${control2.x} ${control2.y} ${end.x} ${end.y}`;
    const label = {
      x: state.x,
      y: state.y - SELF_LOOP_OFFSET - sweep - 6,
    };

    return { path, label };
  }

  _computeManhattanGeometry(from, to, index, count) {
    const midX = (from.x + to.x) / 2;
    const direction = index - (count - 1) / 2;
    const offset = direction * 40;
    const start = {
      x: from.x + Math.sign(midX - from.x) * STATE_RADIUS,
      y: from.y,
    };
    const end = {
      x: to.x - Math.sign(to.x - midX) * STATE_RADIUS,
      y: to.y,
    };

    const path = [
      `M ${start.x} ${start.y}`,
      `L ${midX + offset} ${start.y}`,
      `L ${midX + offset} ${end.y}`,
      `L ${end.x} ${end.y}`,
    ].join(' ');

    return {
      path,
      label: { x: midX + offset, y: (start.y + end.y) / 2 - 12 },
    };
  }

  _quadraticPoint(start, control, end, t) {
    const oneMinusT = 1 - t;
    return {
      x:
        start.x * oneMinusT * oneMinusT +
        2 * control.x * oneMinusT * t +
        end.x * t * t,
      y:
        start.y * oneMinusT * oneMinusT +
        2 * control.y * oneMinusT * t +
        end.y * t * t,
    };
  }

  _createInitialArrow(state) {
    const startX = state.x - STATE_RADIUS - 50;
    const midX = state.x - STATE_RADIUS - 14;
    const y = state.y;
    return createSvg('path', {
      class: 'initial-arrow',
      d: `M ${startX} ${y} L ${midX} ${y}`,
    });
  }

  _setupEventHandlers() {
    this.toolbar.addEventListener('click', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLButtonElement)) {
        return;
      }
      const action = target.dataset.action;
      const routing = target.dataset.routing;
      if (action === 'undo') {
        this.undo();
      } else if (action === 'redo') {
        this.redo();
      } else if (routing) {
        this.setRoutingMode(routing);
      }
    });

    window.addEventListener('keydown', (event) => {
      if (event.ctrlKey || event.metaKey) {
        if (event.key.toLowerCase() === 'z') {
          event.preventDefault();
          if (event.shiftKey) {
            this.redo();
          } else {
            this.undo();
          }
        } else if (event.key.toLowerCase() === 'y') {
          event.preventDefault();
          this.redo();
        }
      }
    });

    this.svg.addEventListener('mousedown', (event) =>
      this._handleCanvasPointer(event),
    );
    window.addEventListener('mousemove', (event) =>
      this._handlePointerMove(event),
    );
    window.addEventListener('mouseup', (event) =>
      this._handlePointerUp(event),
    );
    this.svg.addEventListener('wheel', (event) => this._handleWheel(event));
  }

  _handleCanvasPointer(event) {
    if (event.target.closest('.node') || event.target.closest('.transition')) {
      return;
    }

    if (event.button === 1 || event.button === 2 || event.altKey) {
      this._beginPan(event);
      return;
    }

    if (event.button === 0) {
      this._beginMarquee(event);
    }
  }

  _beginPan(event) {
    event.preventDefault();
    const { x, y } = this._screenToWorld(event.clientX, event.clientY);
    this.interaction = {
      type: 'pan',
      origin: { x, y },
      startViewBox: { ...this.viewBox },
    };
    this.svg.style.cursor = 'grabbing';
  }

  _beginMarquee(event) {
    event.preventDefault();
    const { x, y } = this._screenToWorld(event.clientX, event.clientY);
    this.interaction = {
      type: 'marquee',
      origin: { x, y },
      current: { x, y },
    };
    this._updateMarquee();
  }

  _beginStateDrag(event, stateId) {
    if (event.button !== 0) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();

    const snapshot = this._serialize();
    const state = this.automaton.states.get(stateId);
    if (!state) {
      return;
    }
    const pointer = this._screenToWorld(event.clientX, event.clientY);
    this.dragContext = {
      stateId,
      snapshot,
      offset: { x: pointer.x - state.x, y: pointer.y - state.y },
    };
    this.svg.style.cursor = 'grabbing';
    if (!this.selectedStates.has(stateId)) {
      this.selectedStates.clear();
      this.selectedStates.add(stateId);
    }
  }

  _handleTransitionPointer(event, transitionId) {
    if (event.button !== 0) {
      return;
    }
    event.preventDefault();
    if (!event.shiftKey) {
      this.selectedTransitions.clear();
    }
    if (this.selectedTransitions.has(transitionId)) {
      this.selectedTransitions.delete(transitionId);
    } else {
      this.selectedTransitions.add(transitionId);
    }
    this.render();
  }

  _handlePointerMove(event) {
    if (this.dragContext) {
      const state = this.automaton.states.get(this.dragContext.stateId);
      if (!state) {
        return;
      }
      const pointer = this._screenToWorld(event.clientX, event.clientY);
      state.x = pointer.x - this.dragContext.offset.x;
      state.y = pointer.y - this.dragContext.offset.y;
      this._requestDragFrame();
      return;
    }

    if (!this.interaction) {
      return;
    }

    if (this.interaction.type === 'pan') {
      const pointer = this._screenToWorld(event.clientX, event.clientY);
      const dx = pointer.x - this.interaction.origin.x;
      const dy = pointer.y - this.interaction.origin.y;
      this.viewBox.x = this.interaction.startViewBox.x - dx;
      this.viewBox.y = this.interaction.startViewBox.y - dy;
      this._applyViewBox();
      return;
    }

    if (this.interaction.type === 'marquee') {
      const pointer = this._screenToWorld(event.clientX, event.clientY);
      this.interaction.current = pointer;
      this._updateMarquee();
    }
  }

  _handlePointerUp(event) {
    if (this.dragContext && event.button === 0) {
      const previous = this.dragContext.snapshot;
      this.dragContext = null;
      this.svg.style.cursor = 'default';
      this.render();
      const current = this._serialize();
      const patch = computePatch(previous, current);
      if (!isPatchEmpty(patch)) {
        this._pushUndo(previous);
        this._emitPatch(patch);
        this._showStatus('State moved');
      }
      return;
    }

    if (!this.interaction) {
      return;
    }

    if (this.interaction.type === 'pan') {
      this.interaction = null;
      this.svg.style.cursor = 'default';
      this._emitViewportPatch();
      return;
    }

    if (this.interaction.type === 'marquee') {
      this._selectWithinRect(
        this.interaction.origin,
        this.interaction.current,
        event.shiftKey,
      );
      this.interaction = null;
      this.marqueeEl.classList.add('hidden');
      this.render();
    }
  }

  _handleWheel(event) {
    event.preventDefault();
    const delta = -event.deltaY;
    const zoomFactor = delta > 0 ? 0.9 : 1.1;
    const newWidth = clamp(
      this.viewBox.width * zoomFactor,
      VIEWBOX_SIZE.width * 0.4,
      VIEWBOX_SIZE.width * 2.5,
    );
    const newHeight = clamp(
      this.viewBox.height * zoomFactor,
      VIEWBOX_SIZE.height * 0.4,
      VIEWBOX_SIZE.height * 2.5,
    );

    const pointer = this._screenToWorld(event.clientX, event.clientY);
    const dx = (pointer.x - this.viewBox.x) / this.viewBox.width;
    const dy = (pointer.y - this.viewBox.y) / this.viewBox.height;

    this.viewBox = {
      x: pointer.x - newWidth * dx,
      y: pointer.y - newHeight * dy,
      width: newWidth,
      height: newHeight,
    };
    this._applyViewBox();
    this._emitViewportPatch();
  }

  _emitViewportPatch() {
    this.automaton.viewport.pan = { x: this.viewBox.x, y: this.viewBox.y };
    this.automaton.viewport.zoom = VIEWBOX_SIZE.width / this.viewBox.width;
    this._emitPatch({
      viewport: {
        pan: { ...this.automaton.viewport.pan },
        zoom: this.automaton.viewport.zoom,
      },
    });
  }

  _selectWithinRect(origin, current, additive) {
    const left = Math.min(origin.x, current.x);
    const right = Math.max(origin.x, current.x);
    const top = Math.min(origin.y, current.y);
    const bottom = Math.max(origin.y, current.y);

    if (!additive) {
      this.selectedStates.clear();
    }

    for (const state of this.automaton.states.values()) {
      if (
        state.x >= left &&
        state.x <= right &&
        state.y >= top &&
        state.y <= bottom
      ) {
        this.selectedStates.add(state.id);
      }
    }
  }

  _updateMarquee() {
    if (!this.interaction || this.interaction.type !== 'marquee') {
      return;
    }
    const { origin, current } = this.interaction;
    const x = Math.min(origin.x, current.x);
    const y = Math.min(origin.y, current.y);
    const width = Math.abs(origin.x - current.x);
    const height = Math.abs(origin.y - current.y);

    this.marqueeEl.style.left = `${x}px`;
    this.marqueeEl.style.top = `${y}px`;
    this.marqueeEl.style.width = `${width}px`;
    this.marqueeEl.style.height = `${height}px`;
    this.marqueeEl.classList.toggle('hidden', width < 2 || height < 2);
  }

  _screenToWorld(clientX, clientY) {
    const rect = this.svg.getBoundingClientRect();
    const x = this.viewBox.x + ((clientX - rect.left) / rect.width) * this.viewBox.width;
    const y = this.viewBox.y + ((clientY - rect.top) / rect.height) * this.viewBox.height;
    return { x, y };
  }

  _applyViewBox() {
    this.svg.setAttribute(
      'viewBox',
      `${this.viewBox.x} ${this.viewBox.y} ${this.viewBox.width} ${this.viewBox.height}`,
    );
  }

  _pushUndo(snapshot) {
    this.undoStack.push(snapshot);
    if (this.undoStack.length > this.historyLimit) {
      this.undoStack.shift();
    }
    this.redoStack.length = 0;
  }

  _emitPatch(patch) {
    if (isPatchEmpty(patch)) {
      return;
    }
    window.parent?.postMessage({ type: 'patch', payload: patch }, '*');
  }

  _showStatus(message) {
    if (!this.statusOverlay) {
      return;
    }
    this.statusOverlay.textContent = message;
    this.statusOverlay.classList.remove('hidden');
    clearTimeout(this._statusTimeout);
    this._statusTimeout = setTimeout(() => {
      this.statusOverlay.classList.add('hidden');
    }, 1400);
  }

  _requestDragFrame() {
    if (this._dragFrameRequested) {
      return;
    }
    this._dragFrameRequested = true;
    requestAnimationFrame(() => {
      this._dragFrameRequested = false;
      this.render();
    });
  }

  _openStateLabelEditor(state) {
    const snapshot = this._serialize();
    this.labelEditor.open({
      title: 'Edit state label',
      value: state.label,
      onSubmit: (value) => {
        const newLabel = value || state.id;
        state.label = newLabel;
        this.render();
        const patch = computePatch(snapshot, this._serialize());
        if (!isPatchEmpty(patch)) {
          this._pushUndo(snapshot);
          this._emitPatch(patch);
          this._emitLabelEdited('state', state.id, newLabel);
          this._showStatus('State renamed');
        }
      },
    });
  }

  _openTransitionLabelEditor(transition) {
    const snapshot = this._serialize();
    const existing = [...transition.labels];
    if (transition.lambdaSymbol) {
      existing.push(transition.lambdaSymbol);
    }
    this.labelEditor.open({
      title: 'Edit transition labels',
      value: existing.join(', '),
      onSubmit: (value) => {
        const symbols = value
          .split(',')
          .map((entry) => entry.trim())
          .filter((entry) => entry.length > 0);
        transition.labels = symbols.filter((symbol) => symbol !== 'ε');
        transition.lambdaSymbol = symbols.includes('ε') ? 'ε' : null;
        this.render();
        const patch = computePatch(snapshot, this._serialize());
        if (!isPatchEmpty(patch)) {
          this._pushUndo(snapshot);
          this._emitPatch(patch);
          this._emitLabelEdited('transition', transition.id, value);
          this._showStatus('Transition label updated');
        }
      },
    });
  }

  _emitLabelEdited(kind, id, label) {
    window.parent?.postMessage(
      {
        type: 'label_edited',
        payload: { kind, id, label },
      },
      '*',
    );
  }

  _serialize() {
    return {
      routingMode: this.routingMode,
      viewport: {
        pan: { ...this.automaton.viewport.pan },
        zoom: this.automaton.viewport.zoom,
      },
      states: Array.from(this.automaton.states.values()).map((state) => ({
        id: state.id,
        label: state.label,
        x: state.x,
        y: state.y,
        isInitial: state.isInitial,
        isAccepting: state.isAccepting,
      })),
      transitions: Array.from(this.automaton.transitions.values()).map(
        (transition) => ({
          id: transition.id,
          from: transition.from,
          to: transition.to,
          labels: [...transition.labels],
          lambdaSymbol: transition.lambdaSymbol,
        }),
      ),
      alphabet: Array.from(this.automaton.alphabet),
    };
  }

  _applySnapshot(snapshot) {
    this.automaton.states = new Map(
      snapshot.states.map((state) => [state.id, { ...state }]),
    );
    this.automaton.transitions = new Map(
      snapshot.transitions.map((transition) => [transition.id, { ...transition }]),
    );
    this.automaton.alphabet = new Set(snapshot.alphabet);
    this.automaton.viewport = {
      pan: { ...snapshot.viewport.pan },
      zoom: snapshot.viewport.zoom,
    };
    this.viewBox = {
      x: this.automaton.viewport.pan.x,
      y: this.automaton.viewport.pan.y,
      width: VIEWBOX_SIZE.width / this.automaton.viewport.zoom,
      height: VIEWBOX_SIZE.height / this.automaton.viewport.zoom,
    };
    this._applyViewBox();
  }

  _applyPatchLocally(patch) {
    if (patch.states) {
      const { upsert = [], delete: deletions = [], meta } = patch.states;
      for (const data of upsert) {
        if (!data || !data.id) continue;
        const existing = this.automaton.states.get(data.id) || {
          id: data.id,
          label: data.label || data.id,
          x: Number(data.x) || 0,
          y: Number(data.y) || 0,
          isInitial: Boolean(data.isInitial),
          isAccepting: Boolean(data.isAccepting),
        };
        const updated = {
          ...existing,
          label: data.label ?? existing.label,
          x: data.x !== undefined ? Number(data.x) : existing.x,
          y: data.y !== undefined ? Number(data.y) : existing.y,
          isInitial:
            data.isInitial !== undefined
              ? Boolean(data.isInitial)
              : existing.isInitial,
          isAccepting:
            data.isAccepting !== undefined
              ? Boolean(data.isAccepting)
              : existing.isAccepting,
        };
        this.automaton.states.set(updated.id, updated);
      }
      for (const id of deletions) {
        this.automaton.states.delete(id);
        this.automaton.transitions = new Map(
          Array.from(this.automaton.transitions.entries()).filter(
            ([, transition]) =>
              transition.from !== id && transition.to !== id,
          ),
        );
      }
      if (meta && meta.initialId) {
        for (const state of this.automaton.states.values()) {
          state.isInitial = state.id === meta.initialId;
        }
      }
    }

    if (patch.transitions) {
      const { upsert = [], delete: deletions = [] } = patch.transitions;
      for (const data of upsert) {
        if (!data || !data.id) continue;
        const labels = Array.isArray(data.symbols)
          ? data.symbols.map((symbol) => symbol.toString()).filter((entry) => entry && entry !== 'ε')
          : this.automaton.transitions.get(data.id)?.labels || [];
        const lambdaSymbol = data.lambdaSymbol ||
          (Array.isArray(data.symbols) && data.symbols.includes('ε')
            ? 'ε'
            : this.automaton.transitions.get(data.id)?.lambdaSymbol || null);
        this.automaton.transitions.set(data.id, {
          id: data.id,
          from: data.from || data.fromState,
          to: data.to || data.toState,
          labels,
          lambdaSymbol,
        });
      }
      for (const id of deletions) {
        this.automaton.transitions.delete(id);
      }
    }

    if (patch.alphabet) {
      this.automaton.alphabet = new Set(
        Array.isArray(patch.alphabet)
          ? patch.alphabet.map((entry) => entry.toString())
          : [],
      );
    }

    if (patch.viewport) {
      const pan = patch.viewport.pan || {};
      this.automaton.viewport.pan = {
        x: Number(pan.x ?? this.automaton.viewport.pan.x),
        y: Number(pan.y ?? this.automaton.viewport.pan.y),
      };
      this.automaton.viewport.zoom =
        Number(patch.viewport.zoom ?? this.automaton.viewport.zoom) || 1;
      this.viewBox = {
        x: this.automaton.viewport.pan.x,
        y: this.automaton.viewport.pan.y,
        width: VIEWBOX_SIZE.width / this.automaton.viewport.zoom,
        height: VIEWBOX_SIZE.height / this.automaton.viewport.zoom,
      };
      this._applyViewBox();
    }
  }

  _loadAutomaton(payload) {
    this.undoStack = [];
    this.redoStack = [];
    this.selectedStates.clear();
    this.selectedTransitions.clear();

    const states = new Map();
    const accepting = new Set(payload.acceptingIds || []);
    const initialId = payload.initialId || null;

    (payload.states || []).forEach((state) => {
      const parsed = {
        id: state.id,
        label: state.label || state.id,
        x: Number(state.x) || 0,
        y: Number(state.y) || 0,
        isInitial: state.isInitial || state.id === initialId,
        isAccepting: state.isAccepting || accepting.has(state.id),
      };
      states.set(parsed.id, parsed);
    });

    const transitions = new Map();
    (payload.transitions || []).forEach((transition) => {
      transitions.set(transition.id, {
        id: transition.id,
        from: transition.from || transition.fromState,
        to: transition.to || transition.toState,
        labels: Array.isArray(transition.symbols)
          ? transition.symbols
              .map((symbol) => symbol.toString())
              .filter((entry) => entry && entry !== 'ε')
          : [],
        lambdaSymbol:
          transition.lambdaSymbol ||
          (Array.isArray(transition.symbols) &&
          transition.symbols.includes('ε')
            ? 'ε'
            : null),
      });
    });

    this.automaton = {
      states,
      transitions,
      alphabet: new Set(payload.alphabet || []),
      viewport: {
        pan: {
          x: payload.viewport?.pan?.x ?? 0,
          y: payload.viewport?.pan?.y ?? 0,
        },
        zoom: payload.viewport?.zoom ?? 1,
      },
    };

    this.viewBox = {
      x: this.automaton.viewport.pan.x,
      y: this.automaton.viewport.pan.y,
      width: VIEWBOX_SIZE.width / this.automaton.viewport.zoom,
      height: VIEWBOX_SIZE.height / this.automaton.viewport.zoom,
    };
    this._applyViewBox();
    this.render();
  }
}

function computePatch(previous, next) {
  const patch = {};
  const statePatch = diffStates(previous.states, next.states);
  if (statePatch.upsert.length || statePatch.delete.length || statePatch.meta) {
    patch.states = statePatch;
  }

  const transitionPatch = diffTransitions(previous.transitions, next.transitions);
  if (transitionPatch.upsert.length || transitionPatch.delete.length) {
    patch.transitions = transitionPatch;
  }

  if (
    previous.viewport.zoom !== next.viewport.zoom ||
    previous.viewport.pan.x !== next.viewport.pan.x ||
    previous.viewport.pan.y !== next.viewport.pan.y
  ) {
    patch.viewport = {
      zoom: next.viewport.zoom,
      pan: { ...next.viewport.pan },
    };
  }

  if (!arraysEqual(previous.alphabet, next.alphabet)) {
    patch.alphabet = [...next.alphabet];
  }

  return patch;
}

function diffStates(previousStates, nextStates) {
  const previousMap = new Map(previousStates.map((state) => [state.id, state]));
  const nextMap = new Map(nextStates.map((state) => [state.id, state]));

  const upsert = [];
  const deletions = [];
  let meta = null;

  for (const [id, state] of nextMap.entries()) {
    const previous = previousMap.get(id);
    if (
      !previous ||
      previous.label !== state.label ||
      previous.x !== state.x ||
      previous.y !== state.y ||
      previous.isInitial !== state.isInitial ||
      previous.isAccepting !== state.isAccepting
    ) {
      upsert.push({ ...state });
    }
    if (state.isInitial) {
      meta = { initialId: state.id };
    }
  }

  for (const id of previousMap.keys()) {
    if (!nextMap.has(id)) {
      deletions.push(id);
    }
  }

  return { upsert, delete: deletions, meta };
}

function diffTransitions(previousTransitions, nextTransitions) {
  const previousMap = new Map(previousTransitions.map((t) => [t.id, t]));
  const nextMap = new Map(nextTransitions.map((t) => [t.id, t]));

  const upsert = [];
  const deletions = [];

  for (const [id, transition] of nextMap.entries()) {
    const previous = previousMap.get(id);
    const labels = [...transition.labels];
    if (transition.lambdaSymbol) {
      labels.push('ε');
    }
    if (!previous) {
      upsert.push({ id, from: transition.from, to: transition.to, symbols: labels });
    } else {
      const previousLabels = [...previous.labels];
      if (previous.lambdaSymbol) {
        previousLabels.push('ε');
      }
      if (
        previous.from !== transition.from ||
        previous.to !== transition.to ||
        !arraysEqual(previousLabels, labels)
      ) {
        upsert.push({ id, from: transition.from, to: transition.to, symbols: labels });
      }
    }
  }

  for (const id of previousMap.keys()) {
    if (!nextMap.has(id)) {
      deletions.push(id);
    }
  }

  return { upsert, delete: deletions };
}

function arraysEqual(a, b) {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
}

function isPatchEmpty(patch) {
  if (!patch) return true;
  if (patch.states) {
    const { upsert = [], delete: deletions = [], meta } = patch.states;
    if (upsert.length || deletions.length || meta) {
      return false;
    }
  }
  if (patch.transitions) {
    const { upsert = [], delete: deletions = [] } = patch.transitions;
    if (upsert.length || deletions.length) {
      return false;
    }
  }
  if (patch.viewport) {
    return false;
  }
  if (patch.alphabet && patch.alphabet.length) {
    return false;
  }
  return true;
}

const editor = new AutomatonEditor();

window.addEventListener('message', (event) => editor.handleMessage(event));

window.parent?.postMessage({ type: 'editor_ready' }, '*');
// =======
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
// >>>>>>> 003-ui-improvement-taskforce
