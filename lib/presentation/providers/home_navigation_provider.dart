import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls navigation between the major workspaces displayed on the home page.
class HomeNavigationNotifier extends StateNotifier<int> {
  HomeNavigationNotifier() : super(fsaIndex);

  /// Index for the Finite State Automaton workspace.
  static const int fsaIndex = 0;

  /// Index for the Grammar workspace.
  static const int grammarIndex = 1;

  /// Index for the Pushdown Automaton workspace.
  static const int pdaIndex = 2;

  /// Index for the Turing Machine workspace.
  static const int tmIndex = 3;

  /// Index for the Regular Expression workspace.
  static const int regexIndex = 4;

  /// Index for the Pumping Lemma workspace.
  static const int pumpingLemmaIndex = 5;

  /// Updates the currently visible workspace.
  void setIndex(int index) {
    if (index == state) {
      return;
    }
    state = index;
  }

  /// Convenience method that switches to the FSA workspace.
  void goToFsa() => setIndex(fsaIndex);
}

/// Provides the current navigation index for the home page.
final homeNavigationProvider =
    StateNotifierProvider<HomeNavigationNotifier, int>(
      (ref) => HomeNavigationNotifier(),
    );
