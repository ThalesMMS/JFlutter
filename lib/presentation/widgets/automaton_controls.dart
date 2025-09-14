import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/parsers/jflap_xml_parser.dart';
import '../../core/automaton.dart';
import '../providers/automaton_provider.dart';
import '../providers/algorithm_provider.dart';
import '../../injection/dependency_injection.dart';
import 'contextual_help.dart';
import 'advanced_export_tools.dart';

/// Controls widget for managing automatons
class AutomatonControls extends StatefulWidget {
  final AutomatonType type;
  final void Function(AutomatonEntity)? onAutomatonChanged;
  final GlobalKey? canvasKey;

  const AutomatonControls({
    super.key,
    required this.type,
    this.onAutomatonChanged,
    this.canvasKey,
  });

  @override
  State<AutomatonControls> createState() => _AutomatonControlsState();
}

class _AutomatonControlsState extends State<AutomatonControls> {
  final TextEditingController _alphabetController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();

  @override
  void dispose() {
    _alphabetController.dispose();
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatesCard(),
        const SizedBox(height: 16),
        _buildAlphabetCard(),
        const SizedBox(height: 16),
        _buildSimulationCard(),
        const SizedBox(height: 16),
        _buildExportImportCard(),
      ],
    );
  }

  Widget _buildAlphabetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Alfabeto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                ContextualHelp(
                  helpContent: 'O alfabeto define os símbolos que o automaton pode processar. Digite os símbolos separados por vírgula (ex: a,b,c) ou espaços (ex: a b c).',
                  title: 'Alfabeto',
                  icon: Icons.abc,
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _alphabetController,
                    decoration: const InputDecoration(
                      hintText: 'Símbolos separados por vírgula. Ex: A,B',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _setAlphabet,
                  child: const Text('Definir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use apenas símbolos unitários (sem strings). Ex.: A, B, 0, 1.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _addState,
                  child: const Text('Novo estado'),
                ),
                OutlinedButton(
                  onPressed: _toggleInitial,
                  child: const Text('Inicial'),
                ),
                OutlinedButton(
                  onPressed: _toggleFinal,
                  child: const Text('Aceite'),
                ),
                OutlinedButton(
                  onPressed: _startTransitionMode,
                  child: const Text('Transição'),
                ),
                OutlinedButton(
                  onPressed: _deleteSelected,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Excluir'),
                ),
                OutlinedButton(
                  onPressed: _clearAutomaton,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simular Palavra',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: ABAAB',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _runSimulation,
                  child: const Text('Rodar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _runStepByStep,
                  child: const Text('Modo Run'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Resultado da simulação aparecerá aqui',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exportar / Importar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportAutomaton,
                  icon: const Icon(Icons.upload),
                  label: const Text('Exportar AF'),
                ),
                ElevatedButton.icon(
                  onPressed: _importAutomaton,
                  icon: const Icon(Icons.download),
                  label: const Text('Importar AF'),
                ),
                OutlinedButton.icon(
                  onPressed: _importFromClipboard,
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Colar da Área de Transferência'),
                ),
                if (widget.canvasKey != null)
                  ElevatedButton.icon(
                    onPressed: _showAdvancedExportDialog,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportação Avançada'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Exporta um JSON com Σ, estados, transições, inicial e nextId. Importar substituirá o AF atual. Suporta arquivos JSON e JFLAP (.jff).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _setAlphabet() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final alphabetText = _alphabetController.text.trim();
    
    if (alphabetText.isEmpty) {
      _showError('Digite pelo menos um símbolo para o alfabeto');
      return;
    }

    // Parse alphabet symbols
    final symbols = alphabetText
        .split(RegExp(r'[,;\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    if (symbols.isEmpty) {
      _showError('Nenhum símbolo válido encontrado');
      return;
    }

    // Update current automaton's alphabet
    if (automatonProvider.currentAutomaton != null) {
      final updatedAutomaton = automatonProvider.currentAutomaton!.copyWith(
        alphabet: symbols,
      );
          automatonProvider.currentAutomaton = updatedAutomaton;
      widget.onAutomatonChanged?.call(updatedAutomaton);
      _showSuccess('Alfabeto definido: ${symbols.join(', ')}');
    } else {
      _showError('Nenhum automaton carregado');
    }
  }

  void _addState() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    // Create a new automaton if none exists
    if (automatonProvider.currentAutomaton == null) {
      final newAutomaton = AutomatonEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Novo Automaton',
        alphabet: const <String>{},
        states: const <StateEntity>[],
        transitions: const <String, List<String>>{},
        initialId: null,
        nextId: 1,
        type: widget.type,
      );
      automatonProvider.currentAutomaton = newAutomaton;
    }

    // Generate unique state name
    int counter = 1;
    String newName = 'q$counter';
    while (automatonProvider.currentAutomaton!.states.any((s) => s.name == newName)) {
      counter++;
      newName = 'q$counter';
    }

    // Generate unique state ID
    String newId = 'state_$counter';
    while (automatonProvider.currentAutomaton!.states.any((s) => s.id == newId)) {
      counter++;
      newId = 'state_$counter';
    }

    // Calculate better position for new state
    final existingStates = automatonProvider.currentAutomaton!.states;
    double x, y;
    
    if (existingStates.isEmpty) {
      // First state goes to center
      x = 200.0;
      y = 200.0;
    } else {
      // Position new state in a grid pattern
      final stateCount = existingStates.length;
      final cols = math.sqrt(stateCount + 1).ceil();
      final row = stateCount ~/ cols;
      final col = stateCount % cols;
      
      // Grid spacing
      const spacing = 120.0;
      const startX = 100.0;
      const startY = 100.0;
      
      x = startX + (col * spacing);
      y = startY + (row * spacing);
      
      // Ensure state doesn't overlap with existing states
      bool hasOverlap = true;
      int attempts = 0;
      while (hasOverlap && attempts < 10) {
        hasOverlap = false;
        for (final state in existingStates) {
          final distance = math.sqrt(math.pow(x - state.x, 2) + math.pow(y - state.y, 2));
          if (distance < 80.0) { // Minimum distance between states
            hasOverlap = true;
            x += 40.0;
            y += 40.0;
            attempts++;
            break;
          }
        }
      }
    }

    final newState = StateEntity(
      id: newId,
      name: newName,
      x: x,
      y: y,
      isInitial: automatonProvider.currentAutomaton!.states.isEmpty, // First state is initial
      isFinal: false,
    );

    final updatedStates = [...automatonProvider.currentAutomaton!.states, newState];
    final updatedAutomaton = automatonProvider.currentAutomaton!.copyWith(
      states: updatedStates,
      initialId: automatonProvider.currentAutomaton!.states.isEmpty ? newId : automatonProvider.currentAutomaton!.initialId,
    );
    
    automatonProvider.currentAutomaton = updatedAutomaton;
    automatonProvider.notifyListeners();
    widget.onAutomatonChanged?.call(updatedAutomaton);
    
    _showSuccess('Estado $newName adicionado');
  }

  void _toggleInitial() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    if (automatonProvider.currentAutomaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }
    
    // Get selected states from the provider (if available)
    final selectedStates = automatonProvider.selectedStates;
    if (selectedStates.isEmpty) {
      _showError('Selecione um estado no canvas primeiro');
      return;
    }
    
    if (selectedStates.length > 1) {
      _showError('Selecione apenas um estado para definir como inicial');
      return;
    }
    
    final stateId = selectedStates.first;
    final state = automatonProvider.currentAutomaton!.getState(stateId);
    if (state == null) {
      _showError('Estado não encontrado');
      return;
    }
    
    // Toggle initial state
    final updatedStates = automatonProvider.currentAutomaton!.states.map((s) {
      if (s.id == stateId) {
        return s.copyWith(isInitial: !s.isInitial);
      } else if (s.isInitial) {
        // Remove initial from other states (only one initial state allowed)
        return s.copyWith(isInitial: false);
      }
      return s;
    }).toList();
    
    final updatedAutomaton = automatonProvider.currentAutomaton!.copyWith(states: updatedStates);
    automatonProvider.currentAutomaton = updatedAutomaton;
    automatonProvider.notifyListeners();
    widget.onAutomatonChanged?.call(updatedAutomaton);
    
    _showSuccess('Estado ${state.name} ${state.isInitial ? 'removido como' : 'definido como'} inicial');
  }

  void _toggleFinal() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    if (automatonProvider.currentAutomaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }
    
    // Get selected states from the provider (if available)
    final selectedStates = automatonProvider.selectedStates;
    if (selectedStates.isEmpty) {
      _showError('Selecione um estado no canvas primeiro');
      return;
    }
    
    if (selectedStates.length > 1) {
      _showError('Selecione apenas um estado para definir como final');
      return;
    }
    
    final stateId = selectedStates.first;
    final state = automatonProvider.currentAutomaton!.getState(stateId);
    if (state == null) {
      _showError('Estado não encontrado');
      return;
    }
    
    // Toggle final state
    final updatedStates = automatonProvider.currentAutomaton!.states.map((s) {
      if (s.id == stateId) {
        return s.copyWith(isFinal: !s.isFinal);
      }
      return s;
    }).toList();
    
    final updatedAutomaton = automatonProvider.currentAutomaton!.copyWith(states: updatedStates);
    automatonProvider.currentAutomaton = updatedAutomaton;
    automatonProvider.notifyListeners();
    widget.onAutomatonChanged?.call(updatedAutomaton);
    
    _showSuccess('Estado ${state.name} ${state.isFinal ? 'removido como' : 'definido como'} final');
  }

  void _deleteSelected() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final automaton = automatonProvider.currentAutomaton;
    if (automaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }

    final selectedStates = automatonProvider.selectedStates;
    if (selectedStates.isEmpty) {
      _showError('Selecione pelo menos um estado para excluir');
      return;
    }

    // Remove selected states
    final newStates = automaton.states
        .where((state) => !selectedStates.contains(state.id))
        .toList();

    // Remove transitions from/to deleted states
    final newTransitions = Map<String, List<String>>.from(automaton.transitions);
    newTransitions.removeWhere((key, value) {
      final parts = key.split('|');
      return parts.length == 2 && selectedStates.contains(parts[0]);
    });
    for (final key in newTransitions.keys.toList()) {
      newTransitions[key] = newTransitions[key]!
          .where((dest) => !selectedStates.contains(dest))
          .toList();
      if (newTransitions[key]!.isEmpty) {
        newTransitions.remove(key);
      }
    }

    final updated = automaton.copyWith(states: newStates, transitions: newTransitions);
    automatonProvider.setAutomaton(updated);
    automatonProvider.clearSelectedStates();
    _showSuccess('Exclusão concluída');
  }

  void _startTransitionMode() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    if (automatonProvider.isConnectingStates) {
      automatonProvider.finishConnecting();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo Transição cancelado')),
      );
      return;
    }
    final selected = automatonProvider.selectedStates;
    if (selected.isEmpty) {
      automatonProvider.startConnecting();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo Transição: toque em origem e destino para criar uma transição')),
      );
    } else {
      automatonProvider.startConnecting(fromStateId: selected.first);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo Transição: selecione o estado de destino')),
      );
    }
  }

  void _clearAutomaton() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Automaton'),
        content: const Text('Tem certeza que deseja limpar o automaton atual? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              automatonProvider.clearAutomaton();
              // Don't call onAutomatonChanged when clearing since it expects non-null
              _showSuccess('Automaton limpo');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _runSimulation() async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    final word = _wordController.text.trim();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }

    if (word.isEmpty) {
      _showError('Digite uma palavra para simular');
      return;
    }

    final result = await algorithmProvider.simulateWord(automatonProvider.currentAutomaton!, word);
    if (result != null) {
      final message = result.accepted ? 'Palavra ACEITA' : 'Palavra REJEITADA';
      final color = result.accepted ? Colors.green : Colors.red;
      _showSimulationResult(message, color);
    } else {
      _showError(algorithmProvider.error ?? 'Erro na simulação');
    }
  }

  void _runStepByStep() async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    final word = _wordController.text.trim();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }

    if (word.isEmpty) {
      _showError('Digite uma palavra para simular');
      return;
    }

    final result = await algorithmProvider.createStepByStepSimulation(automatonProvider.currentAutomaton!, word);
    if (result != null) {
      _showStepByStepSimulation(result);
    } else {
      _showError(algorithmProvider.error ?? 'Erro na simulação passo-a-passo');
    }
  }

  void _exportAutomaton() async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    if (automatonProvider.currentAutomaton == null) {
      _showError('Nenhum automaton carregado');
      return;
    }

    final jsonString = await automatonProvider.exportAutomaton();
    if (jsonString != null) {
      await Clipboard.setData(ClipboardData(text: jsonString));
      _showSuccess('Automaton exportado e copiado para a área de transferência');
    } else {
      _showError(automatonProvider.error ?? 'Erro na exportação');
    }
  }

  void _importAutomaton() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'jff'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final fileContent = String.fromCharCodes(file.bytes!);
          final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
          
          // Verificar se é arquivo JFLAP (.jff) ou JSON
          if (file.extension == 'jff') {
            final parseResult = JFLAPXMLParser.parseJFLAPFile(fileContent);
            if (parseResult.isSuccess) {
              // Converter para AutomatonEntity se necessário
              if (parseResult.data is AutomatonEntity) {
                automatonProvider.setAutomaton(parseResult.data);
                _showSuccess('Arquivo JFLAP importado com sucesso');
              } else {
                _showError('Tipo de autômato JFLAP não suportado nesta aba');
              }
            } else {
              _showError('Erro ao importar arquivo JFLAP: ${parseResult.error}');
            }
          } else {
            // Importar como JSON
            final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
            final automatonCore = Automaton.fromJson(jsonData);
            // Convert to AutomatonEntity format
            final importedAutomaton = AutomatonEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'Imported Automaton',
              alphabet: automatonCore.alphabet,
              states: automatonCore.states.map((s) => StateEntity(
                id: s.id,
                name: s.name,
                x: s.x,
                y: s.y,
                isInitial: s.isInitial,
                isFinal: s.isFinal,
              )).toList(),
              transitions: automatonCore.transitions,
              initialId: automatonCore.initialId,
              nextId: automatonCore.nextId,
              type: AutomatonType.nfa,
            );
            automatonProvider.setAutomaton(importedAutomaton);
            _showSuccess('Automaton importado com sucesso');
          }
        }
      }
    } catch (e) {
      _showError('Erro ao importar: $e');
    }
  }

  void _importFromClipboard() async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        await automatonProvider.importAutomaton(clipboardData!.text!);
        if (automatonProvider.currentAutomaton != null) {
          widget.onAutomatonChanged?.call(automatonProvider.currentAutomaton!);
        }
        _showSuccess('Automaton importado com sucesso');
      } else {
        _showError('Nenhum texto encontrado na área de transferência');
      }
    } catch (e) {
      _showError('Erro ao importar: $e');
    }
  }

  // Helper methods
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSimulationResult(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showStepByStepSimulation(StepByStepSimulation simulation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Simulação Passo-a-Passo: ${simulation.word}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: simulation.messages.length,
            itemBuilder: (context, index) {
              final message = simulation.messages[index];
              final isCurrentStep = index == simulation.stepIndex;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrentStep ? Colors.blue.withOpacity(0.1) : null,
                  border: isCurrentStep ? Border.all(color: Colors.blue) : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Passo ${index + 1}: $message',
                  style: TextStyle(
                    fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedExportDialog() {
    if (widget.canvasKey == null) return;
    
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final currentAutomaton = automatonProvider.currentAutomaton;
    
    if (currentAutomaton == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AdvancedExportDialog(
        automaton: currentAutomaton,
        canvasKey: widget.canvasKey!,
      ),
    );
  }
}
