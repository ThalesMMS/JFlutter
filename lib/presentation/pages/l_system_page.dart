import 'package:flutter/material.dart';

/// Page for working with L-Systems
class LSystemPage extends StatelessWidget {
  const LSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'L-Systems Page',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lindenmayer Systems tools coming soon!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
