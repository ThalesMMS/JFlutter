import 'dart:convert';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import '../models/automaton_schema.dart';
import '../models/jflap_file.dart';
import '../models/example_library.dart';

/// JSON serialization service for automaton models
class JSONSerializer {
  /// Serialize any automaton model to JSON
  static Map<String, dynamic> serialize(dynamic model) {
    if (model is FiniteAutomaton) {
      return _serializeFiniteAutomaton(model);
    } else if (model is PushdownAutomaton) {
      return _serializePushdownAutomaton(model);
    } else if (model is TuringMachine) {
      return _serializeTuringMachine(model);
    } else if (model is ContextFreeGrammar) {
      return _serializeContextFreeGrammar(model);
    } else if (model is RegularExpression) {
      return _serializeRegularExpression(model);
    } else if (model is JFLAPFile) {
      return model.toJson();
    } else if (model is ExampleLibrary) {
      return model.toJson();
    } else {
      throw ArgumentError('Unsupported model type: ${model.runtimeType}');
    }
  }

  /// Deserialize JSON to automaton model
  static T deserialize<T>(Map<String, dynamic> json) {
    if (T == FiniteAutomaton) {
      return _deserializeFiniteAutomaton(json) as T;
    } else if (T == PushdownAutomaton) {
      return _deserializePushdownAutomaton(json) as T;
    } else if (T == TuringMachine) {
      return _deserializeTuringMachine(json) as T;
    } else if (T == ContextFreeGrammar) {
      return _deserializeContextFreeGrammar(json) as T;
    } else if (T == RegularExpression) {
      return _deserializeRegularExpression(json) as T;
    } else if (T == JFLAPFile) {
      return JFLAPFile.fromJson(json) as T;
    } else if (T == ExampleLibrary) {
      return ExampleLibrary.fromJson(json) as T;
    } else {
      throw ArgumentError('Unsupported type: $T');
    }
  }

  /// Serialize to JSON string
  static String serializeToString(dynamic model) {
    return jsonEncode(serialize(model));
  }

  /// Deserialize from JSON string
  static T deserializeFromString<T>(String jsonString) {
    return deserialize<T>(jsonDecode(jsonString));
  }

  /// Validate JSON against schema
  static bool validateAgainstSchema(
    Map<String, dynamic> json,
    AutomatonSchema schema,
  ) {
    // Check required fields
    for (final field in schema.requiredFields) {
      if (!json.containsKey(field)) {
        return false;
      }
    }

    // Check type
    if (json['type'] != schema.type.name) {
      return false;
    }

    // Apply validation rules
    for (final rule in schema.validationRules.entries) {
      if (!_validateRule(json, rule.key, rule.value)) {
        return false;
      }
    }

    return true;
  }

  /// Private serialization methods
  static Map<String, dynamic> _serializeFiniteAutomaton(FiniteAutomaton fa) {
    return {
      'type': 'finite_automaton',
      'id': fa.id,
      'name': fa.name,
      'states': fa.states.map((s) => s.toJson()).toList(),
      'transitions': fa.transitions.map((t) => t.toJson()).toList(),
      'alphabet': fa.alphabet.symbols,
      'initialState': fa.initialState?.id,
      'finalStates': fa.finalStates.map((s) => s.id).toList(),
      'metadata': fa.metadata.toJson(),
    };
  }

  static Map<String, dynamic> _serializePushdownAutomaton(PushdownAutomaton pda) {
    return {
      'type': 'pushdown_automaton',
      'id': pda.id,
      'name': pda.name,
      'states': pda.states.map((s) => s.toJson()).toList(),
      'transitions': pda.transitions.map((t) => t.toJson()).toList(),
      'inputAlphabet': pda.inputAlphabet.symbols,
      'stackAlphabet': pda.stackAlphabet.symbols,
      'initialState': pda.initialState?.id,
      'finalStates': pda.finalStates.map((s) => s.id).toList(),
      'acceptanceMode': pda.acceptanceMode.name,
      'metadata': pda.metadata.toJson(),
    };
  }

  static Map<String, dynamic> _serializeTuringMachine(TuringMachine tm) {
    return {
      'type': 'turing_machine',
      'id': tm.id,
      'name': tm.name,
      'states': tm.states.map((s) => s.toJson()).toList(),
      'transitions': tm.transitions.map((t) => t.toJson()).toList(),
      'alphabet': tm.alphabet.symbols,
      'initialState': tm.initialState?.id,
      'finalStates': tm.finalStates.map((s) => s.id).toList(),
      'blankSymbol': tm.blankSymbol,
      'metadata': tm.metadata.toJson(),
    };
  }

  static Map<String, dynamic> _serializeContextFreeGrammar(ContextFreeGrammar cfg) {
    return {
      'type': 'context_free_grammar',
      'id': cfg.id,
      'name': cfg.name,
      'variables': cfg.variables,
      'terminals': cfg.terminals,
      'productions': cfg.productions.map((p) => p.toJson()).toList(),
      'startVariable': cfg.startVariable,
      'metadata': cfg.metadata.toJson(),
    };
  }

  static Map<String, dynamic> _serializeRegularExpression(RegularExpression regex) {
    return {
      'type': 'regular_expression',
      'id': regex.id,
      'name': regex.name,
      'pattern': regex.pattern,
      'alphabet': regex.alphabet.symbols,
      'metadata': regex.metadata.toJson(),
    };
  }

  /// Private deserialization methods
  static FiniteAutomaton _deserializeFiniteAutomaton(Map<String, dynamic> json) {
    return FiniteAutomaton.fromJson(json);
  }

  static PushdownAutomaton _deserializePushdownAutomaton(Map<String, dynamic> json) {
    return PushdownAutomaton.fromJson(json);
  }

  static TuringMachine _deserializeTuringMachine(Map<String, dynamic> json) {
    return TuringMachine.fromJson(json);
  }

  static ContextFreeGrammar _deserializeContextFreeGrammar(Map<String, dynamic> json) {
    return ContextFreeGrammar.fromJson(json);
  }

  static RegularExpression _deserializeRegularExpression(Map<String, dynamic> json) {
    return RegularExpression.fromJson(json);
  }

  /// Private validation helper
  static bool _validateRule(Map<String, dynamic> json, String field, dynamic rule) {
    if (!json.containsKey(field)) return true; // Optional field

    final value = json[field];
    
    if (rule is String) {
      // Type validation
      switch (rule) {
        case 'string':
          return value is String;
        case 'number':
          return value is num;
        case 'boolean':
          return value is bool;
        case 'array':
          return value is List;
        case 'object':
          return value is Map;
        default:
          return true;
      }
    } else if (rule is Map<String, dynamic>) {
      // Complex validation rules
      if (rule.containsKey('minLength') && value is String) {
        return value.length >= rule['minLength'];
      }
      if (rule.containsKey('maxLength') && value is String) {
        return value.length <= rule['maxLength'];
      }
      if (rule.containsKey('pattern') && value is String) {
        return RegExp(rule['pattern']).hasMatch(value);
      }
    }

    return true;
  }
}
