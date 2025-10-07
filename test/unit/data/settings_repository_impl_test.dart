// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/unit/data/settings_repository_impl_test.dart
// Objetivo: Confirmar que o repositório de configurações elimina chaves
// legadas relacionadas ao canvas Draw2D ao carregar ou salvar preferências.
// Cenários cobertos:
// - Limpeza da flag `settings_use_draw2d_canvas` durante o carregamento das
//   configurações.
// - Remoção do mesmo sinalizador ao persistir novas preferências.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

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
