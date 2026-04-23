part of 'help_page.dart';

class HelpSection {
  final String title;
  final IconData icon;
  final Widget content;

  const HelpSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );
}

Widget _buildComponentCard(String title, String description) {
  return _buildCard(title: title, description: description);
}

Widget _buildCard({
  required String title,
  String? description,
  Widget? leading,
  Widget? trailing,
  Widget? subtitle,
  Color? backgroundColor,
  bool expandable = false,
  Widget? expandedChild,
}) {
  if (expandable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: backgroundColor,
      child: ExpansionTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle ?? (description == null ? null : Text(description)),
        trailing: trailing,
        children: [
          if (expandedChild != null)
            expandedChild
          else if (description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description),
            ),
        ],
      ),
    );
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 8.0),
    color: backgroundColor,
    child: ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle ?? (description == null ? null : Text(description)),
      trailing: trailing,
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

// Help content widgets for each section

class _GettingStartedContent extends StatelessWidget {
  const _GettingStartedContent();

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
            'JFlutter is an interactive learning app for students and educators '
            'studying formal languages and automata theory. Build automata and '
            'grammars, run simulations, and explore core concepts in one place.',
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
          if (V1FeatureFlags.showPumpingLemma)
            _buildFeatureCard(
              'Pumping',
              Icons.games,
              'Pumping Lemma Game - Interactive learning tool',
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('Basic Operations'),
          const SizedBox(height: 16),
          _buildComponentCard(
            'Create',
            'Add new states, transitions, or rules',
          ),
          _buildComponentCard('Edit', 'Modify existing elements'),
          _buildComponentCard(
            'Simulate',
            'Test your automaton with input strings',
          ),
          _buildComponentCard(
            'Convert',
            'Transform between different representations',
          ),
          _buildComponentCard(
            'Save/Load',
            'Use the supported import and export formats for each workspace',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, String description) {
    return _buildCard(
      title: title,
      description: description,
      leading: Icon(icon),
    );
  }
}

class _FSAHelpContent extends StatelessWidget {
  const _FSAHelpContent();

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
          _buildStepCard(
            '1',
            'Add States',
            'Use the Add State toolbar action (circle icon) and tap the canvas to '
                'place new states.',
          ),
          _buildStepCard(
            '2',
            'Configure State Properties',
            'Double-tap a state to open its editor. Toggle the Initial and Final '
                'switches, adjust the label, and confirm to apply.',
          ),
          _buildStepCard(
            '3',
            'Create Transitions',
            'Select the Add Transition tool, tap the source state, tap the target '
                'state, and provide the transition label in the dialog.',
          ),
          _buildStepCard(
            '4',
            'Refine Labels',
            'Use the transition dialog to enter one or more symbols (comma '
                'separated). Repeat the source/target selection to add more arcs.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Simulation'),
          const SizedBox(height: 16),
          const Text(
            'To test your FSA:\n'
            '1. Enter an input string in the simulation panel and tap "Simulate".\n'
            '2. Enable Step-by-Step Mode with the toggle to load the execution '
            'timeline.\n'
            '3. Use the playback controls (play/pause, previous, next, reset) to '
            'navigate through the highlighted steps.\n'
            '4. Check the result banner to confirm acceptance or rejection.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Algorithms'),
          const SizedBox(height: 16),
          _buildAlgorithmCard(
            'Regex to NFA',
            'Provide a regular expression and send it to the Regex → NFA converter.'
                ' Use the text field and arrow button to submit.',
          ),
          _buildAlgorithmCard(
            'NFA to DFA',
            'Run the dedicated button to determinize the active automaton.',
          ),
          _buildAlgorithmCard(
            'Remove λ-transitions',
            'Eliminate epsilon transitions before further conversions or '
                'minimization.',
          ),
          _buildAlgorithmCard(
            'Minimize DFA',
            'Press "Minimize DFA" to compute the reduced automaton.',
          ),
          _buildAlgorithmCard(
            'Complete & Complement',
            'Use "Complete DFA" to add the sink state and "Complement DFA" to flip '
                'acceptance.',
          ),
          _buildAlgorithmCard(
            'Product Operations',
            'Union, Intersection, and Difference open a file picker for the second '
                'DFA before computing the combined machine.',
          ),
          _buildAlgorithmCard(
            'Compare Equivalence',
            'Trigger "Compare Equivalence" to load another DFA from file and check '
                'language equality.',
          ),
          _buildAlgorithmCard(
            'Conversions & Layout',
            'Buttons for FA → Regex, FSA → Grammar, Prefix/Suffix closure, and Auto '
                'Layout are available in the same panel.',
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmCard(String title, String description) {
    return _buildCard(
      title: title,
      description: description,
      trailing: const Icon(Icons.play_arrow),
    );
  }
}

class _GrammarHelpContent extends StatelessWidget {
  const _GrammarHelpContent();

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

  Widget _buildParseCard(String title, String description) {
    return _buildCard(
      title: title,
      description: description,
      trailing: const Icon(Icons.play_arrow),
    );
  }
}

class _PDAHelpContent extends StatelessWidget {
  const _PDAHelpContent();

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
}

class _TMHelpContent extends StatelessWidget {
  const _TMHelpContent();

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
}

class _RegexHelpContent extends StatelessWidget {
  const _RegexHelpContent();

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

  Widget _buildSyntaxCard(String pattern, String description) {
    return _buildCard(
      title: description,
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
    );
  }

  Widget _buildPatternCard(String name, String pattern) {
    return _buildCard(
      title: name,
      subtitle: Text(
        pattern,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

class _PumpingLemmaHelpContent extends StatelessWidget {
  const _PumpingLemmaHelpContent();

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

  Widget _buildTipCard(String title, String description) {
    return _buildCard(
      title: title,
      description: description,
      leading: const Icon(Icons.lightbulb_outline),
    );
  }
}

class _FileOperationsHelpContent extends StatelessWidget {
  const _FileOperationsHelpContent();

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
            'JFlutter supports the following file formats for each workspace.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Workspace Support'),
          const SizedBox(height: 16),
          _buildFormatCard(
            'FSA',
            'JFLAP XML import/export, JSON import/export, SVG export, and PNG export on native platforms',
          ),
          _buildFormatCard(
            'Grammar',
            'JFLAP grammar import/export and SVG export',
          ),
          _buildFormatCard(
            'PDA',
            'SVG export only',
          ),
          _buildFormatCard(
            'Turing Machine',
            'SVG export only',
          ),
          _buildFormatCard(
            'Regex',
            'No file import/export supported',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Current Notes'),
          const SizedBox(height: 16),
          const Text(
            '1. JFLAP import/export is limited to the FSA and Grammar workspaces.\n'
            '2. PDA and Turing Machine workspaces support SVG export only.\n'
            '3. PNG export is available on native builds and is not available on the web.\n'
            '4. Regex workflows operate directly on input strings and converted automata rather than saved regex files.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Import/Export'),
          const SizedBox(height: 16),
          _buildComponentCard(
            'Import from JFLAP',
            'Load validated JFLAP files in the supported workspaces',
          ),
          _buildComponentCard(
            'Export for Sharing',
            'Use SVG or other supported release formats for the current module',
          ),
          _buildComponentCard(
            'Backup Work',
            'Create backups only with the formats supported by that workspace',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(String title, String description) {
    return _buildCard(title: title, description: description);
  }
}

class _TroubleshootingContent extends StatelessWidget {
  const _TroubleshootingContent();

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

  Widget _buildIssueCard(String title, String solution) {
    return _buildCard(
      title: title,
      expandable: true,
      expandedChild: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(solution),
      ),
    );
  }
}
