//
//  help_page.dart
//  JFlutter
//
//  Reúne a documentação interativa com seções temáticas controladas por
//  PageView e filtros, oferecendo tutoriais guiados para cada módulo de
//  autômatos, gramáticas e ferramentas presentes no aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Help page with interactive documentation and tutorials
/// Based on JFLAP's HelpAction.java and documentation structure
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<HelpSection> _helpSections = [
    HelpSection(
      title: 'Getting Started',
      icon: Icons.play_circle_outline,
      content: _GettingStartedContent(),
    ),
    HelpSection(
      title: 'FSA',
      icon: Icons.account_tree,
      content: _FSAHelpContent(),
    ),
    HelpSection(
      title: 'Grammar',
      icon: Icons.text_fields,
      content: _GrammarHelpContent(),
    ),
    HelpSection(title: 'PDA', icon: Icons.storage, content: _PDAHelpContent()),
    HelpSection(
      title: 'Turing Machine',
      icon: Icons.settings,
      content: _TMHelpContent(),
    ),
    HelpSection(
      title: 'Regular Expression',
      icon: Icons.pattern,
      content: _RegexHelpContent(),
    ),
    HelpSection(
      title: 'Pumping Lemma',
      icon: Icons.games,
      content: _PumpingLemmaHelpContent(),
    ),
    HelpSection(
      title: 'File Operations',
      icon: Icons.folder_open,
      content: _FileOperationsHelpContent(),
    ),
    HelpSection(
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      content: _TroubleshootingContent(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Documentation'),
        actions: [
          IconButton(
            onPressed: _showQuickStart,
            icon: const Icon(Icons.rocket_launch),
            tooltip: 'Quick Start Guide',
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _helpSections.length,
            itemBuilder: (context, index) {
              final section = _helpSections[index];
              final isSelected = index == _selectedIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(section.title),
                  selected: isSelected,
                  onSelected: (_) => _onSectionSelected(index),
                  avatar: Icon(section.icon, size: 16),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _helpSections.map((section) => section.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: ListView.builder(
            itemCount: _helpSections.length,
            itemBuilder: (context, index) {
              final section = _helpSections[index];
              final isSelected = index == _selectedIndex;

              return ListTile(
                leading: Icon(section.icon),
                title: Text(section.title),
                selected: isSelected,
                onTap: () => _onSectionSelected(index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _helpSections.map((section) => section.content).toList(),
          ),
        ),
      ],
    );
  }

  void _showQuickStart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Start Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to JFlutter! Here\'s how to get started:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Use the bottom navigation bar to choose a module'),
              Text('2. Create or load an automaton/grammar'),
              Text(
                  '3. Use the editor to modify your structure (double-tap a state for quick actions)'),
              Text('4. Run simulations to test your work'),
              Text('5. Use algorithms to transform structures'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Use the bottom navigation to switch between modules quickly'),
              Text('• Double-tap a state to open its quick action menu'),
              Text('• Pinch to zoom on canvas'),
              Text('• Tap the Quick Start icon in the app bar whenever you need a refresher'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class HelpSection {
  final String title;
  final IconData icon;
  final Widget content;

  HelpSection({required this.title, required this.icon, required this.content});
}

// Help content widgets for each section

class _GettingStartedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Welcome to JFlutter'),
          const SizedBox(height: 16),
          const Text(
            'JFlutter is a mobile application for learning formal language theory. '
            'It provides interactive tools for working with automata, grammars, and other '
            'formal language concepts.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Navigation'),
          const SizedBox(height: 16),
          _buildFeatureCard(
            'FSA',
            Icons.account_tree,
            'Finite State Automata - Create and simulate finite state machines',
          ),
          _buildFeatureCard(
            'Grammar',
            Icons.text_fields,
            'Context-Free Grammars - Work with production rules and parsing',
          ),
          _buildFeatureCard(
            'PDA',
            Icons.storage,
            'Pushdown Automata - Explore stack-based computation',
          ),
          _buildFeatureCard(
            'TM',
            Icons.settings,
            'Turing Machines - Learn about computational models',
          ),
          _buildFeatureCard(
            'Regex',
            Icons.pattern,
            'Regular Expressions - Pattern matching and conversion',
          ),
          _buildFeatureCard(
            'Pumping',
            Icons.games,
            'Pumping Lemma Game - Interactive learning tool',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Basic Operations'),
          const SizedBox(height: 16),
          _buildOperationCard(
            'Create',
            'Add new states, transitions, or rules',
          ),
          _buildOperationCard('Edit', 'Modify existing elements'),
          _buildOperationCard(
            'Simulate',
            'Test your automaton with input strings',
          ),
          _buildOperationCard(
            'Convert',
            'Transform between different representations',
          ),
          _buildOperationCard('Save/Load', 'Persist your work in JFLAP format'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildOperationCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}

class _FSAHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Finite State Automata'),
          const SizedBox(height: 16),
          const Text(
            'Finite State Automata (FSA) are computational models that can be in one of '
            'a finite number of states at any given time. They are used to recognize '
            'regular languages.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Creating an FSA'),
          const SizedBox(height: 16),
          _buildStepCard('1', 'Add States', 'Tap the canvas to add states'),
          _buildStepCard(
            '2',
            'Set Initial State',
            'Double-tap a state to make it initial',
          ),
          _buildStepCard(
            '3',
            'Set Final States',
            'Long-press states to mark as final',
          ),
          _buildStepCard(
            '4',
            'Add Transitions',
            'Drag between states to create transitions',
          ),
          _buildStepCard(
            '5',
            'Label Transitions',
            'Tap transitions to add input symbols',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Simulation'),
          const SizedBox(height: 16),
          const Text(
            'To test your FSA:\n'
            '1. Enter an input string in the simulation panel\n'
            '2. Tap "Step" to see each transition\n'
            '3. Tap "Run" to see the complete simulation\n'
            '4. Check if the string is accepted or rejected',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Algorithms'),
          const SizedBox(height: 16),
          _buildAlgorithmCard(
            'NFA to DFA',
            'Convert non-deterministic to deterministic',
          ),
          _buildAlgorithmCard(
            'DFA Minimization',
            'Reduce the number of states',
          ),
          _buildAlgorithmCard(
            'Equality Test',
            'Check if two FSAs are equivalent',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(child: Text(number)),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildAlgorithmCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class _GrammarHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Context-Free Grammars'),
          const SizedBox(height: 16),
          const Text(
            'Context-Free Grammars (CFG) are formal grammars where production rules '
            'have a single nonterminal on the left-hand side. They are used to describe '
            'context-free languages.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Grammar Components'),
          const SizedBox(height: 16),
          _buildComponentCard(
            'Variables',
            'Nonterminal symbols (usually uppercase)',
          ),
          _buildComponentCard(
            'Terminals',
            'Terminal symbols (usually lowercase)',
          ),
          _buildComponentCard('Start Symbol', 'The initial nonterminal'),
          _buildComponentCard('Productions', 'Rules of the form A → α'),
          const SizedBox(height: 24),
          _buildSectionTitle('Creating Productions'),
          const SizedBox(height: 16),
          const Text(
            'To add a production rule:\n'
            '1. Enter the left-hand side (nonterminal)\n'
            '2. Enter the right-hand side (string of terminals and nonterminals)\n'
            '3. Tap "Add" to include the rule\n'
            '4. Use λ or ε for empty string',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Parsing'),
          const SizedBox(height: 16),
          _buildParseCard('LL Parsing', 'Left-to-right, Leftmost derivation'),
          _buildParseCard('LR Parsing', 'Left-to-right, Rightmost derivation'),
          _buildParseCard('CYK Algorithm', 'Cocke-Younger-Kasami algorithm'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildComponentCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }

  Widget _buildParseCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class _PDAHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pushdown Automata'),
          const SizedBox(height: 16),
          const Text(
            'Pushdown Automata (PDA) are finite state machines with a stack. '
            'They can recognize context-free languages and are more powerful than FSAs.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('PDA Components'),
          const SizedBox(height: 16),
          _buildComponentCard('States', 'Finite set of states'),
          _buildComponentCard('Stack', 'LIFO data structure'),
          _buildComponentCard(
            'Transitions',
            'Read input, pop/push stack, change state',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Transition Format'),
          const SizedBox(height: 16),
          const Text(
            'Transitions are of the form:\n'
            '(current_state, input_symbol, stack_top) → (new_state, stack_operation)\n\n'
            'Stack operations:\n'
            '• Pop: Remove top symbol\n'
            '• Push: Add symbol to top\n'
            '• Replace: Pop and push in one operation',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Simulation'),
          const SizedBox(height: 16),
          const Text(
            'During simulation:\n'
            '1. Read input symbol\n'
            '2. Check stack top\n'
            '3. Apply transition\n'
            '4. Update state and stack\n'
            '5. Continue until input is consumed',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildComponentCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}

class _TMHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Turing Machines'),
          const SizedBox(height: 16),
          const Text(
            'Turing Machines (TM) are theoretical computational devices with an infinite '
            'tape and a read/write head. They can recognize recursively enumerable languages.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('TM Components'),
          const SizedBox(height: 16),
          _buildComponentCard('Tape', 'Infinite sequence of cells'),
          _buildComponentCard('Head', 'Read/write head that moves left/right'),
          _buildComponentCard('States', 'Finite set of control states'),
          _buildComponentCard(
            'Transitions',
            'Read symbol, write symbol, move head, change state',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Transition Format'),
          const SizedBox(height: 16),
          const Text(
            'Transitions are of the form:\n'
            '(current_state, read_symbol) → (new_state, write_symbol, direction)\n\n'
            'Directions:\n'
            '• L: Move left\n'
            '• R: Move right\n'
            '• S: Stay (if enabled in settings)',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Acceptance'),
          const SizedBox(height: 16),
          const Text(
            'A TM accepts a string if:\n'
            '• It reaches a final state (default)\n'
            '• It halts (if enabled in settings)\n\n'
            'Configure acceptance mode in Settings.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildComponentCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}

class _RegexHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Regular Expressions'),
          const SizedBox(height: 16),
          const Text(
            'Regular Expressions (regex) are patterns used to match character combinations in strings. '
            'They are fundamental to formal language theory and are equivalent to finite automata.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Basic Syntax'),
          const SizedBox(height: 16),
          _buildSyntaxCard('a', 'Matches the literal character "a"'),
          _buildSyntaxCard('a*', 'Zero or more occurrences of "a"'),
          _buildSyntaxCard('a+', 'One or more occurrences of "a"'),
          _buildSyntaxCard('a?', 'Zero or one occurrence of "a"'),
          _buildSyntaxCard('a|b', 'Either "a" or "b"'),
          _buildSyntaxCard('(ab)*', 'Zero or more occurrences of "ab"'),
          _buildSyntaxCard('[abc]', 'Any character from the set {a, b, c}'),
          _buildSyntaxCard('[a-z]', 'Any lowercase letter'),
          _buildSyntaxCard('.', 'Any single character'),
          const SizedBox(height: 24),
          _buildSectionTitle('Common Patterns'),
          const SizedBox(height: 16),
          _buildPatternCard(
            'Email',
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          ),
          _buildPatternCard('Phone Number', r'^\+?[\d\s\-\(\)]+$'),
          _buildPatternCard('Integer', r'^-?\d+$'),
          _buildPatternCard('Decimal', r'^-?\d+\.?\d*$'),
          _buildPatternCard('Identifier', r'^[a-zA-Z_][a-zA-Z0-9_]*$'),
          const SizedBox(height: 24),
          _buildSectionTitle('Conversion to Automata'),
          const SizedBox(height: 16),
          const Text(
            'Regular expressions can be converted to equivalent finite automata:\n\n'
            '1. **Regex to NFA**: Thompson\'s construction algorithm\n'
            '2. **NFA to DFA**: Subset construction algorithm\n'
            '3. **DFA Minimization**: Hopcroft\'s algorithm\n'
            '4. **FA to Regex**: State elimination method\n\n'
            'These conversions preserve the language recognized by the expression.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Testing and Validation'),
          const SizedBox(height: 16),
          _buildStepCard(
            '1',
            'Enter Regex',
            'Type your regular expression in the input field',
          ),
          _buildStepCard('2', 'Validate', 'Check if the syntax is correct'),
          _buildStepCard(
            '3',
            'Test String',
            'Enter a string to test against the regex',
          ),
          _buildStepCard(
            '4',
            'View Results',
            'See if the string matches the pattern',
          ),
          _buildStepCard(
            '5',
            'Convert',
            'Convert the regex to an equivalent automaton',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSyntaxCard(String pattern, String description) {
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

  Widget _buildPatternCard(String name, String pattern) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          pattern,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(child: Text(number)),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}

class _PumpingLemmaHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pumping Lemma Game'),
          const SizedBox(height: 16),
          const Text(
            'The Pumping Lemma Game is an interactive way to learn about the pumping '
            'lemma for regular languages. It helps you understand why certain languages '
            'are not regular.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('How to Play'),
          const SizedBox(height: 16),
          _buildStepCard(
            '1',
            'Choose Language',
            'Select a language to analyze',
          ),
          _buildStepCard(
            '2',
            'Find Pumping Length',
            'Determine the pumping length p',
          ),
          _buildStepCard('3', 'Choose String', 'Pick a string longer than p'),
          _buildStepCard(
            '4',
            'Decompose String',
            'Split into xyz where |xy| ≤ p',
          ),
          _buildStepCard(
            '5',
            'Pump String',
            'Show that xyⁿz is not in the language',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Pumping Lemma Statement'),
          const SizedBox(height: 16),
          const Text(
            'For any regular language L, there exists a pumping length p such that '
            'for any string s in L with |s| ≥ p, s can be written as s = xyz where:\n\n'
            '1. |xy| ≤ p\n'
            '2. |y| > 0\n'
            '3. xyⁿz ∈ L for all n ≥ 0',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Tips'),
          const SizedBox(height: 16),
          _buildTipCard('Start Simple', 'Begin with basic languages like aⁿbⁿ'),
          _buildTipCard(
            'Use Contradiction',
            'Show pumping leads to strings not in L',
          ),
          _buildTipCard(
            'Consider All Cases',
            'Check different ways to split the string',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(child: Text(number)),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildTipCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}

class _FileOperationsHelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('File Operations'),
          const SizedBox(height: 16),
          const Text(
            'JFlutter supports saving and loading automata, grammars, and other structures '
            'in JFLAP format for compatibility with the original JFLAP software.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Supported Formats'),
          const SizedBox(height: 16),
          _buildFormatCard('JFLAP XML', 'Native JFLAP format (.jff)'),
          _buildFormatCard('SVG Export', 'Vector graphics for presentations'),
          _buildFormatCard('Text Export', 'Plain text representation'),
          const SizedBox(height: 24),
          _buildSectionTitle('Saving Files'),
          const SizedBox(height: 16),
          const Text(
            'To save your work:\n'
            '1. Tap the save button in the file operations panel\n'
            '2. Choose a location and filename\n'
            '3. Select the format (JFLAP XML recommended)\n'
            '4. Confirm to save',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Loading Files'),
          const SizedBox(height: 16),
          const Text(
            'To load existing files:\n'
            '1. Tap the load button in the file operations panel\n'
            '2. Browse to your file location\n'
            '3. Select a .jff file\n'
            '4. The structure will be loaded into the editor',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Import/Export'),
          const SizedBox(height: 16),
          _buildOperationCard(
            'Import from JFLAP',
            'Load files created in desktop JFLAP',
          ),
          _buildOperationCard(
            'Export for Sharing',
            'Save in formats others can use',
          ),
          _buildOperationCard(
            'Backup Work',
            'Create copies of your structures',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFormatCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }

  Widget _buildOperationCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}

class _TroubleshootingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Troubleshooting'),
          const SizedBox(height: 16),
          const Text('Common issues and solutions for using JFlutter.'),
          const SizedBox(height: 24),
          _buildSectionTitle('Performance Issues'),
          const SizedBox(height: 16),
          _buildIssueCard(
            'App is slow with large automata',
            'Try reducing the number of states or simplifying the structure. '
                'Large automata with many transitions can impact performance.',
          ),
          _buildIssueCard(
            'Simulation takes too long',
            'Check for infinite loops in your automaton. Some inputs may cause '
                'the simulation to run indefinitely.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('File Issues'),
          const SizedBox(height: 16),
          _buildIssueCard(
            'Cannot load JFLAP file',
            'Ensure the file is a valid JFLAP XML format (.jff). '
                'Corrupted files may not load properly.',
          ),
          _buildIssueCard(
            'Save operation fails',
            'Check that you have sufficient storage space and write permissions '
                'to the selected location.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('UI Issues'),
          const SizedBox(height: 16),
          _buildIssueCard(
            'Elements are too small to tap',
            'Use pinch-to-zoom to enlarge the canvas, or adjust the zoom level '
                'in settings.',
          ),
          _buildIssueCard(
            'Canvas is not responding',
            'Try refreshing the page or restarting the app. '
                'Some touch gestures may conflict.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Getting Help'),
          const SizedBox(height: 16),
          const Text(
            'If you continue to experience issues:\n\n'
            '1. Check this help section for your specific problem\n'
            '2. Try restarting the application\n'
            '3. Clear app data and restart (will reset settings)\n'
            '4. Check for app updates\n'
            '5. Report bugs with detailed descriptions',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIssueCard(String title, String solution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(padding: const EdgeInsets.all(16.0), child: Text(solution)),
        ],
      ),
    );
  }
}
