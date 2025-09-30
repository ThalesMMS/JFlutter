import 'constants.dart';
import 'exceptions.dart';

sealed class State<T> {
  final String name;
  bool isInitial;
  bool isFinal;

  State({required this.name, this.isInitial = false, this.isFinal = false});

  final Map<String, T> _transitions = {};

  Map<String, T> get transitions => _transitions;

  void setTransition(MapEntry<String, T> transition) =>
      _transitions.putIfAbsent(transition.key, () => transition.value);

  void setTransitions(List<MapEntry<String, T>> transitions) =>
      _transitions.addEntries(transitions);
}

class NonDeterministicState extends State<Set<NonDeterministicState>> {
  NonDeterministicState({required super.name, super.isInitial, super.isFinal});

  Set<NonDeterministicState> executeTransition(String input) =>
      transitions[input] ?? transitions[epsilon] ?? {};
}

class DeterministicState extends State<DeterministicState> {
  DeterministicState({required super.name, super.isInitial, super.isFinal});

  DeterministicState executeTransition(String input) {
    if (transitions.isEmpty) throw InvalidTransitionException();

    final hasValidTransition =
        transitions.containsKey(input) || transitions.containsKey(epsilon);

    if (!hasValidTransition) throw InvalidInputException();

    return transitions[input] ?? transitions[epsilon]!;
  }
}
