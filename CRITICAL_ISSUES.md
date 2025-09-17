# Critical Compilation Issues - Quick Reference

## 🚨 IMMEDIATE BLOCKERS

### 1. Missing Files
```bash
# Create these files immediately:
touch lib/core/models/parse_action.dart
```

### 2. Export Conflicts (lib/core/algorithms.dart)
```dart
// Problem: Multiple files export same class names
export 'algorithms/fa_to_regex_converter.dart';  // exports ConversionStep
export 'algorithms/nfa_to_dfa_converter.dart';   // exports ConversionStep

// Solution: Use qualified imports or rename classes
```

### 3. Type System Conflict
```dart
// Problem: Use cases expect AutomatonEntity but receive Automaton
final result = await _nfaToDfaUseCase.execute(nfa);  // nfa is Automaton, expects AutomatonEntity

// Solution: Either convert types or standardize on one type system
```

## 🔧 QUICK FIXES

### Add Missing Imports
Add this to all algorithm files missing ResultFactory:
```dart
import '../result.dart';
```

### Fix Vector2.zero() Issues
Replace:
```dart
this.panOffset = Vector2.zero(),  // Remove const
```

### Fix Missing Parameters
Add missing required parameters to constructors:
```dart
// Example: FSATransition needs id, label, etc.
final transition = FSATransition(
  id: 't1',
  fromState: fromState,
  toState: toState,
  label: 'a',
  inputSymbols: {'a'},
);
```

## 📋 PRIORITY ORDER
1. Create missing files
2. Fix export conflicts  
3. Resolve type system
4. Add missing imports
5. Fix constructor issues
6. Test compilation

## 🎯 SUCCESS METRIC
```bash
flutter run -d 89B37587-4BC2-4560-ACEA-8B65C649FFC8
# Should compile and launch without errors
```
