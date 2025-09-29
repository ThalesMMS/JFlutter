import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nfa_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class StatesTab extends StatefulWidget {
  const StatesTab({super.key});

  @override
  State<StatesTab> createState() => _StatesTabState();
}

class _StatesTabState extends State<StatesTab> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _addButtonController;
  late final AnimationController _listController;
  late final AnimationController _pulseController;
  late final AnimationController _statsController;
  late final AnimationController _morphController;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listController.forward();
    _statsController.forward();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _addButtonController.dispose();
    _listController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  Future<void> _addState() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    _addButtonController.forward();
    _morphController.forward();

    final name = _controller.text.trim();
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 400));

    if (nfaProvider.currentNFA.states.contains(name)) {
      HapticFeedback.mediumImpact();
      UIHelpers.showSnackBar(
          context,
          AppConstants.errorMessages['stateExists'] ??
              'این State قبلاً وجود دارد!',
          isError: true);
    } else {
      HapticFeedback.lightImpact();
      nfaProvider.addState(name);
      _controller.clear();
      UIHelpers.hideKeyboard(context);

      // Trigger success animation
      _triggerSuccessAnimation();
    }

    setState(() => _isAdding = false);
    _addButtonController.reverse();
    _morphController.reverse();
  }

  void _triggerSuccessAnimation() {
    _statsController.reset();
    _statsController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final states = nfa.currentNFA.states.toList()..sort();
        final startState = nfa.currentNFA.startState;
        final finalStates = nfa.currentNFA.finalStates;

        return Column(
          children: [
            // Enhanced Statistics Card with Parallax Effect
            if (states.isNotEmpty)
              _buildEnhancedStatsCard(states, startState, finalStates),

            Expanded(
              child: states.isEmpty
                  ? _buildEnhancedEmptyState()
                  : _buildAdvancedStatesList(
                      states, startState, finalStates, nfa),
            ),

            _buildMorphingAddStateForm(),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedStatsCard(
      List<String> states, String? startState, Set<String> finalStates) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _statsController.value) * 50),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = (1 + (_pulseController.value * 0.03));
              return Transform.scale(
                scale: pulseValue,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Animated background
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.secondaryContainer,
                              Theme.of(context).colorScheme.tertiaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _buildAnimatedStatItem('کل States',
                                  '${states.length}', Icons.account_tree, 0),
                              _buildGlowingDivider(),
                              _buildAnimatedStatItem(
                                  'شروع',
                                  startState ?? 'تعریف نشده',
                                  Icons.play_arrow,
                                  1),
                              _buildGlowingDivider(),
                              _buildAnimatedStatItem('پایانی',
                                  '${finalStates.length}', Icons.flag, 2),
                            ],
                          ),
                        ),
                      ),
                      ..._buildFloatingParticles(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final offset = _pulseController.value * 2 * math.pi;
          return Positioned(
            left: 20 + (index * 50) + (10 * math.sin(offset + index)),
            top: 10 + (15 * math.cos(offset * 0.7 + index)),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildGlowingDivider() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.5 + _pulseController.value * 0.3),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatItem(
      String label, String value, IconData icon, int index) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _statsController,
        builder: (context, child) {
          final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _statsController,
              curve: Interval(
                index * 0.2,
                (index * 0.2 + 0.6).clamp(0.0, 1.0),
                curve: Curves.elasticOut,
              ),
            ),
          );

          return Transform.scale(
            scale: itemAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _pulseController.value * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          icon,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.account_tree_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'هنوز هیچ State‌ای تعریف نشده',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'اولین State خود را اضافه کنید',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedStatesList(List<String> states, String? startState,
      Set<String> finalStates, NFAProvider nfa) {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: states.length,
          itemBuilder: (context, index) {
            final state = states[index];
            final isStart = state == startState;
            final isFinal = finalStates.contains(state);

            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Interval(
                index * 0.1,
                (index * 0.1 + 0.5).clamp(0.0, 1.0),
                curve: Curves.elasticOut,
              ),
            ));

            final scaleAnimation = Tween<double>(
              begin: 0,
              end: 1,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Interval(
                index * 0.1,
                (index * 0.1 + 0.5).clamp(0.0, 1.0),
                curve: Curves.elasticOut,
              ),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildMorphingStateCard(
                      state, isStart, isFinal, index, nfa),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMorphingStateCard(
      String state, bool isStart, bool isFinal, int index, NFAProvider nfa) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (isStart ? 5 : 0) * math.sin(_pulseController.value),
            0,
          ),
          child: Card(
            elevation: isStart ? 12 : (isFinal ? 8 : 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isStart
                      ? [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.7),
                        ]
                      : isFinal
                          ? [
                              Theme.of(context).colorScheme.secondaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withOpacity(0.7),
                            ]
                          : [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.5),
                            ],
                ),
                border: isFinal
                    ? Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2)
                    : null,
                boxShadow: [
                  if (isStart)
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: _buildPulsatingAvatar(index, isStart, isFinal),
                title: Row(
                  children: [
                    Text(
                      state,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (isStart) ...[
                      const SizedBox(width: 12),
                      _buildGlowingChip(
                        'شروع',
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                    if (isFinal) ...[
                      const SizedBox(width: 12),
                      _buildGlowingChip(
                        'پایانی',
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.onSecondary,
                      ),
                    ],
                  ],
                ),
                trailing:
                    _buildEnhancedStateActions(state, nfa, isStart, isFinal),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulsatingAvatar(int index, bool isStart, bool isFinal) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue =
            isStart ? (1 + (_pulseController.value * 0.15)) : 1.0;
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isStart
                    ? [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ]
                    : isFinal
                        ? [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                          ]
                        : [
                            Theme.of(context).colorScheme.surfaceVariant,
                            Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.7),
                          ],
              ),
              boxShadow: [
                if (isStart)
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isStart
                      ? Theme.of(context).colorScheme.onPrimary
                      : isFinal
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingChip(
      String label, Color backgroundColor, Color textColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStateActions(
      String state, NFAProvider nfa, bool isStart, bool isFinal) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced Radio for start state
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStart
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Radio<String>(
            value: state,
            groupValue: nfa.currentNFA.startState,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              nfa.setStartState(val!);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        // Enhanced Checkbox for final state
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFinal
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                : null,
          ),
          child: Checkbox(
            value: isFinal,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              nfa.toggleFinalState(state);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        // Enhanced Delete button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).colorScheme.error,
            tooltip: 'حذف State',
            onPressed: () => _confirmDeleteState(state, nfa),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteState(String state, NFAProvider nfa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            const Text('حذف State'),
          ],
        ),
        content: Text(
          'آیا از حذف State "$state" مطمئن هستید؟\nاین عمل قابل بازگشت نیست.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              elevation: 4,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      nfa.removeState(state);
    }
  }

  Widget _buildMorphingAddStateForm() {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                          Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'نام State جدید',
                        hintText: 'مثلاً: q0, q1, start',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _pulseController.value * 0.1,
                              child: const Icon(Icons.radio_button_checked),
                            );
                          },
                        ),
                        filled: true,
                      ),
                      validator: ValidationHelpers.validateStateName,
                      onFieldSubmitted: (_) => _addState(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedBuilder(
                  animation: _addButtonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_addButtonController.value * 0.2),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isAdding ? null : _addState,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isAdding
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add,
                                  size: 28, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Alphabet Tab with Particle Effects
class AlphabetTab extends StatefulWidget {
  const AlphabetTab({super.key});

  @override
  State<AlphabetTab> createState() => _AlphabetTabState();
}

class _AlphabetTabState extends State<AlphabetTab>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _gridController;
  late final AnimationController _quickAddController;
  late final AnimationController _particleController;
  late final AnimationController _waveController;

  final List<String> _quickSymbols = ['a', 'b', 'c', '0', '1', '+', '*', 'ε'];

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _quickAddController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _gridController.forward();
    _quickAddController.forward();
    _particleController.repeat();
    _waveController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _gridController.dispose();
    _quickAddController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _addSymbol([String? symbol]) {
    final symbolToAdd = symbol ?? _controller.text.trim();
    if (symbolToAdd.isEmpty) return;

    if (symbolToAdd.length > 1) {
      UIHelpers.showSnackBar(context, 'نماد باید فقط یک کاراکتر باشد.',
          isError: true);
      return;
    }

    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    if (nfaProvider.currentNFA.alphabet.contains(symbolToAdd)) {
      UIHelpers.showSnackBar(context, 'این نماد قبلاً وجود دارد!',
          isError: true);
      return;
    }

    HapticFeedback.lightImpact();
    nfaProvider.addSymbol(symbolToAdd);
    if (symbol == null) {
      _controller.clear();
      UIHelpers.hideKeyboard(context);
    }

    // Trigger grid refresh animation
    _gridController.reset();
    _gridController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final alphabet = nfa.currentNFA.alphabet.toList()..sort();

        return Column(
          children: [
            // Enhanced Quick add symbols with wave effect
            _buildWaveQuickAddSection(alphabet, nfa),

            // Enhanced Statistics with particles
            if (alphabet.isNotEmpty) _buildParticleAlphabetStats(alphabet),

            // Enhanced Alphabet grid with 3D effects
            Expanded(
              child: alphabet.isEmpty
                  ? _buildFloatingEmptyAlphabet()
                  : _build3DAlphabetGrid(alphabet, nfa),
            ),

            // Morphing add symbol form
            _buildFloatingAddSymbolForm(),
          ],
        );
      },
    );
  }

  Widget _buildWaveQuickAddSection(List<String> alphabet, NFAProvider nfa) {
    final availableSymbols =
        _quickSymbols.where((s) => !alphabet.contains(s)).toList();

    if (availableSymbols.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _quickAddController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _quickAddController,
            curve: Curves.elasticOut,
          )),
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2),
                  Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _waveController.value * 2 * math.pi,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.6),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'نمادهای پرکاربرد:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableSymbols.asMap().entries.map((entry) {
                        final index = entry.key;
                        final symbol = entry.value;
                        final waveOffset =
                            (_waveController.value * 2 * math.pi) +
                                (index * 0.5);
                        return Transform.translate(
                          offset: Offset(0, 5 * math.sin(waveOffset)),
                          child: _buildEnhancedQuickAddChip(symbol, index),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedQuickAddChip(String symbol, int index) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final glowIntensity = (0.5 +
            0.5 * math.sin(_particleController.value * 2 * math.pi + index));
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.3 * glowIntensity),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.primaryContainer,
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () => _addSymbol(symbol),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleAlphabetStats(List<String> alphabet) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondaryContainer,
                      Theme.of(context).colorScheme.tertiaryContainer,
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.text_fields,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الفبا شامل ${alphabet.length} نماد',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              alphabet.join(' • '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Floating particles
              ..._buildAlphabetParticles(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAlphabetParticles() {
    return List.generate(8, (index) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final offset =
              (_particleController.value * 2 * math.pi) + (index * 0.8);
          return Positioned(
            left: 30 + (index * 25) + (15 * math.cos(offset)),
            top: 15 + (20 * math.sin(offset)),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildFloatingEmptyAlphabet() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, 10 * math.sin(_waveController.value)),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.text_fields,
                    size: 100,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'الفبا خالی است',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'نمادهای ورودی خود را اضافه کنید',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DAlphabetGrid(List<String> alphabet, NFAProvider nfa) {
    return AnimatedBuilder(
      animation: _gridController,
      builder: (context, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: alphabet.length,
          itemBuilder: (context, index) {
            final symbol = alphabet[index];
            final staggeredAnimation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _gridController,
                curve: Interval(
                  index * 0.1,
                  (index * 0.1 + 0.6).clamp(0.0, 1.0),
                  curve: Curves.elasticOut,
                ),
              ),
            );

            return AnimatedBuilder(
              animation: staggeredAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: staggeredAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (1 - staggeredAnimation.value) * 100,
                    ),
                    child: _build3DSymbolCard(symbol, nfa, index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _build3DSymbolCard(String symbol, NFAProvider nfa, int index) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final floatOffset =
            5 * math.sin(_particleController.value * 2 * math.pi + index * 0.3);
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.secondaryContainer,
                      Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.8),
                      Theme.of(context)
                          .colorScheme
                          .tertiaryContainer
                          .withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onLongPress: () => _confirmDeleteSymbol(symbol, nfa),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  symbol,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontSize: 32,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.3),
                                      Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.2),
                                  Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () =>
                                  _confirmDeleteSymbol(symbol, nfa),
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              tooltip: 'حذف نماد',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSymbol(String symbol, NFAProvider nfa) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            const Text('حذف نماد'),
          ],
        ),
        content: Text(
          'آیا از حذف نماد "$symbol" مطمئن هستید؟\nاین عمل قابل بازگشت نیست.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              elevation: 4,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      nfa.removeSymbol(symbol);
    }
  }

  Widget _buildFloatingAddSymbolForm() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                        Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLength: 1,
                    decoration: InputDecoration(
                      labelText: 'نماد جدید',
                      hintText: 'یک کاراکتر وارد کنید',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _particleController.value * 0.2,
                            child: const Icon(Icons.text_fields),
                          );
                        },
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    onSubmitted: (_) => _addSymbol(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _addSymbol,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 28, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
