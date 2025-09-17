#!/bin/bash

# JFlutter Compilation Fix Script
# This script helps fix the remaining compilation issues

echo "🔧 JFlutter Compilation Fix Script"
echo "=================================="

# Create missing files
echo "📁 Creating missing files..."
touch lib/core/models/parse_action.dart

# Add basic content to parse_action.dart
cat > lib/core/models/parse_action.dart << 'EOF'
/// Represents a parse action in grammar parsing
class ParseAction {
  final String type;
  final String symbol;
  final int state;
  
  const ParseAction({
    required this.type,
    required this.symbol,
    required this.state,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'symbol': symbol,
    'state': state,
  };
  
  factory ParseAction.fromJson(Map<String, dynamic> json) => ParseAction(
    type: json['type'] as String,
    symbol: json['symbol'] as String,
    state: json['state'] as int,
  );
}
EOF

echo "✅ Created parse_action.dart"

# Check for missing ResultFactory imports
echo "🔍 Checking for missing ResultFactory imports..."

files_with_missing_imports=(
  "lib/core/algorithms/mealy_machine_simulator.dart"
  "lib/core/algorithms/pda_simulator.dart" 
  "lib/core/algorithms/tm_simulator.dart"
  "lib/core/algorithms/pumping_lemma_game.dart"
  "lib/core/algorithms/pumping_lemma_prover.dart"
  "lib/core/algorithms/l_system_generator.dart"
)

for file in "${files_with_missing_imports[@]}"; do
  if [ -f "$file" ]; then
    if ! grep -q "import '../result.dart';" "$file"; then
      echo "⚠️  Missing ResultFactory import in $file"
      # Add import after other imports
      sed -i '' '/^import /a\
import '\''../result.dart'\'';
' "$file"
      echo "✅ Added ResultFactory import to $file"
    fi
  fi
done

echo ""
echo "🎯 Next steps:"
echo "1. Fix export conflicts in lib/core/algorithms.dart"
echo "2. Resolve Automaton vs AutomatonEntity type conflicts"
echo "3. Fix remaining constructor issues"
echo "4. Run: flutter run -d 89B37587-4BC2-4560-ACEA-8B65C649FFC8"
echo ""
echo "📚 See COMPILATION_STATUS.md for detailed progress"
echo "🚨 See CRITICAL_ISSUES.md for immediate blockers"
