import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/repositories/active_session_repository.dart';

export '../../core/repositories/active_session_repository.dart'
    show
        ActiveSessionPersistenceException,
        ActiveSessionRepository,
        ActiveSessionSnapshot,
        RegexSessionSnapshot,
        UnsupportedActiveSessionVersionException;

class ActiveSessionPersistenceService implements ActiveSessionRepository {
  const ActiveSessionPersistenceService(this._prefs);

  static const String sessionKey = 'active_editor_session';
  static const String autoSaveKey = 'settings_auto_save';

  static String unsupportedSessionBackupKey(int version) =>
      '${sessionKey}_unsupported_v$version';

  final SharedPreferences _prefs;

  @override
  bool get autoSaveEnabled => _prefs.getBool(autoSaveKey) ?? true;

  @override
  Future<void> saveSession(ActiveSessionSnapshot session) async {
    final succeeded =
        await _prefs.setString(sessionKey, jsonEncode(session.toJson()));
    if (!succeeded) {
      throw const ActiveSessionPersistenceException('save');
    }
  }

  @override
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
      final sessionJson = decoded.cast<String, dynamic>();
      final storedVersion = sessionJson['version'] as int? ?? 0;
      final session = ActiveSessionSnapshot.fromJson(sessionJson);
      if (storedVersion != ActiveSessionSnapshot.currentVersion) {
        await saveSession(session);
      }
      return session;
    } on UnsupportedActiveSessionVersionException catch (error) {
      final succeeded = await _prefs.setString(
        unsupportedSessionBackupKey(error.version),
        payload,
      );
      if (!succeeded) {
        throw const ActiveSessionPersistenceException(
          'backup_unsupported_version',
        );
      }
      rethrow;
    } on ActiveSessionPersistenceException {
      rethrow;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    final succeeded = await _prefs.remove(sessionKey);
    if (!succeeded) {
      throw const ActiveSessionPersistenceException('clear');
    }
  }
}
