import 'package:flutter/material.dart';
import '../../core/pumping_lemmas.dart';
import 'contextual_help.dart';

/// Interactive pumping lemma interface based on JFLAP
/// Provides step-by-step pumping lemma demonstrations for regular and context-free languages
class PumpingLemmaInterface extends StatefulWidget {
  const PumpingLemmaInterface({super.key});

  @override
  State<PumpingLemmaInterface> createState() => _PumpingLemmaInterfaceState();
}

class _PumpingLemmaInterfaceState extends State<PumpingLemmaInterface> {
  PumpingLemmaType _selectedType = PumpingLemmaType.regular;
  PumpingLemmaBase? _currentLemma;
  String _currentString = '';
  int _pumpingLength = 0;
  int _pumpingIndex = 0;
  String _decomposition = '';
  String _pumpedString = '';
  String _explanation = '';
  bool _isAnimating = false;
  int _animationStep = 0;
  List<String> _attempts = [];
  String _currentAttempt = '';

  @override
  void initState() {
    super.initState();
    _initializeLemma();
  }

  void _initializeLemma() {
    setState(() {
      _currentLemma = _createLemma(_selectedType);
      _currentString = '';
      _pumpingLength = 0;
      _pumpingIndex = 0;
      _decomposition = '';
      _pumpedString = '';
      _explanation = 'Selecione um tipo de lema e uma string para testar.';
      _isAnimating = false;
      _animationStep = 0;
      _attempts.clear();
      _currentAttempt = '';
    });
  }

