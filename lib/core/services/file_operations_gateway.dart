import 'dart:typed_data';

import '../entities/turing_machine_entity.dart';
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/pda.dart';
import '../result.dart';

abstract interface class FileOperationsGateway {
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton);
  Future<StringResult> writePngBytesToPath(Uint8List bytes, String filePath);
  Future<StringResult> saveAutomatonToJFLAP(FSA automaton, String filePath);
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath);
  Future<StringResult> saveAutomatonToJson(FSA automaton, String filePath);
  Future<Result<FSA>> loadAutomatonFromJson(String filePath);
  Future<StringResult> saveGrammarToJFLAP(Grammar grammar, String filePath);
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath);
  Future<StringResult> exportFsaToSVG(FSA automaton, String filePath);
  Future<StringResult> exportGrammarModelToSVG(
    Grammar grammar,
    String filePath,
  );
  Future<StringResult> exportPdaToSVG(PDA pda, String filePath);
  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity machine,
    String filePath,
  );
  String serializeAutomatonToJFLAPString(FSA automaton);
  String serializeAutomatonToJsonString(FSA automaton);
  String serializeGrammarToJFLAPString(Grammar grammar);
  String exportFsaToSvgString(FSA automaton);
  String exportGrammarModelToSvgString(Grammar grammar);
  String exportPdaToSvgString(PDA pda);
  String exportTuringMachineToSvgString(TuringMachineEntity machine);
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes);
  Future<Result<FSA>> loadAutomatonFromJsonBytes(Uint8List bytes);
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes);
}
