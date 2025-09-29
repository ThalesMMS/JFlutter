/// DTO for serializing automata data
class AutomatonDto {
  final String id;
  final String name;
  final String type;
  final List<String> alphabet;
  final List<StateDto> states;
  final Map<String, List<String>> transitions;
  final String? initialId;
  final int nextId;

  const AutomatonDto({
    required this.id,
    required this.name,
    required this.type,
    required this.alphabet,
    required this.states,
    required this.transitions,
    this.initialId,
    required this.nextId,
  });

  factory AutomatonDto.fromJson(Map<String, dynamic> json) {
    return AutomatonDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      alphabet: List<String>.from(json['alphabet'] as List),
      states: (json['states'] as List)
          .map((s) => StateDto.fromJson(s as Map<String, dynamic>))
          .toList(),
      transitions: (json['transitions'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      initialId: json['initialId'] as String?,
      nextId: json['nextId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'alphabet': alphabet,
      'states': states.map((s) => s.toJson()).toList(),
      'transitions': transitions,
      'initialId': initialId,
      'nextId': nextId,
    };
  }
}

/// DTO for serializing state data
class StateDto {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  const StateDto({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
  });

  factory StateDto.fromJson(Map<String, dynamic> json) {
    return StateDto(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isInitial: json['isInitial'] as bool? ?? false,
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isFinal': isFinal,
    };
  }
}

/// DTO for JFLAP XML structure
class JflapStructureDto {
  final String type;
  final JflapAutomatonDto automaton;

  const JflapStructureDto({
    required this.type,
    required this.automaton,
  });

  factory JflapStructureDto.fromJson(Map<String, dynamic> json) {
    return JflapStructureDto(
      type: json['type'] as String,
      automaton:
          JflapAutomatonDto.fromJson(json['automaton'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'automaton': automaton.toJson(),
    };
  }
}

/// DTO for JFLAP automaton structure
class JflapAutomatonDto {
  final List<JflapStateDto> states;
  final List<JflapTransitionDto> transitions;

  const JflapAutomatonDto({
    required this.states,
    required this.transitions,
  });

  factory JflapAutomatonDto.fromJson(Map<String, dynamic> json) {
    return JflapAutomatonDto(
      states: (json['states'] as List)
          .map((s) => JflapStateDto.fromJson(s as Map<String, dynamic>))
          .toList(),
      transitions: (json['transitions'] as List)
          .map((t) => JflapTransitionDto.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'states': states.map((s) => s.toJson()).toList(),
      'transitions': transitions.map((t) => t.toJson()).toList(),
    };
  }
}

/// DTO for JFLAP state
class JflapStateDto {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  const JflapStateDto({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
  });

  factory JflapStateDto.fromJson(Map<String, dynamic> json) {
    return JflapStateDto(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isInitial: json['isInitial'] as bool? ?? false,
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isFinal': isFinal,
    };
  }
}

/// DTO for JFLAP transition
class JflapTransitionDto {
  final String from;
  final String to;
  final String read;

  const JflapTransitionDto({
    required this.from,
    required this.to,
    required this.read,
  });

  factory JflapTransitionDto.fromJson(Map<String, dynamic> json) {
    return JflapTransitionDto(
      from: json['from'] as String,
      to: json['to'] as String,
      read: json['read'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'read': read,
    };
  }
}
