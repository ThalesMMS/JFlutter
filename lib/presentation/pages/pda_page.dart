import 'package:flutter/material.dart';
import '../../core/pda.dart';
import '../../core/pda_algorithms.dart';
import '../widgets/pda_canvas.dart';
import '../widgets/pda_controls.dart';

/// PDA Page - Main interface for Pushdown Automata
/// Optimized for mobile devices with responsive layout
class PDAPage extends StatefulWidget {
  const PDAPage({super.key});

  @override
  State<PDAPage> createState() => _PDAPageState();
}

class _PDAPageState extends State<PDAPage> with TickerProviderStateMixin {
  late PushdownAutomaton _pda;
  Set<String> _selectedStates = {};
  bool _isSimulating = false;
  List<PDAConfiguration> _simulationConfigs = [];
  int _currentSimulationStep = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pda = PushdownAutomaton.empty();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pushdown Automaton'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.play_arrow), text: 'Simulate'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(),
          _buildSimulateTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildEditTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        if (isMobile) {
          // Mobile layout: stacked
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: PDACanvas(
                  pda: _pda,
                  onPDAChanged: _updatePDA,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: PDAControls(
                    pda: _pda,
                    onPDAChanged: _updatePDA,
                    onSimulationRequested: _startSimulation,
                  ),
                ),
              ),
            ],
          );
        } else {
          // Desktop layout: side by side
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: PDACanvas(
                  pda: _pda,
                  onPDAChanged: _updatePDA,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: PDAControls(
                    pda: _pda,
                    onPDAChanged: _updatePDA,
                    onSimulationRequested: _startSimulation,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSimulateTab() {
    return Column(
      children: [
        if (_simulationConfigs.isNotEmpty) _buildSimulationControls(),
        Expanded(
          child: _simulationConfigs.isEmpty
              ? _buildEmptySimulationState()
              : _buildSimulationView(),
        ),
      ],
    );
  }

  Widget _buildSimulationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentSimulationStep > 0 ? _previousStep : null,
            icon: const Icon(Icons.skip_previous),
          ),
          Expanded(
            child: Slider(
              value: _currentSimulationStep.toDouble(),
              min: 0,
              max: (_simulationConfigs.length - 1).toDouble(),
              divisions: _simulationConfigs.length - 1,
              onChanged: (value) {
                setState(() {
                  _currentSimulationStep = value.round();
                });
              },
            ),
          ),
          IconButton(
            onPressed: _currentSimulationStep < _simulationConfigs.length - 1 ? _nextStep : null,
            icon: const Icon(Icons.skip_next),
          ),
          Text('${_currentSimulationStep + 1}/${_simulationConfigs.length}'),
        ],
      ),
    );
  }

  Widget _buildEmptySimulationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No simulation running',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the Edit tab and click "Simulate" to start a simulation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        if (isMobile) {
          // Mobile: stacked layout
          return Column(
            children: [
              Expanded(
                child: PDACanvas(
                  pda: _pda,
                  onPDAChanged: _updatePDA,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                  isSimulating: true,
                  simulationConfig: _simulationConfigs[_currentSimulationStep],
                ),
              ),
              _buildSimulationInfo(),
            ],
          );
        } else {
          // Desktop: side by side
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: PDACanvas(
                  pda: _pda,
                  onPDAChanged: _updatePDA,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                  isSimulating: true,
                  simulationConfig: _simulationConfigs[_currentSimulationStep],
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildSimulationInfo(),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSimulationInfo() {
    final config = _simulationConfigs[_currentSimulationStep];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Step ${_currentSimulationStep + 1}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Current State',
            config.state,
            Icons.flag,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Unprocessed Input',
            config.unprocessedInput.isEmpty ? 'λ' : config.unprocessedInput,
            Icons.text_fields,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Stack Contents',
            config.stack.isEmpty ? 'Empty' : config.stack.toString(),
            Icons.storage,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Acceptance',
            config.isAccept ? 'ACCEPT' : 'REJECT',
            config.isAccept ? Icons.check_circle : Icons.cancel,
            color: config.isAccept ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _addState,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  void _updatePDA(PushdownAutomaton pda) {
    setState(() {
      _pda = pda;
    });
  }

  void _updateSelection(Set<String> selection) {
    setState(() {
      _selectedStates = selection;
    });
  }

  void _addState() {
    setState(() {
      _pda = _pda.addState();
    });
  }

  void _startSimulation(String input) {
    final result = PDAAlgorithms.simulatePDA(_pda, input);
    
    if (result.isSuccess) {
      setState(() {
        _simulationConfigs = result.data!;
        _currentSimulationStep = 0;
        _isSimulating = true;
      });
      
      // Switch to simulation tab
      _tabController.animateTo(1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation completed with ${_simulationConfigs.length} steps'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation error: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentSimulationStep > 0) {
      setState(() {
        _currentSimulationStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentSimulationStep < _simulationConfigs.length - 1) {
      setState(() {
        _currentSimulationStep++;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDA Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pushdown Automaton (PDA)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('A PDA is a finite automaton with a stack. It can recognize context-free languages.'),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Add states by tapping the + button'),
              Text('• Tap states to select them'),
              Text('• Drag states to move them'),
              Text('• Define input and stack alphabets'),
              Text('• Choose acceptance mode (final state or empty stack)'),
              Text('• Simulate with input strings'),
              Text('• Convert to Context-Free Grammar'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
