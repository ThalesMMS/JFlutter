import 'app_localizations.dart';

/// Presentation-only bridge for legacy algorithm prose.
///
/// Core algorithms still expose human-readable English in some structured
/// traces. Renderers pass that prose through this adapter so locale concerns do
/// not leak into the core model. New controls and summaries should use the
/// generated ARB getters directly; this bridge can shrink as trace payloads gain
/// stable message keys and arguments.
extension AppLocalizationsWorkflows on AppLocalizations {
  String localizeWorkflowText(String source) {
    final common = switch (source) {
      'Simulation' => simulation,
      'Input String' => inputString,
      'Leave blank for ε; whitespace is preserved' => simulationInputHint,
      'Simulate' => simulate,
      'Simulating...' => simulating,
      'Cancel simulation' => cancelSimulation,
      'Run simulation' => runSimulation,
      'Runs the machine using the currently entered input string.' =>
        runSimulationHint,
      'Simulation Result' => simulationResult,
      'Regex Result' => regexResult,
      'Regular Expression' => regularExpression,
      'Step-by-Step Mode' => stepByStepMode,
      'Step-by-Step Execution' => stepByStepExecution,
      'Play' => play,
      'Pause' => pause,
      'Reset' => reset,
      'Expand' => expand,
      'Collapse' => collapse,
      'No steps recorded' => noStepsRecorded,
      'No steps available' => noStepsAvailable,
      'No steps' => noSteps,
      'Timeline' => timeline,
      'Timeline scrubber' => timelineScrubber,
      'No simulation results yet' => noSimulationResults,
      'Enter an input string and click Simulate to see results' =>
        simulationEmptyHint,
      'Accepted' => accepted,
      'Rejected' => rejected,
      'Suggested fixes' => suggestedFixes,
      _ => null,
    };
    if (common != null) {
      return common;
    }

    if (!localeName.startsWith('pt')) {
      return workflowLegacyText(source);
    }

    final exact = _ptWorkflowCopy[source];
    if (exact != null) {
      return workflowLegacyText(exact);
    }

    var translated = source;
    for (final replacement in _ptWorkflowReplacements) {
      translated = translated.replaceAll(replacement.$1, replacement.$2);
    }
    return workflowLegacyText(translated);
  }
}

