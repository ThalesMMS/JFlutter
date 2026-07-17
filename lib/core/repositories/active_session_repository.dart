import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/tm.dart';

abstract interface class ActiveSessionRepository {
  bool get autoSaveEnabled;
  Future<void> saveSession(ActiveSessionSnapshot session);
  Future<ActiveSessionSnapshot?> loadSession();
  Future<void> clearSession();
}

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

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'savedAt': savedAt.toIso8601String(),
        'activeWorkspaceIndex': activeWorkspaceIndex,
        if (fsa != null) 'fsa': fsa!.toJson(),
        if (grammar != null) 'grammar': grammar!.toJson(),
        if (pda != null) 'pda': pda!.toJson(),
        if (tm != null) 'tm': tm!.toJson(),
        if (regex != null) 'regex': regex!.toJson(),
      };

  factory ActiveSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final migratedJson = _migrateToCurrentVersion(json);
    return ActiveSessionSnapshot(
      activeWorkspaceIndex: migratedJson['activeWorkspaceIndex'] as int? ?? 0,
      savedAt: DateTime.parse(migratedJson['savedAt'] as String),
      fsa: _decodeModel(migratedJson['fsa'], FSA.fromJson),
      grammar: _decodeModel(migratedJson['grammar'], Grammar.fromJson),
      pda: _decodeModel(migratedJson['pda'], PDA.fromJson),
      tm: _decodeModel(migratedJson['tm'], TM.fromJson),
      regex: _decodeModel(
        migratedJson['regex'],
        RegexSessionSnapshot.fromJson,
      ),
    );
  }

  static Map<String, dynamic> _migrateToCurrentVersion(
    Map<String, dynamic> json,
  ) {
    final rawVersion = json['version'];
    if (rawVersion != null && rawVersion is! int) {
      throw const FormatException('Active session version must be an integer');
    }
    final version = rawVersion as int? ?? 0;
    if (version < 0 || version > currentVersion) {
      throw UnsupportedActiveSessionVersionException(
        version: version,
        supportedVersion: currentVersion,
      );
    }
    final migrated = Map<String, dynamic>.from(json);
    var migratedVersion = version;
    while (migratedVersion < currentVersion) {
      switch (migratedVersion) {
        case 0:
          migrated['version'] = 1;
          migratedVersion = 1;
        default:
          throw UnsupportedActiveSessionVersionException(
            version: migratedVersion,
            supportedVersion: currentVersion,
          );
      }
    }
    return migrated;
  }

  static T? _decodeModel<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    return value is Map ? decode(value.cast<String, dynamic>()) : null;
  }
}

class RegexSessionSnapshot {
  const RegexSessionSnapshot({
    required this.currentRegex,
    required this.testString,
    required this.simplifyOutput,
    this.alphabet = defaultAlphabet,
  });

  static const defaultAlphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?_-';

  final String currentRegex;
  final String testString;
  final bool simplifyOutput;
  final String alphabet;

  bool get hasContent =>
      currentRegex.isNotEmpty ||
      testString.isNotEmpty ||
      !simplifyOutput ||
      alphabet != defaultAlphabet;

  Map<String, dynamic> toJson() => {
        'currentRegex': currentRegex,
        'testString': testString,
        'simplifyOutput': simplifyOutput,
        'alphabet': alphabet,
      };

  factory RegexSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return RegexSessionSnapshot(
      currentRegex: json['currentRegex'] as String? ?? '',
      testString: json['testString'] as String? ?? '',
      simplifyOutput: json['simplifyOutput'] as bool? ?? true,
      alphabet: json['alphabet'] as String? ?? defaultAlphabet,
    );
  }
}

class UnsupportedActiveSessionVersionException implements Exception {
  const UnsupportedActiveSessionVersionException({
    required this.version,
    required this.supportedVersion,
  });

  final int version;
  final int supportedVersion;

  @override
  String toString() =>
      'Unsupported active session version $version; this app supports version $supportedVersion. The saved session was preserved for recovery.';
}

class ActiveSessionPersistenceException implements Exception {
  const ActiveSessionPersistenceException(this.operation);

  final String operation;

  @override
  String toString() =>
      'ActiveSessionPersistenceException: $operation operation failed';
}
