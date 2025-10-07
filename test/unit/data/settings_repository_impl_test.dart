//
//  settings_repository_impl_test.dart
//  JFlutter
//
//  Testes que confirmam a limpeza de chaves legadas pelo SharedPreferencesSettingsRepository,
//  removendo o uso antigo do canvas Draw2D tanto ao carregar quanto ao salvar
//  preferências e garantindo que o armazenamento permaneça consistente.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/data/repositories/settings_repository_impl.dart';
import 'package:jflutter/data/storage/settings_storage.dart';

void main() {
  group('SharedPreferencesSettingsRepository legacy cleanup', () {
    late InMemorySettingsStorage storage;
    late SharedPreferencesSettingsRepository repository;

    setUp(() {
      storage = InMemorySettingsStorage({
        'settings_use_draw2d_canvas': true,
      });
      repository = SharedPreferencesSettingsRepository(storage: storage);
    });

    test('loadSettings removes legacy Draw2D flag', () async {
      final settings = await repository.loadSettings();

      expect(settings, isA<SettingsModel>());
      final legacyValue = await storage.readBool('settings_use_draw2d_canvas');
      expect(legacyValue, isNull);
    });

    test('saveSettings removes legacy Draw2D flag', () async {
      await repository.saveSettings(const SettingsModel());

      final legacyValue = await storage.readBool('settings_use_draw2d_canvas');
      expect(legacyValue, isNull);
    });
  });
}
