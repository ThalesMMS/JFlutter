import 'package:flutter/foundation.dart';

/// Returns whether the current platform can host the Draw2D WebView.
bool isDraw2dWebViewSupported() {
  if (kIsWeb) {
    return false;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}
