import 'package:flutter/material.dart';
import '../../core/mealy_moore.dart';
import '../widgets/mealy_moore_canvas.dart';
import '../widgets/mealy_moore_controls.dart';
import '../widgets/common_ui_components.dart';

/// Page for Mealy and Moore machines
class MealyMoorePage extends StatefulWidget {
  final bool isMealy;

  const MealyMoorePage({
    super.key,
    required this.isMealy,
  });

  @override
  State<MealyMoorePage> createState() => _MealyMoorePageState();
}

class _MealyMoorePageState extends State<MealyMoorePage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  dynamic _machine; // MealyMachine or MooreMachine
  List<String> _selectedStates = [];
  List<String> _selectedTransitions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMachine();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMachine() {
    setState(() {
      if (widget.isMealy) {
        _machine = MealyMachine.empty();
      } else {
        _machine = MooreMachine.empty();
      }
    });
  }

  void _onMachineChanged(dynamic newMachine) {
    setState(() {
      _machine = newMachine;
    });
  }

  void _onStateSelected(String stateId) {
    setState(() {
      if (stateId.isEmpty) {
        _selectedStates.clear();
      } else if (_selectedStates.contains(stateId)) {
        _selectedStates.remove(stateId);
      } else {
        _selectedStates.add(stateId);
      }
    });
  }

  void _onTransitionSelected(String transitionId) {
    setState(() {
      if (_selectedTransitions.contains(transitionId)) {
        _selectedTransitions.remove(transitionId);
      } else {
        _selectedTransitions.add(transitionId);
      }
    });
  }

  void _clearMachine() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Máquina'),
        content: const Text('Tem certeza que deseja limpar a máquina atual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeMachine();
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _loadExample() {
    setState(() {
      if (widget.isMealy) {
        _machine = _createExampleMealy();
      } else {
        _machine = _createExampleMoore();
      }
    });
  }

  MealyMachine _createExampleMealy() {
    final mealy = MealyMachine(
      alphabet: {'a', 'b'},
      states: [
        MealyState(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true),
        MealyState(id: 'q1', name: 'q1', x: 300, y: 100),
      ],
      transitions: [
        MealyTransition(fromState: 'q0', toState: 'q1', input: 'a', output: '0'),
        MealyTransition(fromState: 'q1', toState: 'q0', input: 'b', output: '1'),
      ],
      initialId: 'q0',
      nextId: 2,
    );
    return mealy;
  }

  MooreMachine _createExampleMoore() {
    final moore = MooreMachine(
      alphabet: {'a', 'b'},
      states: [
        MooreState(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, output: '0'),
        MooreState(id: 'q1', name: 'q1', x: 300, y: 100, output: '1'),
      ],
      transitions: [
        MooreTransition(fromState: 'q0', toState: 'q1', input: 'a'),
        MooreTransition(fromState: 'q1', toState: 'q0', input: 'b'),
      ],
      initialId: 'q0',
      nextId: 2,
    );
    return moore;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: isMobile
          ? null
          : AppBar(
              title: const Text(''),
              bottom: ResponsiveTabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Editar', icon: Icon(Icons.edit)),
                  Tab(text: 'Simular', icon: Icon(Icons.play_arrow)),
                ],
              ),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(isMobile),
          _buildSimulateTab(isMobile),
        ],
      ),
    );
  }

  Widget _buildEditTab(bool isMobile) {
    return Column(
      children: [
        Expanded(
          child: isMobile ? Column(
            children: [
          Expanded(
            child: MealyMooreCanvas(
              machine: _machine,
              onStateSelected: _onStateSelected,
              onTransitionSelected: _onTransitionSelected,
              selectedStates: _selectedStates,
              selectedTransitions: _selectedTransitions,
              isMealy: widget.isMealy,
            ),
          ),
          // Bottom full‑width controls, expanded por padrão
          MealyMooreControls(
            machine: _machine,
            onMachineChanged: _onMachineChanged,
            isMealy: widget.isMealy,
            startCollapsed: false,
            fullWidth: true,
            onClear: _clearMachine,
            onToggleLog: () {
              // Placeholder for future log/algoritmo toggle
            },
          ),
            ],
          ) : Row(
            children: [
              Expanded(
                flex: 2,
                child: MealyMooreCanvas(
                  machine: _machine,
                  onStateSelected: _onStateSelected,
                  onTransitionSelected: _onTransitionSelected,
                  selectedStates: _selectedStates,
                  selectedTransitions: _selectedTransitions,
                  isMealy: widget.isMealy,
                ),
              ),
              Expanded(
                flex: 1,
                child: MealyMooreControls(
                  machine: _machine,
                  onMachineChanged: _onMachineChanged,
                  isMealy: widget.isMealy,
                  startCollapsed: false,
                  fullWidth: false,
                  onClear: _clearMachine,
                  onToggleLog: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimulateTab(bool isMobile) {
    return Padding(
      padding: CommonUIComponents.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Simulação ${widget.isMealy ? 'Mealy' : 'Moore'}',
            subtitle: 'Teste strings e visualize a saída da máquina',
            icon: Icons.play_arrow,
          ),
          
          // Machine info
          StandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações da Máquina',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_machine != null) ...[
                  Text('Estados: ${_machine.states.length}'),
                  Text('Transições: ${_machine.transitions.length}'),
                  Text('Alfabeto: ${_machine.alphabet.join(', ')}'),
                  if (_machine.initialId != null)
                    Text('Estado inicial: ${_machine.getState(_machine.initialId)?.name ?? 'N/A'}'),
                ] else
                  const Text('Nenhuma máquina definida'),
              ],
            ),
          ),
          
          const SizedBox(height: CommonUIComponents.sectionSpacing),
          
          // Simulation controls
          Expanded(
            child: MealyMooreControls(
              machine: _machine,
              onMachineChanged: _onMachineChanged,
              isMealy: widget.isMealy,
            ),
          ),
        ],
      ),
    );
  }
}
