/// Painel de visualização de pilha para Autômatos de Pilha (PDA)
///
/// Este arquivo demonstra como implementar um painel lateral que mostra
/// o estado da pilha durante a edição e simulação de PDAs.
library;

import 'package:flutter/material.dart';

/// Representação de um símbolo na pilha
class StackSymbol {
  final String symbol;
  final int position;
  final bool isHighlighted;

  const StackSymbol({
    required this.symbol,
    required this.position,
    this.isHighlighted = false,
  });
}

/// Estado da pilha em um determinado momento
class StackState {
  final List<String> symbols;
  final String? lastOperation; // "push X", "pop X", ou null
  final bool isEmpty;

  StackState({
    required this.symbols,
    this.lastOperation,
  }) : isEmpty = symbols.isEmpty;

  /// Retorna o topo da pilha
  String? get top => symbols.isEmpty ? null : symbols.last;

  /// Retorna a pilha como lista (topo no final)
  List<StackSymbol> get stackSymbols {
    return symbols.asMap().entries.map((entry) {
      return StackSymbol(
        symbol: entry.value,
        position: entry.key,
        isHighlighted: entry.key == symbols.length - 1, // Destacar topo
      );
    }).toList();
  }

  /// Cria uma nova pilha com push
  StackState push(String symbol) {
    return StackState(
      symbols: [...symbols, symbol],
      lastOperation: 'push $symbol',
    );
  }

  /// Cria uma nova pilha com pop
  StackState pop() {
    if (symbols.isEmpty) return this;
    final popped = symbols.last;
    return StackState(
      symbols: symbols.sublist(0, symbols.length - 1),
      lastOperation: 'pop $popped',
    );
  }

  /// Cria uma nova pilha substituindo o topo
  StackState replace(String newSymbol) {
    if (symbols.isEmpty) return push(newSymbol);
    final newSymbols = [...symbols];
    newSymbols[newSymbols.length - 1] = newSymbol;
    return StackState(
      symbols: newSymbols,
      lastOperation: 'replace with $newSymbol',
    );
  }
}

/// Widget principal do painel de pilha
class PdaStackPanel extends StatefulWidget {
  final StackState stackState;
  final String initialStackSymbol;
  final Set<String> stackAlphabet;
  final bool isSimulating;
  final VoidCallback? onClear;

  const PdaStackPanel({
    Key? key,
    required this.stackState,
    required this.initialStackSymbol,
    required this.stackAlphabet,
    this.isSimulating = false,
    this.onClear,
  }) : super(key: key);

  @override
  State<PdaStackPanel> createState() => _PdaStackPanelState();
}

