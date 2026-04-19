part of graphview;

abstract class GraphChildManager {
  void startLayout();

  void buildChild(Node node);

  void reuseChild(Node node);

  void endLayout();
}
