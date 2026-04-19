part of graphview;

class GraphViewElement extends RenderObjectElement
    implements GraphChildManager {
  GraphViewElement(GraphViewWidget super.widget);

  @override
  GraphViewWidget get widget => super.widget as GraphViewWidget;

  @override
  RenderCustomLayoutBox get renderObject =>
      super.renderObject as RenderCustomLayoutBox;

  // Contains all children, including those that are keyed
  Map<Node, Element> _nodeToElement = <Node, Element>{};
  Map<Key, Element> _keyToElement = <Key, Element>{};

  // Used between startLayout() & endLayout() to compute the new values
  Map<Node, Element>? _newNodeToElement;
  Map<Key, Element>? _newKeyToElement;

  bool get _debugIsDoingLayout =>
      _newNodeToElement != null && _newKeyToElement != null;

  @override
  void performRebuild() {
    super.performRebuild();
    // Children list is updated during layout since we only know during layout
    // which children will be visible
    renderObject.markNeedsLayout();
  }

  @override
  void forgetChild(Element child) {
    assert(!_debugIsDoingLayout);
    super.forgetChild(child);
    _nodeToElement.remove(child.slot as Node);
    if (child.widget.key != null) {
      _keyToElement.remove(child.widget.key);
    }
  }

  @override
  void insertRenderObjectChild(RenderBox child, Node slot) {
    renderObject._insertChild(child, slot);
  }

  @override
  void moveRenderObjectChild(RenderBox child, Node oldSlot, Node newSlot) {
    renderObject._moveChild(child, from: oldSlot, to: newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, Node slot) {
    renderObject._removeChild(child, slot);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _nodeToElement.values.forEach(visitor);
  }

  // ---- GraphChildManager implementation ----

  @override
  void startLayout() {
    assert(!_debugIsDoingLayout);
    _newNodeToElement = <Node, Element>{};
    _newKeyToElement = <Key, Element>{};
  }

  @override
  void buildChild(Node node) {
    assert(_debugIsDoingLayout);
    owner!.buildScope(this, () {
      final newWidget = widget.delegate.build(node);
      if (newWidget == null) {
        return;
      }

      final oldElement = _retrieveOldElement(newWidget, node);
      final newChild = updateChild(oldElement, newWidget, node);

      if (newChild != null) {
        // Ensure we are not overwriting an existing child
        assert(_newNodeToElement![node] == null);
        _newNodeToElement![node] = newChild;
        if (newWidget.key != null) {
          // Ensure we are not overwriting an existing key
          assert(_newKeyToElement![newWidget.key!] == null);
          _newKeyToElement![newWidget.key!] = newChild;
        }
      }
    });
  }

  @override
  void reuseChild(Node node) {
    assert(_debugIsDoingLayout);
    final elementToReuse = _nodeToElement.remove(node);
    assert(
      elementToReuse != null,
      'Expected to re-use an element at $node, but none was found.',
    );
    _newNodeToElement![node] = elementToReuse!;
    if (elementToReuse.widget.key != null) {
      assert(_keyToElement.containsKey(elementToReuse.widget.key));
      assert(_keyToElement[elementToReuse.widget.key] == elementToReuse);
      _newKeyToElement![elementToReuse.widget.key!] =
          _keyToElement.remove(elementToReuse.widget.key)!;
    }
  }

  Element? _retrieveOldElement(Widget newWidget, Node node) {
    if (newWidget.key != null) {
      final result = _keyToElement.remove(newWidget.key);
      if (result != null) {
        _nodeToElement.remove(result.slot as Node);
      }
      return result;
    }

    final potentialOldElement = _nodeToElement[node];
    if (potentialOldElement != null && potentialOldElement.widget.key == null) {
      return _nodeToElement.remove(node);
    }
    return null;
  }

  @override
  void endLayout() {
    assert(_debugIsDoingLayout);

    // Unmount all elements that have not been reused in the layout cycle
    for (final element in _nodeToElement.values) {
      if (element.widget.key == null) {
        // If it has a key, we handle it below
        updateChild(element, null, null);
      } else {
        assert(_keyToElement.containsValue(element));
      }
    }
    for (final element in _keyToElement.values) {
      assert(element.widget.key != null);
      updateChild(element, null, null);
    }

    _nodeToElement = _newNodeToElement!;
    _keyToElement = _newKeyToElement!;
    _newNodeToElement = null;
    _newKeyToElement = null;
    assert(!_debugIsDoingLayout);

    centerNodeWhileToggling();
  }

  void centerNodeWhileToggling() {
    widget.delegate.controller?.jumpToFocusedNode();
  }
}
