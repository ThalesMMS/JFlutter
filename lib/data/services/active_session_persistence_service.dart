import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';

class ActiveSessionSnapshot {
  const ActiveSessionSnapshot({
    required this.activeWorkspaceIndex,
    required this.savedAt,
    this.fsa,
    this.grammar,
    this.pda,
    this.tm,
    this.regex,
  });

  static const int currentVersion = 1;

  final int activeWorkspaceIndex;
  final DateTime savedAt;
  final FSA? fsa;
  final Grammar? grammar;
  final PDA? pda;
  final TM? tm;
  final RegexSessionSnapshot? regex;

  Map<String, dynamic> toJson() {
    return {
      'version': currentVersion,
      'savedAt': savedAt.toIso8601String(),
      'activeWorkspaceIndex': activeWorkspaceIndex,
      if (fsa != null) 'fsa': fsa!.toJson(),
      if (grammar != null) 'grammar': grammar!.toJson(),
      if (pda != null) 'pda': pda!.toJson(),
      if (tm != null) 'tm': tm!.toJson(),
      if (regex != null) 'regex': regex!.toJson(),
    };
  }

  factory ActiveSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 0;
    if (version != currentVersion) {
      throw FormatException('Unsupported active session version: $version');
    }

    return ActiveSessionSnapshot(
      activeWorkspaceIndex: json['activeWorkspaceIndex'] as int? ?? 0,
      savedAt: DateTime.parse(json['savedAt'] as String),
      fsa: _decodeModel(json['fsa'], FSA.fromJson),
      grammar: _decodeModel(json['grammar'], Grammar.fromJson),
      pda: _decodeModel(json['pda'], PDA.fromJson),
      tm: _decodeModel(json['tm'], TM.fromJson),
      regex: _decodeModel(json['regex'], RegexSessionSnapshot.fromJson),
    );
  }

  static T? _decodeModel<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! Map) {
      return null;
    }
    return decode(value.cast<String, dynamic>());
  }
}

class RegexSessionSnapshot {
  const RegexSessionSnapshot({
    required this.currentRegex,
    required this.testString,
    required this.simplifyOutput,
  });

  final String currentRegex;
  final String testString;
  final bool simplifyOutput;

  bool get hasContent =>
      currentRegex.isNotEmpty || testString.isNotEmpty || !simplifyOutput;

  Map<String, dynamic> toJson() {
    return {
      'currentRegex': currentRegex,
      'testString': testString,
      'simplifyOutput': simplifyOutput,
    };
  }

  factory RegexSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return RegexSessionSnapshot(
      currentRegex: json['currentRegex'] as String? ?? '',
      testString: json['testString'] as String? ?? '',
      simplifyOutput: json['simplifyOutput'] as bool? ?? true,
    );
  }
}

class ActiveSessionPersistenceService {
  const ActiveSessionPersistenceService(this._prefs);

  static const String sessionKey = 'active_editor_session';
  static const String autoSaveKey = 'settings_auto_save';

  final SharedPreferences _prefs;

  bool get autoSaveEnabled => _prefs.getBool(autoSaveKey) ?? true;

  Future<void> saveSession(ActiveSessionSnapshot session) {
    return _prefs.setString(sessionKey, jsonEncode(session.toJson()));
  }

  Future<ActiveSessionSnapshot?> loadSession() async {
    final payload = _prefs.getString(sessionKey);
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        await clearSession();
        return null;
      }
      return ActiveSessionSnapshot.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() {
    return _prefs.remove(sessionKey);
  }
}
