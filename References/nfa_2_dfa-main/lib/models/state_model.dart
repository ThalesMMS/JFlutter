class StateModel {
  final String name;
  final bool isFinal;

  const StateModel({required this.name, this.isFinal = false});

  StateModel copyWith({String? name, bool? isFinal}) {
    return StateModel(
      name: name ?? this.name,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  // تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'isFinal': isFinal};
  }

  // ساخت از JSON
  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      name: json['name'] as String,
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  // اعتبارسنجی
  bool get isValid {
    return name.isNotEmpty && name.trim() == name;
  }

  // برای مقایسه دو state
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateModel && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  // برای نمایش و debug
  @override
  String toString() {
    return 'State(name: $name, isFinal: $isFinal)';
  }

  // نمایش ساده برای UI
  String get displayName {
    return isFinal ? '$name (F)' : name;
  }
}

// کلاس کمکی برای مجموعه state ها
class StateSet {
  final Set<StateModel> states;

  const StateSet(this.states);

  // نام نمایشی برای مجموعه state ها (برای DFA)
  String get displayName {
    if (states.isEmpty) return '∅';
    final names = states.map((s) => s.name).toList()..sort();
    return '{${names.join(',')}}';
  }

  // آیا شامل final state هست؟
  bool get isFinal {
    return states.any((state) => state.isFinal);
  }

  // تبدیل به لیست نام‌ها
  List<String> get stateNames {
    return states.map((s) => s.name).toList()..sort();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateSet &&
        states.length == other.states.length &&
        states.every((s) => other.states.contains(s));
  }

  @override
  int get hashCode => Object.hashAll(stateNames);

  @override
  String toString() => displayName;
}
