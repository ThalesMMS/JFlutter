import 'package:flutter/material.dart';
import '../../core/services/diagnostics_service.dart';

/// Panel for displaying automaton diagnostics and suggestions
class DiagnosticsPanel extends StatelessWidget {
  final List<DiagnosticMessage> diagnostics;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const DiagnosticsPanel({
    super.key,
    required this.diagnostics,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.analytics, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Diagnostics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: isLoading ? null : onRefresh,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh diagnostics',
                  ),
              ],
            ),
          ),
          if (diagnostics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No issues found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diagnostics.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final diagnostic = diagnostics[index];
                return _DiagnosticTile(diagnostic: diagnostic);
              },
            ),
        ],
      ),
    );
  }
}

/// Individual diagnostic message tile
class _DiagnosticTile extends StatelessWidget {
  final DiagnosticMessage diagnostic;

  const _DiagnosticTile({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: _buildSeverityIcon(),
      title: Text(
        diagnostic.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: _getSeverityColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        diagnostic.message,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        if (diagnostic.suggestion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSuggestionBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSuggestionBorderColor(),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: _getSuggestionIconColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diagnostic.suggestion!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getSuggestionTextColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSeverityIcon() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Icon(Icons.error, color: Colors.red.shade600, size: 20);
      case DiagnosticSeverity.warning:
        return Icon(Icons.warning, color: Colors.orange.shade600, size: 20);
      case DiagnosticSeverity.info:
        return Icon(Icons.info, color: Colors.blue.shade600, size: 20);
    }
  }

  Color _getSeverityColor() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Colors.red.shade700;
      case DiagnosticSeverity.warning:
        return Colors.orange.shade700;
      case DiagnosticSeverity.info:
        return Colors.blue.shade700;
    }
  }

  Color _getSuggestionBackgroundColor() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Colors.red.shade50;
      case DiagnosticSeverity.warning:
        return Colors.orange.shade50;
      case DiagnosticSeverity.info:
        return Colors.blue.shade50;
    }
  }

  Color _getSuggestionBorderColor() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Colors.red.shade200;
      case DiagnosticSeverity.warning:
        return Colors.orange.shade200;
      case DiagnosticSeverity.info:
        return Colors.blue.shade200;
    }
  }

  Color _getSuggestionIconColor() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Colors.red.shade600;
      case DiagnosticSeverity.warning:
        return Colors.orange.shade600;
      case DiagnosticSeverity.info:
        return Colors.blue.shade600;
    }
  }

  Color _getSuggestionTextColor() {
    switch (diagnostic.severity) {
      case DiagnosticSeverity.error:
        return Colors.red.shade800;
      case DiagnosticSeverity.warning:
        return Colors.orange.shade800;
      case DiagnosticSeverity.info:
        return Colors.blue.shade800;
    }
  }
}

/// Compact diagnostics summary widget
class DiagnosticsSummary extends StatelessWidget {
  final List<DiagnosticMessage> diagnostics;

  const DiagnosticsSummary({super.key, required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return const SizedBox.shrink();
    }

    final errorCount = diagnostics
        .where((d) => d.severity == DiagnosticSeverity.error)
        .length;
    final warningCount = diagnostics
        .where((d) => d.severity == DiagnosticSeverity.warning)
        .length;
    final infoCount = diagnostics
        .where((d) => d.severity == DiagnosticSeverity.info)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getSummaryColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSummaryBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSummaryIcon(), size: 16, color: _getSummaryIconColor()),
          const SizedBox(width: 8),
          if (errorCount > 0) ...[
            _buildCountBadge(context, errorCount, Colors.red),
            const SizedBox(width: 4),
          ],
          if (warningCount > 0) ...[
            _buildCountBadge(context, warningCount, Colors.orange),
            const SizedBox(width: 4),
          ],
          if (infoCount > 0) ...[
            _buildCountBadge(context, infoCount, Colors.blue),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSummaryColor() {
    if (diagnostics.any((d) => d.severity == DiagnosticSeverity.error)) {
      return Colors.red.shade50;
    } else if (diagnostics.any(
      (d) => d.severity == DiagnosticSeverity.warning,
    )) {
      return Colors.orange.shade50;
    } else {
      return Colors.blue.shade50;
    }
  }

  Color _getSummaryBorderColor() {
    if (diagnostics.any((d) => d.severity == DiagnosticSeverity.error)) {
      return Colors.red.shade200;
    } else if (diagnostics.any(
      (d) => d.severity == DiagnosticSeverity.warning,
    )) {
      return Colors.orange.shade200;
    } else {
      return Colors.blue.shade200;
    }
  }

  IconData _getSummaryIcon() {
    if (diagnostics.any((d) => d.severity == DiagnosticSeverity.error)) {
      return Icons.error;
    } else if (diagnostics.any(
      (d) => d.severity == DiagnosticSeverity.warning,
    )) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  Color _getSummaryIconColor() {
    if (diagnostics.any((d) => d.severity == DiagnosticSeverity.error)) {
      return Colors.red.shade600;
    } else if (diagnostics.any(
      (d) => d.severity == DiagnosticSeverity.warning,
    )) {
      return Colors.orange.shade600;
    } else {
      return Colors.blue.shade600;
    }
  }
}
