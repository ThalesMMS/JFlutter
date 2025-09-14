import 'package:flutter/material.dart';
import '../../core/pumping_lemmas.dart';
import '../../core/automaton.dart';

class PumpingLemmaViewer extends StatefulWidget {
  final Automaton? automaton;
  final String? languageDescription;

  const PumpingLemmaViewer({
    super.key,
    this.automaton,
    this.languageDescription,
  });

  @override
  State<PumpingLemmaViewer> createState() => _PumpingLemmaViewerState();
}

class _PumpingLemmaViewerState extends State<PumpingLemmaViewer> {
  PumpingLemma? _pumpingLemma;
  String _word = '';
  int _pumpingLength = 1;
  PumpingResult? _result;
  bool _isAnalyzing = false;
  final TextEditingController _wordCtrl = TextEditingController();
  final TextEditingController _pLenCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _initializePumpingLemma();
  }

  void _initializePumpingLemma() {
    if (widget.automaton != null) {
      _pumpingLemma = PumpingLemmaFactory.createRegular(widget.automaton!);
    } else if (widget.languageDescription != null) {
      _pumpingLemma = PumpingLemmaFactory.createContextFree(widget.languageDescription!);
    }
    _wordCtrl.text = _word;
    _pLenCtrl.text = _pumpingLength.toString();
  }

  Future<void> _analyzeWord() async {
    if (_word.isEmpty || _pumpingLemma == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = _pumpingLemma!.checkPumping(_word, _pumpingLength);
      setState(() {
        _result = result;
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pumpingLemma == null) {
      return const Center(
        child: Text('Nenhum autômato ou linguagem selecionada'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pumpingLemma!.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pumpingLemma!.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Input section
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parâmetros de Análise',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Word input
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Palavra para analisar',
                    hintText: 'Ex: aabb, abab, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  controller: _wordCtrl,
                  onChanged: (value) => setState(() => _word = value),
                ),
                
                const SizedBox(height: 20),
                
                // Pumping length input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Comprimento de bombeamento (p): '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          controller: _pLenCtrl,
                          onChanged: (value) {
                            final length = int.tryParse(value);
                            if (length != null && length > 0) {
                              setState(() => _pumpingLength = length);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Analyze button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _word.isNotEmpty && !_isAnalyzing ? _analyzeWord : null,
                    icon: _isAnalyzing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics, size: 18),
                    label: Text(_isAnalyzing ? 'Analisando...' : 'Analisar Palavra'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Results section
        if (_result != null) ...[
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.canPump ? Icons.check_circle : Icons.cancel,
                        color: _result!.canPump ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.canPump ? 'Pode ser bombeada' : 'Não pode ser bombeada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _result!.canPump ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_result!.explanation != null) ...[
                    const SizedBox(height: 8),
                    Text(_result!.explanation!),
                  ],
                  
                  if (_result!.canPump && _result!.u != null) ...[
                    const SizedBox(height: 16),
                    const Text('Decomposição:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDecomposition(),
                  ],
                  
                  if (!_result!.canPump) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Esta palavra não pode ser bombeada, o que sugere que a linguagem pode não ser regular/context-free.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Examples section
        const SizedBox(height: 16),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exemplos de palavras:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getExampleWords().map((word) => 
                    ActionChip(
                      label: Text(word),
                      onPressed: () => setState(() => _word = word),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecomposition() {
    if (_pumpingLemma is RegularPumpingLemma) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('w = uvw'),
          Text('u = "${_result!.u}"'),
          Text('v = "${_result!.v}"'),
          Text('w = "${_result!.w}"'),
          const SizedBox(height: 8),
          const Text('Teste: uvⁱw ∈ L para i = 0, 1, 2'),
          const SizedBox(height: 4),
          _buildPumpingTest(),
        ],
      );
    } else if (_pumpingLemma is ContextFreePumpingLemma) {
      return const Text(
        'Decomposição detalhada (u, v, w, x, y) não está disponível nesta versão.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPumpingTest() {
    if (_result!.u == null || _result!.v == null || _result!.w == null) {
      return const SizedBox.shrink();
    }

    final u = _result!.u!;
    final v = _result!.v!;
    final w = _result!.w!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('i=0: uv⁰w = "${u}${w}"'),
        Text('i=1: uv¹w = "${u}${v}${w}"'),
        Text('i=2: uv²w = "${u}${v}${v}${w}"'),
      ],
    );
  }

  List<String> _getExampleWords() {
    if (_pumpingLemma is RegularPumpingLemma) {
      return ['a', 'aa', 'aaa', 'ab', 'aab', 'aaab', 'abab'];
    } else if (_pumpingLemma is ContextFreePumpingLemma) {
      final description = widget.languageDescription?.toLowerCase() ?? '';
      switch (description) {
        case 'a^n b^n':
          return ['ab', 'aabb', 'aaabbb', 'aaaabbbb'];
        case 'a^n b^n c^n':
          return ['abc', 'aabbcc', 'aaabbbccc'];
        case 'ww':
          return ['aa', 'abab', 'abcabc', 'aabbaabb'];
        case 'a^n b^m a^n b^m':
          return ['abab', 'aabbaabb', 'aaabbbaaabbb'];
        default:
          return ['ab', 'aabb', 'aaabbb'];
      }
    }
    return [];
  }
}
