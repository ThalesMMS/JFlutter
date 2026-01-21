//
//  base_simulation_panel.dart
//  JFlutter
//
//  Classe base abstrata para painéis de simulação, fornecendo campos e métodos
//  compartilhados entre SimulationPanel e PDASimulationPanel, incluindo
//  controladores de entrada, gerenciamento de estado de simulação e integração
//  com o serviço de destaque para sincronização de canvas.
//  Centraliza lógica comum de ciclo de vida e limpeza de recursos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import '../../core/services/simulation_highlight_service.dart';

/// Abstract base class for simulation panels
///
/// Provides common fields and methods for simulation panels including:
/// - Input controller management
/// - Simulation state tracking
/// - Highlight service integration
/// - Resource cleanup
abstract class BaseSimulationPanelState<T extends StatefulWidget>
    extends State<T> {
  /// Controller for the input string text field
  final TextEditingController inputController = TextEditingController();

  /// Indicates whether a simulation is currently running
  bool isSimulating = false;

  /// Service for managing canvas highlighting during simulation
  SimulationHighlightService get highlightService;

  @override
  void dispose() {
    inputController.dispose();
    highlightService.clear();
    super.dispose();
  }

  /// Starts a simulation with the given input string
  ///
  /// Subclasses should override this to implement specific simulation logic
  void simulate();

  /// Clears the current simulation state and results
  ///
  /// Subclasses should override this to clear specific simulation data
  void clearSimulation() {
    setState(() {
      isSimulating = false;
    });
    highlightService.clear();
  }

  /// Builds the common input text field for entering test strings
  Widget buildInputField({
    required BuildContext context,
    String labelText = 'Input String',
    String hintText = 'Enter string to test',
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: inputController,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => onSubmit?.call() ?? simulate(),
    );
  }

  /// Builds the common simulate button
  Widget buildSimulateButton({
    required BuildContext context,
    String label = 'Simulate',
    String simulatingLabel = 'Simulating...',
    IconData icon = Icons.play_arrow,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSimulating ? null : (onPressed ?? simulate),
        icon: isSimulating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(isSimulating ? simulatingLabel : label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Builds a result card with accept/reject status
  Widget buildResultCard({
    required BuildContext context,
    required bool isAccepted,
    String acceptedLabel = 'Accepted',
    String rejectedLabel = 'Rejected',
    Widget? additionalInfo,
    String? errorMessage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAccepted ? colorScheme.tertiary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAccepted ? acceptedLabel : rejectedLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (additionalInfo != null) ...[
            const SizedBox(height: 8),
            additionalInfo,
          ],
          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Error: $errorMessage',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a state name for display, replacing empty states with ∅
  String formatState(String state) {
    return state.isEmpty ? '∅' : state;
  }

  /// Shows an error message in a SnackBar
  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