class _PdaStackPanelState extends State<PdaStackPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(PdaStackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar quando a pilha muda
    if (oldWidget.stackState.symbols != widget.stackState.symbols) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildStackInfo(),
          const Divider(height: 1),
          Expanded(child: _buildStackVisualization()),
          if (widget.onClear != null) ...[
            const Divider(height: 1),
            _buildControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.view_list, size: 20),
          const SizedBox(width: 8),
          Text(
            'Stack',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (widget.isSimulating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulando',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStackInfo() {
    final topSymbol = widget.stackState.top ?? '(vazia)';
    final size = widget.stackState.symbols.length;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Topo: ', style: TextStyle(fontSize: 12)),
              Text(
                topSymbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tamanho: $size',
            style: const TextStyle(fontSize: 12),
          ),
          if (widget.stackState.lastOperation != null) ...[
            const SizedBox(height: 4),
            Text(
              'Última op: ${widget.stackState.lastOperation}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStackVisualization() {
    if (widget.stackState.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Pilha vazia',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Símbolo inicial: ${widget.initialStackSymbol}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar pilha de baixo para cima (reverter para display)
    final displaySymbols = widget.stackState.stackSymbols.reversed.toList();

    return ListView.builder(
      reverse: false, // Não reverter a lista, já revertemos acima
      padding: const EdgeInsets.all(8),
      itemCount: displaySymbols.length,
      itemBuilder: (context, index) {
        final stackSymbol = displaySymbols[index];
        final isTop = index == 0; // Primeiro item é o topo

        return FadeTransition(
          opacity: _animationController,
          child: _buildStackItem(stackSymbol, isTop: isTop),
        );
      },
    );
  }

  Widget _buildStackItem(StackSymbol stackSymbol, {required bool isTop}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isTop ? Colors.blue[100] : Colors.grey[100],
              border: Border.all(
                color: isTop ? Colors.blue : Colors.grey[300]!,
                width: isTop ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (isTop)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_upward, size: 16, color: Colors.blue),
                  ),
                Expanded(
                  child: Text(
                    stackSymbol.symbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (isTop)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'TOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onClear,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Limpar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red,
          ),
        ),
      ),
    );
  }
}

/// Widget de preview de operação de pilha (para mostrar ao passar mouse em transições)
class StackOperationPreview extends StatelessWidget {
  final String inputSymbol;
  final String popSymbol;
  final String pushSymbol;
  final StackState currentStack;

  const StackOperationPreview({
    Key? key,
    required this.inputSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.currentStack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview da Operação',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Divider(),
          _buildOperationRow('Input', inputSymbol, Icons.input, Colors.blue),
          _buildOperationRow('Pop', popSymbol, Icons.arrow_downward, Colors.red),
          _buildOperationRow('Push', pushSymbol, Icons.arrow_upward, Colors.green),
          const Divider(),
          Text(
            'Resultado',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildStackPreview(),
        ],
      ),
    );
  }

  Widget _buildOperationRow(String label, String value, IconData icon, Color color) {
    final isLambda = value == 'λ' || value == 'ε' || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            isLambda ? 'λ' : value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLambda ? Colors.grey : color,
              fontStyle: isLambda ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackPreview() {
    // Simular a operação
    var resultStack = currentStack;

    // Pop se não for lambda
    if (popSymbol != 'λ' && popSymbol != 'ε' && popSymbol.isNotEmpty) {
      resultStack = resultStack.pop();
    }

    // Push se não for lambda
    if (pushSymbol != 'λ' && pushSymbol != 'ε' && pushSymbol.isNotEmpty) {
      // Push pode ser múltiplos símbolos (ex: "ABC")
      for (var i = pushSymbol.length - 1; i >= 0; i--) {
        resultStack = resultStack.push(pushSymbol[i]);
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: resultStack.stackSymbols.reversed.take(5).map((symbol) {
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              symbol.symbol,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Exemplo de uso
class PdaStackPanelExample extends StatefulWidget {
  const PdaStackPanelExample({Key? key}) : super(key: key);

  @override
  State<PdaStackPanelExample> createState() => _PdaStackPanelExampleState();
}

class _PdaStackPanelExampleState extends State<PdaStackPanelExample> {
  StackState _stackState = StackState(symbols: ['Z']); // Iniciar com símbolo inicial

  void _push(String symbol) {
    setState(() {
      _stackState = _stackState.push(symbol);
    });
  }

  void _pop() {
    setState(() {
      _stackState = _stackState.pop();
    });
  }

  void _clear() {
    setState(() {
      _stackState = StackState(symbols: ['Z']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDA Stack Panel Example')),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Controles de Teste'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _push('A'),
                    child: const Text('Push A'),
                  ),
                  ElevatedButton(
                    onPressed: () => _push('B'),
                    child: const Text('Push B'),
                  ),
                  ElevatedButton(
                    onPressed: _pop,
                    child: const Text('Pop'),
                  ),
                ],
              ),
            ),
          ),
          PdaStackPanel(
            stackState: _stackState,
            initialStackSymbol: 'Z',
            stackAlphabet: {'A', 'B', 'Z'},
            isSimulating: false,
            onClear: _clear,
          ),
        ],
      ),
    );
  }
}
