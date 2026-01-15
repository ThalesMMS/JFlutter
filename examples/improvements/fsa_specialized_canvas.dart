/// Canvas especializado para Autômatos Finitos (FSA)
///
/// Este arquivo demonstra como criar um canvas especializado para FSA
/// que mostra indicadores de determinismo e destaca transições epsilon.
library;

import 'package:flutter/material.dart';

/// Estilo de transição para FSA
class FSATransitionStyle {
  final bool isEpsilon;
  final bool isNonDeterministic;
  final Color color;
  final List<double>? dashPattern;

  const FSATransitionStyle({
    required this.isEpsilon,
    required this.isNonDeterministic,
    Color? color,
    this.dashPattern,
  }) : color = color ?? Colors.black;

  /// Estilo para transição epsilon
  factory FSATransitionStyle.epsilon() {
    return FSATransitionStyle(
      isEpsilon: true,
      isNonDeterministic: false,
      color: Colors.grey[600]!,
      dashPattern: [8.0, 4.0], // Linha tracejada
    );
  }

  /// Estilo para transição normal
  factory FSATransitionStyle.normal({bool isNonDeterministic = false}) {
    return FSATransitionStyle(
      isEpsilon: false,
      isNonDeterministic: isNonDeterministic,
      color: isNonDeterministic ? Colors.orange[700]! : Colors.black,
    );
  }
}

/// Informações sobre determinismo do autômato
class DeterminismInfo {
  final bool isDeterministic;
  final bool hasEpsilonTransitions;
  final List<String> nonDeterministicStates;
  final List<String> nonDeterministicSymbols;

  const DeterminismInfo({
    required this.isDeterministic,
    required this.hasEpsilonTransitions,
    this.nonDeterministicStates = const [],
    this.nonDeterministicSymbols = const [],
  });

  /// Retorna a descrição do tipo de autômato
  String get type {
    if (isDeterministic && !hasEpsilonTransitions) return 'DFA';
    if (hasEpsilonTransitions) return 'ε-NFA';
    return 'NFA';
  }

  /// Retorna a cor do badge baseada no tipo
  Color get badgeColor {
    if (isDeterministic) return Colors.green;
    if (hasEpsilonTransitions) return Colors.purple;
    return Colors.blue;
  }

  /// Retorna mensagem de ajuda
  String get helpMessage {
    if (isDeterministic) {
      return 'Autômato Finito Determinístico - cada estado tem no máximo uma transição por símbolo';
    } else if (hasEpsilonTransitions) {
      return 'Autômato Finito Não-Determinístico com transições ε';
    } else {
      return 'Autômato Finito Não-Determinístico - alguns estados têm múltiplas transições para o mesmo símbolo';
    }
  }
}

/// Widget de badge mostrando o tipo de autômato (DFA/NFA/ε-NFA)
class AutomatonTypeBadge extends StatelessWidget {
  final DeterminismInfo info;
  final VoidCallback? onTap;

  const AutomatonTypeBadge({
    super.key,
    required this.info,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: info.badgeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              info.isDeterministic ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              info.type,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Painel de informações detalhadas sobre não-determinismo
class NonDeterminismPanel extends StatelessWidget {
  final DeterminismInfo info;
  final VoidCallback? onClose;

  const NonDeterminismPanel({
    super.key,
    required this.info,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: info.badgeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  info.isDeterministic ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Análise de Determinismo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo
                Row(
                  children: [
                    const Text(
                      'Tipo: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(info.type),
                  ],
                ),
                const SizedBox(height: 8),

                // Descrição
                Text(
                  info.helpMessage,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),

                // Características
                if (info.hasEpsilonTransitions) ...[
                  _buildFeature(
                    icon: Icons.call_split,
                    label: 'Possui transições ε (epsilon)',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 8),
                ],

                if (!info.isDeterministic && info.nonDeterministicStates.isNotEmpty) ...[
                  _buildFeature(
                    icon: Icons.warning,
                    label: 'Estados não-determinísticos:',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: info.nonDeterministicStates.map((state) {
                        return Chip(
                          label: Text(state),
                          backgroundColor: Colors.orange[100],
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!info.isDeterministic && info.nonDeterministicSymbols.isNotEmpty) ...[
                  _buildFeature(
                    icon: Icons.content_copy,
                    label: 'Símbolos com múltiplas transições:',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: info.nonDeterministicSymbols.map((symbol) {
                        return Chip(
                          label: Text(symbol),
                          backgroundColor: Colors.blue[100],
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (info.isDeterministic) ...[
                  _buildFeature(
                    icon: Icons.check_circle,
                    label: 'Todas as transições são determinísticas',
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}

/// Visualizador de transições agrupadas
class GroupedTransitionLabel extends StatelessWidget {
  final List<String> symbols;
  final bool isEpsilon;

  const GroupedTransitionLabel({
    super.key,
    required this.symbols,
    this.isEpsilon = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = isEpsilon ? 'ε' : symbols.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isEpsilon ? Colors.purple : Colors.blue,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEpsilon)
            Icon(
              Icons.call_split,
              size: 12,
              color: Colors.purple[700],
            ),
          if (isEpsilon) const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isEpsilon ? Colors.purple[700] : Colors.black,
              fontStyle: isEpsilon ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          if (symbols.length > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${symbols.length}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay especializado para FSA
class FSACanvasOverlay extends StatefulWidget {
  final DeterminismInfo determinismInfo;

  const FSACanvasOverlay({
    super.key,
    required this.determinismInfo,
  });

  @override
  State<FSACanvasOverlay> createState() => _FSACanvasOverlayState();
}

class _FSACanvasOverlayState extends State<FSACanvasOverlay> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Badge no canto superior direito
        Positioned(
          top: 16,
          right: 16,
          child: AutomatonTypeBadge(
            info: widget.determinismInfo,
            onTap: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
          ),
        ),

        // Painel de detalhes (se aberto)
        if (_showDetails)
          Positioned(
            top: 60,
            right: 16,
            child: NonDeterminismPanel(
              info: widget.determinismInfo,
              onClose: () {
                setState(() {
                  _showDetails = false;
                });
              },
            ),
          ),
      ],
    );
  }
}

/// Exemplo de uso
class FSASpecializedCanvasExample extends StatefulWidget {
  const FSASpecializedCanvasExample({super.key});

  @override
  State<FSASpecializedCanvasExample> createState() =>
      _FSASpecializedCanvasExampleState();
}

class _FSASpecializedCanvasExampleState
    extends State<FSASpecializedCanvasExample> {
  DeterminismInfo _info = const DeterminismInfo(
    isDeterministic: false,
    hasEpsilonTransitions: true,
    nonDeterministicStates: ['q0', 'q1'],
    nonDeterministicSymbols: ['a', 'b'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FSA Specialized Canvas Example')),
      body: Stack(
        children: [
          // Canvas (placeholder)
          Container(
            color: Colors.grey[100],
            child: const Center(
              child: Text('Canvas Area'),
            ),
          ),

          // Overlay especializado
          FSACanvasOverlay(determinismInfo: _info),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Alternar entre DFA e NFA para demonstração
            _info = _info.isDeterministic
                ? const DeterminismInfo(
                    isDeterministic: false,
                    hasEpsilonTransitions: true,
                    nonDeterministicStates: ['q0', 'q1'],
                    nonDeterministicSymbols: ['a', 'b'],
                  )
                : const DeterminismInfo(
                    isDeterministic: true,
                    hasEpsilonTransitions: false,
                  );
          });
        },
        child: const Icon(Icons.swap_horiz),
      ),
    );
  }
}
