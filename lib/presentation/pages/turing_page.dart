import 'package:flutter/material.dart';
import '../../core/turing.dart';
import '../../core/turing_algorithms.dart';
import '../widgets/turing_canvas.dart';
import '../widgets/turing_controls.dart';

/// Turing Machine Page - Main interface for Turing Machines
/// Optimized for mobile devices with responsive layout
class TuringPage extends StatefulWidget {
  const TuringPage({super.key});

  @override
  State<TuringPage> createState() => _TuringPageState();
}

class _TuringPageState extends State<TuringPage> with TickerProviderStateMixin {
  late TuringMachine _tm;
  Set<String> _selectedStates = {};
  bool _isSimulating = false;
  List<TMConfiguration> _simulationConfigs = [];
  int _currentSimulationStep = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tm = TuringMachine.empty();
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
        title: const Text('Turing Machine'),
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
                child: TuringCanvas(
                  tm: _tm,
                  onTMChanged: _updateTM,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: TuringControls(
                    tm: _tm,
                    onTMChanged: _updateTM,
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
                child: TuringCanvas(
                  tm: _tm,
                  onTMChanged: _updateTM,
                  selectedStates: _selectedStates,
                  onSelectionChanged: _updateSelection,
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: TuringControls(
                    tm: _tm,
                    onTMChanged: _updateTM,
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
                child: TuringCanvas(
                  tm: _tm,
                  onTMChanged: _updateTM,
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
                child: TuringCanvas(
                  tm: _tm,
                  onTMChanged: _updateTM,
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
            'Acceptance',
            config.isAccept ? 'ACCEPT' : 'REJECT',
            config.isAccept ? Icons.check_circle : Icons.cancel,
            color: config.isAccept ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Tape Contents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: config.tapes.length,
              itemBuilder: (context, index) {
                final tape = config.tapes[index];
                return _buildTapeInfo(index, tape);
              },
            ),
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

  Widget _buildTapeInfo(int index, Tape tape) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Tape ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contents: ${tape.contents}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Head Position: ${tape.tapeHead}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Output: ${tape.output}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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

  void _updateTM(TuringMachine tm) {
    setState(() {
      _tm = tm;
    });
  }

  void _updateSelection(Set<String> selection) {
    setState(() {
      _selectedStates = selection;
    });
  }

  void _addState() {
    setState(() {
      _tm = _tm.addState();
    });
  }

  void _startSimulation(String input) {
    final result = TuringAlgorithms.simulateTM(_tm, input);
    
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
        title: const Text('Turing Machine Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Turing Machine',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('A Turing Machine is a theoretical computing device that can simulate any algorithm.'),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Add states by tapping the + button'),
              Text('• Tap states to select them'),
              Text('• Drag states to move them'),
              Text('• Support for multiple tapes (1-5)'),
              Text('• Define tape alphabet'),
              Text('• Choose acceptance mode (final state or halting)'),
              Text('• Simulate with input strings'),
              Text('• Convert to Context-Sensitive Grammar'),
              SizedBox(height: 16),
              Text(
                'Transitions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Format: read_symbol ; write_symbol , direction'),
              Text('Directions: L (left), R (right), S (stay)'),
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