  PumpingLemmaBase _createLemma(PumpingLemmaType type) {
    switch (type) {
      case PumpingLemmaType.regular:
        return RegularPumpingLemmaInterface();
      case PumpingLemmaType.contextFree:
        return ContextFreePumpingLemmaInterface();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Lema do Bombeamento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                ContextualHelp(
                  helpContent: HelpContent.pumpingLemmas,
                  title: 'Lema do Bombeamento',
                  icon: Icons.water_drop,
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type selection
            _buildTypeSelection(),
            const SizedBox(height: 16),
            
            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use responsive layout based on screen width
                  if (constraints.maxWidth < 800) {
                    // Mobile layout: Stack panels vertically
                    return Column(
                      children: [
                        // Input and controls
                        Expanded(
                          flex: 1,
                          child: _buildInputPanel(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Animation and results
                        Expanded(
                          flex: 1,
                          child: _buildAnimationPanel(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop layout: Side by side panels
                    return Row(
                      children: [
                        // Left panel - Input and controls
                        Expanded(
                          flex: 1,
                          child: _buildInputPanel(),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Right panel - Animation and results
                        Expanded(
                          flex: 1,
                          child: _buildAnimationPanel(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Lema',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PumpingLemmaType>(
                    title: const Text('Regular'),
                    subtitle: const Text('Decomposição xyz'),
                    value: PumpingLemmaType.regular,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                        _initializeLemma();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<PumpingLemmaType>(
                    title: const Text('Context-Free'),
                    subtitle: const Text('Decomposição uvwxy'),
                    value: PumpingLemmaType.contextFree,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                        _initializeLemma();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrada',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            
            // String input
            TextField(
              decoration: const InputDecoration(
                labelText: 'String w para testar',
                hintText: 'Ex: aabb, a^n b^n, etc.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _currentString = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Pumping length input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Comprimento de bombeamento (m)',
                hintText: 'Ex: 3, 5, etc.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _pumpingLength = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Pumping index input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Índice de bombeamento (i)',
                hintText: 'Ex: 0, 1, 2, etc.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _pumpingIndex = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentString.isNotEmpty ? _testString : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Testar String'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentString.isNotEmpty ? _startAnimation : null,
                  icon: const Icon(Icons.animation),
                  label: const Text('Animar'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Decomposition display
            if (_decomposition.isNotEmpty) ...[
              Text(
                'Decomposição:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _decomposition,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animação e Resultados',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            
            // Animation controls
            if (_isAnimating) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _stepAnimation,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Passo'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _stopAnimation,
                    icon: const Icon(Icons.stop),
                    label: const Text('Parar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Animation display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'String Original:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentString,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (_pumpedString.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'String Bombeada:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pumpedString,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    
                    if (_explanation.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Explicação:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Attempts list
            if (_attempts.isNotEmpty) ...[
              Text(
                'Tentativas:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _attempts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          _attempts[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _testString() {
    if (_currentString.isEmpty || _currentLemma == null) return;
    
    setState(() {
      _currentAttempt = 'Testando: $_currentString';
      _attempts.add(_currentAttempt);
    });
    
    // Perform pumping lemma test
    final result = _currentLemma!.testString(_currentString, _pumpingLength, _pumpingIndex);
    
    setState(() {
      _decomposition = result.decomposition;
      _pumpedString = result.pumpedString;
      _explanation = result.explanation;
    });
  }

  void _startAnimation() {
    if (_currentString.isEmpty) return;
    
    setState(() {
      _isAnimating = true;
      _animationStep = 0;
    });
    
    _stepAnimation();
  }

  void _stepAnimation() {
    if (!_isAnimating || _currentLemma == null) return;
    
    setState(() {
      _animationStep++;
    });
    
    // Animate the pumping process
    final result = _currentLemma!.animateStep(_currentString, _pumpingLength, _pumpingIndex, _animationStep);
    
    setState(() {
      _decomposition = result.decomposition;
      _pumpedString = result.pumpedString;
      _explanation = result.explanation;
    });
    
    if (_animationStep >= 5) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _stopAnimation() {
    setState(() {
      _isAnimating = false;
      _animationStep = 0;
    });
  }

  void _reset() {
    setState(() {
      _currentString = '';
      _pumpingLength = 0;
      _pumpingIndex = 0;
      _decomposition = '';
      _pumpedString = '';
      _explanation = 'Selecione um tipo de lema e uma string para testar.';
      _isAnimating = false;
      _animationStep = 0;
      _attempts.clear();
      _currentAttempt = '';
    });
  }
}

/// Types of pumping lemmas
enum PumpingLemmaType {
  regular,
  contextFree,
}

/// Result of a pumping lemma test
class PumpingLemmaResult {
  final String decomposition;
  final String pumpedString;
  final String explanation;
  final bool isInLanguage;

  PumpingLemmaResult({
    required this.decomposition,
    required this.pumpedString,
    required this.explanation,
    required this.isInLanguage,
  });
}

/// Base class for pumping lemmas
abstract class PumpingLemmaBase {
  PumpingLemmaResult testString(String w, int m, int i);
  PumpingLemmaResult animateStep(String w, int m, int i, int step);
}

/// Regular pumping lemma implementation
class RegularPumpingLemmaInterface extends PumpingLemmaBase {
  @override
  PumpingLemmaResult testString(String w, int m, int i) {
    if (w.length < m) {
      return PumpingLemmaResult(
        decomposition: 'w = $w (|w| = ${w.length} < m = $m)',
        pumpedString: w,
        explanation: 'String muito curta para aplicar o lema do bombeamento.',
        isInLanguage: true,
      );
    }
    
    // Simple decomposition for demonstration
    final x = w.substring(0, 1);
    final y = w.substring(1, 2);
    final z = w.substring(2);
    
    final pumped = x + (y * i) + z;
    
    return PumpingLemmaResult(
      decomposition: 'w = $w = xyz onde x=$x, y=$y, z=$z',
      pumpedString: pumped,
      explanation: 'Para i=$i: xy^i z = $pumped. Se a linguagem for regular, esta string deve estar na linguagem.',
      isInLanguage: true,
    );
  }

  @override
  PumpingLemmaResult animateStep(String w, int m, int i, int step) {
    switch (step) {
      case 1:
        return PumpingLemmaResult(
          decomposition: 'Passo 1: Verificando se |w| ≥ m',
          pumpedString: w,
          explanation: 'w = $w, |w| = ${w.length}, m = $m',
          isInLanguage: true,
        );
      case 2:
        return PumpingLemmaResult(
          decomposition: 'Passo 2: Decompondo w = xyz',
          pumpedString: w,
          explanation: 'Escolhendo x, y, z tais que |xy| ≤ m e |y| ≥ 1',
          isInLanguage: true,
        );
      case 3:
        final x = w.substring(0, 1);
        final y = w.substring(1, 2);
        final z = w.substring(2);
        return PumpingLemmaResult(
          decomposition: 'w = $w = xyz onde x=$x, y=$y, z=$z',
          pumpedString: w,
          explanation: 'Decomposição: x=$x, y=$y, z=$z',
          isInLanguage: true,
        );
      case 4:
        final x = w.substring(0, 1);
        final y = w.substring(1, 2);
        final z = w.substring(2);
        final pumped = x + (y * i) + z;
        return PumpingLemmaResult(
          decomposition: 'w = $w = xyz onde x=$x, y=$y, z=$z',
          pumpedString: pumped,
          explanation: 'Bombeando y $i vezes: xy^i z = $pumped',
          isInLanguage: true,
        );
      default:
        return testString(w, m, i);
    }
  }
}

/// Context-free pumping lemma implementation
class ContextFreePumpingLemmaInterface extends PumpingLemmaBase {
  @override
  PumpingLemmaResult testString(String w, int m, int i) {
    if (w.length < m) {
      return PumpingLemmaResult(
        decomposition: 'w = $w (|w| = ${w.length} < m = $m)',
        pumpedString: w,
        explanation: 'String muito curta para aplicar o lema do bombeamento.',
        isInLanguage: true,
      );
    }
    
    // Simple decomposition for demonstration
    final u = w.substring(0, 1);
    final v = w.substring(1, 2);
    final wPart = w.substring(2, 3);
    final x = w.substring(3, 4);
    final y = w.substring(4);
    
    final pumped = u + (v * i) + wPart + (x * i) + y;
    
    return PumpingLemmaResult(
      decomposition: 'w = $w = uvwxy onde u=$u, v=$v, w=$wPart, x=$x, y=$y',
      pumpedString: pumped,
      explanation: 'Para i=$i: uv^i wx^i y = $pumped. Se a linguagem for livre de contexto, esta string deve estar na linguagem.',
      isInLanguage: true,
    );
  }

  @override
  PumpingLemmaResult animateStep(String w, int m, int i, int step) {
    switch (step) {
      case 1:
        return PumpingLemmaResult(
          decomposition: 'Passo 1: Verificando se |w| ≥ m',
          pumpedString: w,
          explanation: 'w = $w, |w| = ${w.length}, m = $m',
          isInLanguage: true,
        );
      case 2:
        return PumpingLemmaResult(
          decomposition: 'Passo 2: Decompondo w = uvwxy',
          pumpedString: w,
          explanation: 'Escolhendo u, v, w, x, y tais que |vwx| ≤ m e |vx| ≥ 1',
          isInLanguage: true,
        );
      case 3:
        final u = w.substring(0, 1);
        final v = w.substring(1, 2);
        final wPart = w.substring(2, 3);
        final x = w.substring(3, 4);
        final y = w.substring(4);
        return PumpingLemmaResult(
          decomposition: 'w = $w = uvwxy onde u=$u, v=$v, w=$wPart, x=$x, y=$y',
          pumpedString: w,
          explanation: 'Decomposição: u=$u, v=$v, w=$wPart, x=$x, y=$y',
          isInLanguage: true,
        );
      case 4:
        final u = w.substring(0, 1);
        final v = w.substring(1, 2);
        final wPart = w.substring(2, 3);
        final x = w.substring(3, 4);
        final y = w.substring(4);
        final pumped = u + (v * i) + wPart + (x * i) + y;
        return PumpingLemmaResult(
          decomposition: 'w = $w = uvwxy onde u=$u, v=$v, w=$wPart, x=$x, y=$y',
          pumpedString: pumped,
          explanation: 'Bombeando v e x $i vezes: uv^i wx^i y = $pumped',
          isInLanguage: true,
        );
      default:
        return testString(w, m, i);
    }
  }
}
