//
//  settings_storage.dart
//  JFlutter
//
//  Define a abstração SettingsStorage e suas implementações baseada em
//  SharedPreferences e em memória, permitindo que o repositório de
//  configurações leia e persista preferências do usuário sem acoplar detalhes
//  de plataforma, além de facilitar testes com provedores customizados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value storage interface used by the settings repository.
abstract class SettingsStorage {
  Future<String?> readString(String key);
  Future<bool?> readBool(String key);
  Future<double?> readDouble(String key);

  Future<bool> writeString(String key, String value);
  Future<bool> writeBool(String key, bool value);
  Future<bool> writeDouble(String key, double value);
  Future<bool> remove(String key);
}

/// [SettingsStorage] backed by [SharedPreferences].
class SharedPreferencesSettingsStorage implements SettingsStorage {
  const SharedPreferencesSettingsStorage({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider = preferencesProvider;

  final Future<SharedPreferences> Function()? _preferencesProvider;

  Future<SharedPreferences> _getPreferences() {
    final provider = _preferencesProvider;
    if (provider != null) {
      return provider();
    }
    return SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(String key) async {
    final prefs = await _getPreferences();
    return prefs.getString(key);
  }

  @override
  Future<bool?> readBool(String key) async {
    final prefs = await _getPreferences();
    return prefs.getBool(key);
  }

  @override
  Future<double?> readDouble(String key) async {
    final prefs = await _getPreferences();
    return prefs.getDouble(key);
  }

  @override
  Future<bool> writeString(String key, String value) async {
    final prefs = await _getPreferences();
    return prefs.setString(key, value);
  }

  @override
  Future<bool> writeBool(String key, bool value) async {
    final prefs = await _getPreferences();
    return prefs.setBool(key, value);
  }

  @override
  Future<bool> writeDouble(String key, double value) async {
    final prefs = await _getPreferences();
    return prefs.setDouble(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _getPreferences();
    return prefs.remove(key);
  }
}

/// In-memory implementation of [SettingsStorage] used in tests.
class InMemorySettingsStorage implements SettingsStorage {
  InMemorySettingsStorage([Map<String, Object?>? initialValues])
    : _values = Map<String, Object?>.from(initialValues ?? const {});

  final Map<String, Object?> _values;

  @override
  Future<String?> readString(String key) async => _values[key] as String?;

  @override
  Future<bool?> readBool(String key) async => _values[key] as bool?;

  @override
  Future<double?> readDouble(String key) async =>
      (_values[key] as num?)?.toDouble();

  @override
  Future<bool> writeString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> writeBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> writeDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    return _values.remove(key) != null;
  }
}
