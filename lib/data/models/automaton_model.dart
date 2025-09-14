import '../../core/entities/automaton_entity.dart';

/// Data model for automaton persistence
/// This model handles the conversion between domain entities and data storage
class AutomatonModel {
  final String id;
  final String name;
  final List<String> alphabet;
  final List<StateModel> states;
  final Map<String, List<String>> transitions;
  final String? initialId;
  final int nextId;
  final String type;

  const AutomatonModel({
    required this.id,
    required this.name,
    required this.alphabet,
    required this.states,
    required this.transitions,
    this.initialId,
    required this.nextId,
    required this.type,
  });

  /// Converts from domain entity to data model
  factory AutomatonModel.fromEntity(AutomatonEntity entity) {
    return AutomatonModel(
      id: entity.id,
      name: entity.name,
      alphabet: entity.alphabet.toList(),
      states: entity.states.map((s) => StateModel.fromEntity(s)).toList(),
      transitions: entity.transitions,
      initialId: entity.initialId,
      nextId: entity.nextId,
      type: entity.type.name,
    );
  }

  /// Converts from data model to domain entity
  AutomatonEntity toEntity() {
    return AutomatonEntity(
      id: id,
      name: name,
      alphabet: alphabet.toSet(),
      states: states.map((s) => s.toEntity()).toList(),
      transitions: transitions,
      initialId: initialId,
      nextId: nextId,
      type: AutomatonType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => AutomatonType.dfa,
      ),
    );
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alphabet': alphabet,
      'states': states.map((s) => s.toJson()).toList(),
      'transitions': transitions,
      'initialId': initialId,
      'nextId': nextId,
      'type': type,
    };
  }

  /// Creates from JSON
  factory AutomatonModel.fromJson(Map<String, dynamic> json) {
    return AutomatonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      alphabet: List<String>.from(json['alphabet'] as List),
      states: (json['states'] as List)
          .map((s) => StateModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      transitions: Map<String, List<String>>.from(
        (json['transitions'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            List<String>.from(value as List),
          ),
        ),
      ),
      initialId: json['initialId'] as String?,
      nextId: json['nextId'] as int,
      type: json['type'] as String,
    );
  }

  AutomatonModel copyWith({
    String? id,
    String? name,
    List<String>? alphabet,
    List<StateModel>? states,
    Map<String, List<String>>? transitions,
    String? initialId,
    int? nextId,
    String? type,
  }) {
    return AutomatonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      alphabet: alphabet ?? this.alphabet,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      initialId: initialId ?? this.initialId,
      nextId: nextId ?? this.nextId,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomatonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AutomatonModel(id: $id, name: $name, type: $type)';
}

/// Data model for state persistence
class StateModel {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  const StateModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isFinal,
  });

  /// Converts from domain entity to data model
  factory StateModel.fromEntity(StateEntity entity) {
    return StateModel(
      id: entity.id,
      name: entity.name,
      x: entity.x,
      y: entity.y,
      isInitial: entity.isInitial,
      isFinal: entity.isFinal,
    );
  }

  /// Converts from data model to domain entity
  StateEntity toEntity() {
    return StateEntity(
      id: id,
      name: name,
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
    );
  }

  /// Converts to JSON for persistence
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

  /// Creates from JSON
  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isInitial: json['isInitial'] as bool,
      isFinal: json['isFinal'] as bool,
    );
  }

  StateModel copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
  }) {
    return StateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StateModel(id: $id, name: $name)';
}
