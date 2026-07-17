import 'package:flutter/material.dart';

import 'common/algorithm_button.dart';
import 'common/algorithm_button_config.dart';

class AlgorithmButtonList extends StatelessWidget {
  const AlgorithmButtonList({
    super.key,
    required this.configs,
    this.spacing = 12,
  });

  final List<AlgorithmButtonConfig> configs;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < configs.length; index++) ...[
          AlgorithmButton.fromConfig(configs[index]),
          if (index < configs.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}
