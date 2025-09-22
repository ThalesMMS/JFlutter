import 'package:flutter/material.dart';

class HelpSectionTitle extends StatelessWidget {
  final String text;

  const HelpSectionTitle(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class HelpInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget? leading;
  final Widget? trailing;

  const HelpInfoCard({
    super.key,
    required this.title,
    required this.description,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(description),
        trailing: trailing,
      ),
    );
  }
}

class HelpFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const HelpFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
      leading: Icon(icon),
    );
  }
}

class HelpOperationCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpOperationCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
    );
  }
}

class HelpStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;

  const HelpStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
      leading: CircleAvatar(
        child: Text(stepNumber),
      ),
    );
  }
}

class HelpAlgorithmCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpAlgorithmCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
      trailing: const Icon(Icons.play_arrow),
    );
  }
}

class HelpComponentCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpComponentCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
    );
  }
}

class HelpParseCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpParseCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
      trailing: const Icon(Icons.play_arrow),
    );
  }
}

class HelpTipCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpTipCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
      leading: const Icon(Icons.lightbulb_outline),
    );
  }
}

class HelpFormatCard extends StatelessWidget {
  final String title;
  final String description;

  const HelpFormatCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return HelpInfoCard(
      title: title,
      description: description,
    );
  }
}

class HelpSyntaxCard extends StatelessWidget {
  final String pattern;
  final String description;

  const HelpSyntaxCard({
    super.key,
    required this.pattern,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pattern,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        title: Text(description),
      ),
    );
  }
}

class HelpPatternCard extends StatelessWidget {
  final String name;
  final String pattern;

  const HelpPatternCard({
    super.key,
    required this.name,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          pattern,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class HelpIssueCard extends StatelessWidget {
  final String title;
  final String solution;

  const HelpIssueCard({
    super.key,
    required this.title,
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(solution),
          ),
        ],
      ),
    );
  }
}
