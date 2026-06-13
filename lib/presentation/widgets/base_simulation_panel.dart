//
//  base_simulation_panel.dart
//  JFlutter
//
//  Componentes compartilhados para painéis de simulação, incluindo shell,
//  cabeçalho, seção de entrada, botão de execução e estados de resultado.
//  Mantém a estrutura visual comum sem assumir a lógica específica de FA, PDA
//  ou TM.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

/// Card shell shared by the simulation side panels.
class SimulationPanelShell extends StatelessWidget {
  const SimulationPanelShell({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.focusTraversal = false,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool focusTraversal;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );

    if (!focusTraversal) {
      return card;
    }

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: card,
    );
  }
}

/// Header shared by simulation panels.
class SimulationPanelHeader extends StatelessWidget {
  const SimulationPanelHeader({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    if (icon == null) {
      return titleText;
    }

    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: titleText),
      ],
    );
  }
}

/// Shared decorated section for simulation inputs.
class SimulationInputSection extends StatelessWidget {
  const SimulationInputSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Text field styling shared by simulation panels.
class SimulationTextField extends StatelessWidget {
  const SimulationTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.onSubmitted,
    this.semanticsLabel,
    this.semanticsHint,
    this.excludeSemantics = false,
    this.isDense = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final VoidCallback? onSubmitted;
  final String? semanticsLabel;
  final String? semanticsHint;
  final bool excludeSemantics;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        isDense: isDense,
      ),
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      onSubmitted: (_) => onSubmitted?.call(),
    );

    final label = semanticsLabel ?? 'Simulation input: $labelText';
    final hint = semanticsHint ?? '$hintText. Double tap to edit.';

    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      enabled: true,
      excludeSemantics: excludeSemantics,
      child: field,
    );
  }
}

/// Shared run button for simulation panels.
class SimulationRunButton extends StatelessWidget {
  const SimulationRunButton({
    super.key,
    required this.isSimulating,
    required this.label,
    required this.onPressed,
    this.simulatingLabel = 'Simulating...',
    this.icon = Icons.play_arrow,
    this.iconSize,
    this.padding,
    this.semanticsLabel,
    this.semanticsHint,
    this.excludeSemantics = false,
  });

  final bool isSimulating;
  final String label;
  final VoidCallback onPressed;
  final String simulatingLabel;
  final IconData icon;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final String? semanticsLabel;
  final String? semanticsHint;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSimulating ? null : onPressed,
        icon: isSimulating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: iconSize),
        label: Text(isSimulating ? simulatingLabel : label),
        style:
            padding == null ? null : ElevatedButton.styleFrom(padding: padding),
      ),
    );

    return Semantics(
      label: semanticsLabel ?? 'Run simulation',
      hint: semanticsHint ??
          'Runs the machine using the currently entered input string.',
      value: isSimulating ? 'Simulating' : null,
      button: true,
      enabled: !isSimulating,
      excludeSemantics: excludeSemantics,
      child: button,
    );
  }
}

/// Shared title wrapper for simulation results.
class SimulationResultsSection extends StatelessWidget {
  const SimulationResultsSection({
    super.key,
    required this.title,
    required this.child,
    this.maxHeight,
  });

  final String title;
  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final content = maxHeight == null
        ? child
        : Container(
            constraints: BoxConstraints(maxHeight: maxHeight!),
            child: child,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

/// Shared empty-state placeholder for simulation results.
class SimulationEmptyResults extends StatelessWidget {
  const SimulationEmptyResults({
    super.key,
    this.icon = Icons.psychology,
    this.title = 'No simulation results yet',
    this.message = 'Enter an input string and click Simulate to see results',
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shared accepted/rejected status card for simulation results.
class SimulationStatusCard extends StatelessWidget {
  const SimulationStatusCard({
    super.key,
    required this.isAccepted,
    required this.message,
    this.children = const [],
  });

  final bool? isAccepted;
  final String message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = isAccepted == true;
    final color = isSuccess ? colorScheme.tertiary : colorScheme.error;
    final icon = isAccepted == null
        ? Icons.error
        : isSuccess
            ? Icons.check_circle
            : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...children,
          ],
        ],
      ),
    );
  }
}
