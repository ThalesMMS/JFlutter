/// Fallback implementation used on non-web platforms.
class Draw2DBridgePlatform {
  const Draw2DBridgePlatform();

  void postMessage(String type, Map<String, dynamic> payload) {}
}

Draw2DBridgePlatform createDraw2DBridgePlatform() {
  return const Draw2DBridgePlatform();
}
