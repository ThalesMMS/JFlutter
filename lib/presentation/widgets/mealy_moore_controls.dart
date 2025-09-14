import 'package:flutter/material.dart';
import '../../core/mealy_moore.dart';
import '../../core/mealy_moore_algorithms.dart';

/// Controls panel for Mealy and Moore machines
class MealyMooreControls extends StatefulWidget {
  final dynamic machine; // MealyMachine or MooreMachine
  final Function(dynamic)? onMachineChanged;
  final bool isMealy;
  final bool startCollapsed;
  final bool fullWidth; // bottom bar style when true
  final VoidCallback? onClear;
  final VoidCallback? onToggleLog; // move the log/algoritmo toggle here

  const MealyMooreControls({
    super.key,
    required this.machine,
    this.onMachineChanged,
    required this.isMealy,
    this.startCollapsed = false,
    this.fullWidth = false,
    this.onClear,
    this.onToggleLog,
  });

  @override
  State<MealyMooreControls> createState() => _MealyMooreControlsState();
}

class _MealyMooreControlsState extends State<MealyMooreControls> with TickerProviderStateMixin {
  final TextEditingController _alphabetController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _stateNameController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  
  List<String> _simulationSteps = [];
  bool _isSimulating = false;
  String _simulationResult = '';
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _updateAlphabetDisplay();
    _collapsed = widget.startCollapsed;
  }

  @override
  void dispose() {
    _alphabetController.dispose();
    _inputController.dispose();
    _stateNameController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _updateAlphabetDisplay() {
    if (widget.machine != null) {
      _alphabetController.text = widget.machine.alphabet.join(', ');
    }
  }

  void _updateAlphabet() {
    if (widget.machine == null) return;
    
    final alphabetText = _alphabetController.text.trim();
    if (alphabetText.isEmpty) return;
    
    final alphabet = alphabetText.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    
    setState(() {
      widget.machine.alphabet = alphabet;
    });
    
    widget.onMachineChanged?.call(widget.machine);
  }

  void _addState() {
    if (widget.machine == null) return;
    
    final name = _stateNameController.text.trim();
    if (name.isEmpty) return;
    
    final output = widget.isMealy ? '' : _outputController.text.trim();
    
    setState(() {
      if (widget.isMealy) {
        final mealy = widget.machine as MealyMachine;
        final newState = MealyState(
          id: 'q${mealy.nextId}',
          name: name,
          x: 100.0 + (mealy.states.length * 150.0),
          y: 100.0,
        );
        mealy.states.add(newState);
        mealy.nextId++;
      } else {
        final moore = widget.machine as MooreMachine;
        final newState = MooreState(
          id: 'q${moore.nextId}',
          name: name,
          x: 100.0 + (moore.states.length * 150.0),
          y: 100.0,
          output: output,
        );
        moore.states.add(newState);
        moore.nextId++;
      }
    });
    
    _stateNameController.clear();
    _outputController.clear();
    widget.onMachineChanged?.call(widget.machine);
  }

  void _setInitialState(String stateId) {
    if (widget.machine == null) return;
    
    setState(() {
      if (widget.isMealy) {
        final mealy = widget.machine as MealyMachine;
        for (int i = 0; i < mealy.states.length; i++) {
          mealy.states[i] = mealy.states[i].copyWith(isInitial: mealy.states[i].id == stateId);
        }
        mealy.initialId = stateId;
      } else {
        final moore = widget.machine as MooreMachine;
        for (int i = 0; i < moore.states.length; i++) {
          moore.states[i] = moore.states[i].copyWith(isInitial: moore.states[i].id == stateId);
        }
        moore.initialId = stateId;
      }
    });
    
    widget.onMachineChanged?.call(widget.machine);
  }

  void _simulateInput() {
    if (widget.machine == null || _inputController.text.isEmpty) return;
    
    setState(() {
      _isSimulating = true;
      _simulationSteps.clear();
      _simulationResult = '';
    });
    
    try {
      final input = _inputController.text;
      
      if (widget.isMealy) {
        final result = MealyMooreAlgorithms.simulateMealy(widget.machine, input);
        if (result.isSuccess) {
          final configurations = result.data!;
          _simulationSteps = configurations.map((config) => 
            'Estado: ${config.state}, Entrada: ${config.input}, Saída: ${config.output}'
          ).toList();
          _simulationResult = 'Simulação concluída com ${configurations.length} passos';
        } else {
          _simulationResult = 'Erro na simulação: ${result.error}';
        }
      } else {
        final result = MealyMooreAlgorithms.simulateMoore(widget.machine, input);
        if (result.isSuccess) {
          final configurations = result.data!;
          _simulationSteps = configurations.map((config) => 
            'Estado: ${config.state}, Entrada: ${config.input}, Saída: ${config.output}'
          ).toList();
          _simulationResult = 'Simulação concluída com ${configurations.length} passos';
        } else {
          _simulationResult = 'Erro na simulação: ${result.error}';
        }
      }
    } catch (e) {
      _simulationResult = 'Erro na simulação: $e';
    }
    
    setState(() {
      _isSimulating = false;
    });
  }

  void _convertMachine() {
    if (widget.machine == null) return;
    
    try {
      if (widget.isMealy) {
        final result = MealyMooreAlgorithms.mealyToMoore(widget.machine);
        if (result.isSuccess) {
          widget.onMachineChanged?.call(result.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máquina convertida de Mealy para Moore')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na conversão: ${result.error}')),
          );
        }
      } else {
        final result = MealyMooreAlgorithms.mooreToMealy(widget.machine);
        if (result.isSuccess) {
          widget.onMachineChanged?.call(result.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máquina convertida de Moore para Mealy')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na conversão: ${result.error}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na conversão: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: widget.fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header with actions and collapse toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Controles ${widget.isMealy ? 'Mealy' : 'Moore'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Log/Algoritmo',
                  onPressed: widget.onToggleLog,
                  icon: const Icon(Icons.list_alt),
                ),
                IconButton(
                  tooltip: 'Limpar máquina',
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.clear),
                ),
                IconButton(
                  tooltip: _collapsed ? 'Expandir' : 'Recolher',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _collapsed
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Alphabet definition
                          TextField(
                            controller: _alphabetController,
                            decoration: const InputDecoration(
                              labelText: 'Alfabeto (separado por vírgulas)',
                              hintText: 'Ex: a, b, c',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _updateAlphabet(),
                          ),
                          const SizedBox(height: 16),

                          // Add state
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _stateNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome do Estado',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              if (!widget.isMealy) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _outputController,
                                    decoration: const InputDecoration(
                                      labelText: 'Saída',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addState,
                                child: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Initial state selection
                          if (widget.machine != null && widget.machine.states.isNotEmpty) ...[
                            Text(
                              'Estado Inicial:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: widget.machine.states.map((state) {
                                final isInitial = widget.machine.initialId == state.id;
                                return FilterChip(
                                  label: Text(state.name),
                                  selected: isInitial,
                                  onSelected: (_) => _setInitialState(state.id),
                                  selectedColor: Colors.blue.shade100,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Simulation
                          TextField(
                            controller: _inputController,
                            decoration: const InputDecoration(
                              labelText: 'String de entrada',
                              hintText: 'Ex: abab',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isSimulating ? null : _simulateInput,
                                icon: _isSimulating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.play_arrow),
                                label: Text(_isSimulating ? 'Simulando...' : 'Simular'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _convertMachine,
                                icon: const Icon(Icons.transform),
                                label: Text('Converter para ${widget.isMealy ? 'Moore' : 'Mealy'}'),
                              ),
                            ],
                          ),

                          // Simulation results
                          if (_simulationResult.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                border: Border.all(color: Colors.blue.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resultado:',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_simulationResult),
                                ],
                              ),
                            ),
                          ],

                          // Simulation steps
                          if (_simulationSteps.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Passos da Simulação:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                itemCount: _simulationSteps.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      _simulationSteps[index],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
