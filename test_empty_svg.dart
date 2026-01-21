#!/usr/bin/env dart

import 'lib/core/entities/automaton_entity.dart';
import 'lib/presentation/widgets/export/svg_exporter.dart';

void main() {
  // Create empty automaton
  const emptyAutomaton = AutomatonEntity(
    id: 'empty_automaton',
    name: 'Empty Automaton',
    alphabet: {},
    states: [],
    transitions: {},
    initialId: null,
    nextId: 0,
    type: AutomatonType.dfa,
  );

  // Export to SVG
  final svg = SvgExporter.exportAutomatonToSvg(emptyAutomaton);

  print('=== SVG OUTPUT ===');
  print(svg);
  print('\n=== CHECKS ===');
  print('Contains "No states defined": ${svg.contains('No states defined')}');
  print('Contains "<svg": ${svg.contains('<svg')}');
  print('Contains "<circle": ${svg.contains('<circle')}');
}
