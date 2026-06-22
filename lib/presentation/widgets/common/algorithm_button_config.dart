import 'package:flutter/material.dart';

/// Declarative configuration for a shared algorithm action button.
class AlgorithmButtonConfig {
  const AlgorithmButtonConfig({
    required this.title,
    required this.description,
    required this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.isExecuting = false,
    this.isDestructive = false,
    this.isSelected = false,
    this.executionProgress,
    this.executionStatus,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isExecuting;
  final bool isDestructive;
  final bool isSelected;
  final double? executionProgress;
  final String? executionStatus;

  VoidCallback? get effectiveOnPressed {
    return isEnabled ? onPressed : null;
  }
}
