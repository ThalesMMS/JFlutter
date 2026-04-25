//
//  file_operations_panel_test.dart
//  JFlutter
//
//  Suíte de testes de widget para o painel de operações de arquivo, validando
//  a renderização de botões contextuais, estados de carregamento, exibição de
//  banners de erro e integração com callbacks de salvamento, carregamento e
//  exportação. Os cenários cobrem automatos e gramáticas em ambientes web e
//  desktop, garantindo que operações assíncronas atualizem o estado visual.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/services/file_operations_service.dart';
import 'package:jflutter/presentation/widgets/error_banner.dart';
import 'package:jflutter/presentation/widgets/file_operations_panel.dart';
import 'package:jflutter/presentation/widgets/import_error_dialog.dart';
import 'package:vector_math/vector_math_64.dart';
part 'file_operations_panel/basic_rendering_tests.dart';
part 'file_operations_panel/automaton_operation_tests.dart';
part 'file_operations_panel/machine_operation_tests.dart';
part 'file_operations_panel/loading_error_tests.dart';
part 'file_operations_panel/message_cancellation_tests.dart';
part 'file_operations_panel/fixtures.dart';

void main() {
  late _FakeFilePicker fakeFilePicker;

  setUp(() {
    fakeFilePicker = _FakeFilePicker();
    FilePicker.platform = fakeFilePicker;
  });

  _runFileOperationsPanelBasicRenderingTests();
  _runFileOperationsPanelAutomatonOperationTests(() => fakeFilePicker);
  _runFileOperationsPanelMachineOperationTests(() => fakeFilePicker);
  _runFileOperationsPanelLoadingErrorTests(() => fakeFilePicker);
  _runFileOperationsPanelMessageCancellationTests(() => fakeFilePicker);
}