const _ptWorkflowCopy = <String, String>{
  'Algorithms': 'Algoritmos',
  'Grammar Analysis': 'Análise da gramática',
  'PDA Analysis': 'Análise do AP',
  'TM Analysis': 'Análise da MT',
  'PDA Simulation': 'Simulação de AP',
  'TM Simulation': 'Simulação de MT',
  'Simulation Input': 'Entrada da simulação',
  'Initial Stack Symbol': 'Símbolo inicial da pilha',
  'Record step-by-step trace': 'Registrar traço passo a passo',
  'Simulate PDA': 'Simular AP',
  'Simulate TM': 'Simular MT',
  'Simulation Results': 'Resultados da simulação',
  'Simulation error': 'Erro de simulação',
  'Grammar Parser': 'Analisador de gramática',
  'Parsing Algorithm': 'Algoritmo de análise',
  'Test String': 'Cadeia de teste',
  'Parsing...': 'Analisando...',
  'Parse String': 'Analisar cadeia',
  'Parse Results': 'Resultados da análise',
  'No parse results yet': 'Nenhum resultado de análise',
  'Enter a string and click Parse to see results':
      'Informe uma cadeia e ative Analisar para ver os resultados',
  'NFA to DFA': 'AFN para AFD',
  'Remove λ-transitions': 'Remover transições λ',
  'Minimize DFA': 'Minimizar AFD',
  'Complete DFA': 'Completar AFD',
  'Complement DFA': 'Complemento do AFD',
  'Union of DFAs': 'União de AFDs',
  'Intersection of DFAs': 'Interseção de AFDs',
  'Difference of DFAs': 'Diferença de AFDs',
  'Prefix Closure': 'Fecho por prefixos',
  'Suffix Closure': 'Fecho por sufixos',
  'FA to Regex': 'AF para expressão regular',
  'FSA to Grammar': 'AF para gramática',
  'Regex to NFA': 'Expressão regular para AFN',
  'Auto Layout': 'Layout automático',
  'Compare Equivalence': 'Comparar equivalência',
  'Clear': 'Limpar',
  'Convert to CNF': 'Converter para FNC',
  'Convert to GNF': 'Converter para FNG',
  'Remove Left Recursion': 'Remover recursão à esquerda',
  'Left Factor': 'Fatorar à esquerda',
  'Find First Sets': 'Calcular conjuntos FIRST',
  'Find Follow Sets': 'Calcular conjuntos FOLLOW',
  'Build Parse Table': 'Construir tabela de análise',
  'Check Ambiguity': 'Verificar ambiguidade',
  'Convert to CFG': 'Converter para GLC',
  'Minimize PDA': 'Minimizar AP',
  'Check Determinism': 'Verificar determinismo',
  'Find Reachable States': 'Encontrar estados alcançáveis',
  'Language Analysis': 'Análise da linguagem',
  'Stack Operations': 'Operações da pilha',
  'Check Decidability': 'Verificar decidibilidade',
  'Tape Operations': 'Operações da fita',
  'Time Characteristics': 'Características de tempo',
  'Space Characteristics': 'Características de espaço',
  'No analysis results yet': 'Nenhum resultado de análise',
  'Analysis Results': 'Resultados da análise',
  'Load Examples': 'Carregar exemplos',
  'Conversions': 'Conversões',
  'No structural issues detected.': 'Nenhum problema estrutural detectado.',
  'Processing...': 'Processando...',
  'Executing...': 'Executando...',
  'Completed successfully': 'Concluído com sucesso',
  'Loading automaton...': 'Carregando autômato...',
  'Failed to load automaton': 'Falha ao carregar o autômato',
  'Comparison complete': 'Comparação concluída',
  'Comparison failed': 'Falha na comparação',
  'Language Comparison': 'Comparação de linguagens',
  'Current Automaton': 'Autômato atual',
  'Compared Automaton': 'Autômato comparado',
  'Automata are equivalent': 'Os autômatos são equivalentes',
  'Automata are not equivalent': 'Os autômatos não são equivalentes',
  'Generated Grammar': 'Gramática gerada',
  'Explanation': 'Explicação',
  'Notes': 'Observações',
  'Derivations': 'Derivações',
  'Conflicts': 'Conflitos',
  'Reachable': 'Alcançáveis',
  'Unreachable': 'Inalcançáveis',
  'Total states': 'Total de estados',
  'Accepting states': 'Estados de aceitação',
  'Non-accepting states': 'Estados que não são de aceitação',
  'Total transitions': 'Total de transições',
  'Potential Issues': 'Possíveis problemas',
};

// Replacements are sequential. Keep longer or more specific source strings
// before entries that contain the same substrings.
const _ptWorkflowReplacements = <(String, String)>[
  (
    'Select an algorithm above to analyze your ',
    'Selecione um algoritmo acima para analisar '
  ),
  (
    'Convert non-deterministic to deterministic automaton',
    'Converter autômato não determinístico em determinístico'
  ),
  (
    'Eliminate epsilon transitions from the automaton',
    'Eliminar transições epsilon do autômato'
  ),
  (
    'Minimize deterministic finite automaton',
    'Minimizar o autômato finito determinístico'
  ),
  (
    'Add trap state to make DFA complete',
    'Adicionar estado armadilha para completar o AFD'
  ),
  (
    'Flip accepting states after completion',
    'Inverter estados de aceitação após completar'
  ),
  (
    'Identify reachable states from initial state',
    'Identificar estados alcançáveis a partir do estado inicial'
  ),
  ('Failed to load ', 'Falha ao carregar '),
  ('Failed to convert ', 'Falha ao converter '),
  ('Analysis failed', 'Falha na análise'),
  ('Conversion failed', 'Falha na conversão'),
  ('No PDA examples available.', 'Nenhum exemplo de AP disponível.'),
  ('No TM examples available.', 'Nenhum exemplo de MT disponível.'),
  ('Initial state', 'Estado inicial'),
  ('Reachable states', 'Estados alcançáveis'),
  ('Unreachable states', 'Estados inalcançáveis'),
  ('Accepting states', 'Estados de aceitação'),
  ('Total transitions', 'Total de transições'),
  ('Total states', 'Total de estados'),
  ('transitions', 'transições'),
  ('states', 'estados'),
  ('Warnings', 'Avisos'),
  ('Result', 'Resultado'),
  ('Start symbol', 'Símbolo inicial'),
  ('Productions', 'Produções'),
  ('Terminals', 'Terminais'),
  ('Non-terminals', 'Não terminais'),
];
