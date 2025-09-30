import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nfa_provider.dart';
import '../utils/helpers.dart';

class TransitionHelpers {
  // Quick Add Dialog - امکان افزودن سریع چندین انتقال
  static void showQuickAdd(BuildContext context) {
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    final states = nfaProvider.currentNFA.states.toList()..sort();
    final alphabetWithEpsilon = ['ε', ...nfaProvider.currentNFA.alphabet]
      ..sort();

    String? selectedFromState;
    String? selectedToState;
    List<String> selectedSymbols = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              const Text('افزودن سریع انتقال‌ها'),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'یک State مبدأ و مقصد انتخاب کنید، سپس نمادهای مورد نظر را انتخاب کنید:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // From State Selection
                  Text(
                    'از State:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedFromState,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.radio_button_checked),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    items: states
                        .map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedFromState = value),
                    hint: const Text('State مبدأ را انتخاب کنید'),
                  ),
                  const SizedBox(height: 16),

                  // To State Selection
                  Text(
                    'به State:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedToState,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.flag),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    items: states
                        .map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedToState = value),
                    hint: const Text('State مقصد را انتخاب کنید'),
                  ),
                  const SizedBox(height: 20),

                  // Symbols Selection
                  Text(
                    'نمادها:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: alphabetWithEpsilon.map((symbol) {
                        final isSelected = selectedSymbols.contains(symbol);
                        return CheckboxListTile(
                          title: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: symbol == 'ε'
                                    ? [
                                        Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withOpacity(0.7),
                                      ]
                                    : [
                                        Theme.of(
                                          context,
                                        ).colorScheme.tertiaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .tertiaryContainer
                                            .withOpacity(0.7),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: symbol == 'ε'
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedSymbols.add(symbol);
                              } else {
                                selectedSymbols.remove(symbol);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview
                  if (selectedFromState != null &&
                      selectedToState != null &&
                      selectedSymbols.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'پیش‌نمایش:',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...selectedSymbols.map(
                            (symbol) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$selectedFromState --($symbol)--> $selectedToState',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedSymbols.length} انتقال اضافه خواهد شد',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton.icon(
              onPressed:
                  (selectedFromState != null &&
                      selectedToState != null &&
                      selectedSymbols.isNotEmpty)
                  ? () {
                      _addMultipleTransitions(
                        context,
                        nfaProvider,
                        selectedFromState!,
                        selectedToState!,
                        selectedSymbols,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              icon: const Icon(Icons.add_circle),
              label: Text('افزودن ${selectedSymbols.length} انتقال'),
            ),
          ],
        ),
      ),
    );
  }

  // Edit State Transitions Dialog - ویرایش انتقال‌های یک state
  static void showEditStateTransitions(
    BuildContext context,
    String fromState,
    Map<String, Set<String>> symbolTransitions,
  ) {
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    final allStates = nfaProvider.currentNFA.states.toList()..sort();
    final alphabetWithEpsilon = ['ε', ...nfaProvider.currentNFA.alphabet]
      ..sort();

    // Create editable copy of transitions
    Map<String, Set<String>> editableTransitions = {};
    symbolTransitions.forEach((symbol, states) {
      editableTransitions[symbol] = Set.from(states);
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Hero(
                tag: 'state_$fromState',
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    fromState.length > 2
                        ? fromState.substring(0, 2).toUpperCase()
                        : fromState.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ویرایش انتقال‌های $fromState'),
                    Text(
                      '${_countTotalTransitions(editableTransitions)} انتقال',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add new transition section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'افزودن انتقال جدید',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'نماد',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: alphabetWithEpsilon
                                    .map(
                                      (symbol) => DropdownMenuItem(
                                        value: symbol,
                                        child: Text(symbol),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (symbol) {
                                  if (symbol != null) {
                                    _showAddTransitionToState(
                                      context,
                                      setState,
                                      fromState,
                                      symbol,
                                      allStates,
                                      editableTransitions,
                                    );
                                  }
                                },
                                hint: const Text('انتخاب نماد'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Existing transitions
                  if (editableTransitions.isNotEmpty) ...[
                    Text(
                      'انتقال‌های موجود:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...editableTransitions.entries.map((entry) {
                      final symbol = entry.key;
                      final toStates = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: symbol == 'ε'
                                    ? [
                                        Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withOpacity(0.7),
                                      ]
                                    : [
                                        Theme.of(
                                          context,
                                        ).colorScheme.tertiaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .tertiaryContainer
                                            .withOpacity(0.7),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: symbol == 'ε'
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                          title: Text('${toStates.length} مقصد'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => _showAddTransitionToState(
                                  context,
                                  setState,
                                  fromState,
                                  symbol,
                                  allStates,
                                  editableTransitions,
                                ),
                                tooltip: 'افزودن مقصد جدید',
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                          children: toStates.map((toState) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                child: Text(
                                  toState.length > 2
                                      ? toState.substring(0, 2).toUpperCase()
                                      : toState.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$fromState → $toState',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    editableTransitions[symbol]?.remove(
                                      toState,
                                    );
                                    if (editableTransitions[symbol]?.isEmpty ==
                                        true) {
                                      editableTransitions.remove(symbol);
                                    }
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                tooltip: 'حذف انتقال',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'هیچ انتقالی برای این State تعریف نشده',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            FilledButton.icon(
              onPressed: () {
                _applyTransitionChanges(
                  context,
                  nfaProvider,
                  fromState,
                  symbolTransitions,
                  editableTransitions,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('ذخیره تغییرات'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  static void _addMultipleTransitions(
    BuildContext context,
    NFAProvider nfaProvider,
    String fromState,
    String toState,
    List<String> symbols,
  ) {
    int addedCount = 0;
    int skippedCount = 0;

    for (String symbol in symbols) {
      if (nfaProvider.currentNFA.transitions[fromState]?[symbol]?.contains(
            toState,
          ) !=
          true) {
        nfaProvider.addTransition(fromState, symbol, toState);
        addedCount++;
      } else {
        skippedCount++;
      }
    }

    HapticFeedback.lightImpact();

    String message = '';
    if (addedCount > 0 && skippedCount == 0) {
      message = '$addedCount انتقال با موفقیت اضافه شد.';
    } else if (addedCount > 0 && skippedCount > 0) {
      message =
          '$addedCount انتقال اضافه شد، $skippedCount انتقال از قبل موجود بود.';
    } else {
      message = 'همه انتقال‌ها از قبل موجود بودند.';
    }

    UIHelpers.showSnackBar(context, message, isError: addedCount == 0);
  }

  static void _showAddTransitionToState(
    BuildContext context,
    StateSetter setState,
    String fromState,
    String symbol,
    List<String> allStates,
    Map<String, Set<String>> editableTransitions,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('افزودن مقصد برای نماد $symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: allStates.map((state) {
            final isAlreadyAdded =
                editableTransitions[symbol]?.contains(state) == true;
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isAlreadyAdded
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  state.length > 2
                      ? state.substring(0, 2).toUpperCase()
                      : state.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAlreadyAdded
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(state),
              subtitle: isAlreadyAdded ? const Text('قبلاً اضافه شده') : null,
              enabled: !isAlreadyAdded,
              onTap: isAlreadyAdded
                  ? null
                  : () {
                      setState(() {
                        editableTransitions[symbol] ??= <String>{};
                        editableTransitions[symbol]!.add(state);
                      });
                      Navigator.of(context).pop();
                      HapticFeedback.lightImpact();
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  static void _applyTransitionChanges(
    BuildContext context,
    NFAProvider nfaProvider,
    String fromState,
    Map<String, Set<String>> originalTransitions,
    Map<String, Set<String>> editableTransitions,
  ) {
    // Remove all original transitions for this state
    originalTransitions.forEach((symbol, toStates) {
      for (String toState in toStates) {
        nfaProvider.removeTransition(fromState, symbol, toState);
      }
    });

    // Add all new transitions
    int addedCount = 0;
    editableTransitions.forEach((symbol, toStates) {
      for (String toState in toStates) {
        nfaProvider.addTransition(fromState, symbol, toState);
        addedCount++;
      }
    });

    HapticFeedback.mediumImpact();
    UIHelpers.showSnackBar(
      context,
      'تغییرات با موفقیت اعمال شد. ($addedCount انتقال)',
      isError: false,
    );
  }

  static int _countTotalTransitions(
    Map<String, Set<String>> symbolTransitions,
  ) {
    return symbolTransitions.values.fold(
      0,
      (sum, states) => sum + states.length,
    );
  }
}
