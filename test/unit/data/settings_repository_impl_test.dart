//
//  settings_repository_impl_test.dart
//  JFlutter
//
//  Testes que confirmam que chaves legadas desconhecidas não interferem nas
//  preferências atuais persistidas pelo SharedPreferencesSettingsRepository.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/data/repositories/settings_repository_impl.dart';
import 'package:jflutter/data/storage/settings_storage.dart';

void main() {
  group('SharedPreferencesSettingsRepository legacy keys', () {
    late SharedPreferencesSettingsStorage storage;
    late SharedPreferencesSettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'settings_use_draw2d_canvas': true,
      });
      storage = const SharedPreferencesSettingsStorage();
      repository = SharedPreferencesSettingsRepository(storage: storage);
    });

    test('loadSettings ignores legacy Draw2D flag', () async {
      final settings = await repository.loadSettings();

      expect(settings, isA<SettingsModel>());
      final legacyValue = await storage.readBool('settings_use_draw2d_canvas');
      expect(legacyValue, isTrue);
    });

    test('saveSettings leaves unrelated legacy Draw2D flag untouched',
        () async {
      await repository.saveSettings(const SettingsModel());

      final legacyValue = await storage.readBool('settings_use_draw2d_canvas');
      expect(legacyValue, isTrue);
    });
  });
}
