import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/conversion_provider.dart';
import '../services/converter_service.dart' hide ConversionResult;
import '../utils/constants.dart';
import '../models/conversion_models.dart' hide ConversionResult;

class ConversionProcessScreen extends StatefulWidget {
  const ConversionProcessScreen({super.key});

  @override
  State<ConversionProcessScreen> createState() => _ConversionProcessScreenState();
}

class _ConversionProcessScreenState extends State<ConversionProcessScreen>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late final AnimationController _resultController;
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupConversionListener();
  }

  void _initializeAnimations() {
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);
  }

  void _setupConversionListener() {
    final conversionProvider = Provider.of<ConversionProvider>(context, listen: false);

    if (conversionProvider.isConverting) {
      _progressController.forward();

      void listener() {
        if (!conversionProvider.isConverting) {
          _progressController.stop();
          _pulseController.stop();
          _resultController.forward();
          conversionProvider.removeListener(listener);

          HapticFeedback.lightImpact();
        }
      }

      conversionProvider.addListener(listener);
    } else {
      _resultController.forward();
    }
  }

  @override
  void dispose() {
    _resultController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addLogItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listKey.currentState != null) {
        final provider = Provider.of<ConversionProvider>(context, listen: false);
        _listKey.currentState!.insertItem(
          provider.conversionLog.length - 1,
          duration: const Duration(milliseconds: 400),
        );

        _scrollToBottom();

        HapticFeedback.selectionClick();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        if (provider.isNewLogAdded) {
          _addLogItem();
          provider.logWasDisplayed();
        }

        return PopScope(
          canPop: !provider.isConverting,
          onPopInvoked: (didPop) {
            if (!didPop && provider.isConverting) {
              _showCancelDialog(context, provider);
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(context, provider),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: provider.isConverting
                  ? _buildInProgressView(provider)
                  : _buildResultView(context, provider),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConversionProvider provider) {
    return AppBar(
      elevation: 0,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          provider.isConverting ? 'در حال تبدیل...' : 'نتیجه تبدیل',
          key: ValueKey(provider.isConverting),
        ),
      ),
      automaticallyImplyLeading: !provider.isConverting,
      actions: [
        if (provider.isConverting)
          AnimatedSlide(
            offset: provider.isConverting ? Offset.zero : const Offset(1.0, 0),
            duration: const Duration(milliseconds: 400),
            child: TextButton.icon(
              onPressed: () => _showCancelDialog(context, provider),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('لغو', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, ConversionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لغو تبدیل'),
        content: const Text('آیا مطمئن هستید که می‌خواهید عملیات تبدیل را لغو کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('خیر'),
          ),
          TextButton(
            onPressed: () {
              provider.cancelConversion();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('بله، لغو کن'),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressView(ConversionProvider provider) {
    return Column(
      key: const ValueKey('inProgress'),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                _buildEnhancedCircularProgress(provider),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    provider.currentStepMessage,
                    key: ValueKey(provider.currentStepMessage),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgressIndicator(provider),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
            ),
            child: _buildEnhancedLogList(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCircularProgress(ConversionProvider provider) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(
                  0.2 + (_pulseController.value * 0.1),
                ),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: _pulseController.value * 5,
              ),
            ],
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: provider.conversionProgress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(value * 100).toInt()}%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withOpacity(
                              0.5 + (_pulseController.value * 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(ConversionProvider provider) {
    final totalSteps = 5;
    final currentStep = (provider.conversionProgress * totalSteps).floor();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Theme.of(context).colorScheme.surfaceVariant,
          ),
        );
      }),
    );
  }

  Widget _buildEnhancedLogList(ConversionProvider provider) {
    return AnimatedList(
      key: _listKey,
      controller: _scrollController,
      initialItemCount: provider.conversionLog.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index, animation) {
        final log = provider.conversionLog[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.5, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: _buildEnhancedLogItem(log, index + 1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLogItem(ConversionProgress step, int stepNumber) {
    final isError = step.type == ConversionProgressType.error;
    final isCompleted = step.type == ConversionProgressType.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Theme.of(context).colorScheme.error.withOpacity(0.3)
              : isCompleted
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getColorForStep(step.type).withOpacity(0.1),
                border: Border.all(
                  color: _getColorForStep(step.type).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getColorForStep(step.type),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isError || isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      isError ? 'خطا رخ داده است' : 'تکمیل شد',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getColorForStep(step.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getColorForStep(step.type).withOpacity(0.1),
              ),
              child: Icon(
                _getIconForStep(step.type),
                size: 20,
                color: _getColorForStep(step.type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForStep(ConversionProgressType type) {
    switch (type) {
      case ConversionProgressType.started:
        return Theme.of(context).colorScheme.primary;
      case ConversionProgressType.completed:
        return Colors.green;
      case ConversionProgressType.error:
        return Theme.of(context).colorScheme.error;
      case ConversionProgressType.processingState:
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData _getIconForStep(ConversionProgressType type) {
    switch (type) {
      case ConversionProgressType.started:
        return Icons.play_circle_outline;
      case ConversionProgressType.epsilonClosure:
        return Icons.merge_type;
      case ConversionProgressType.subsetConstruction:
        return Icons.group_work_outlined;
      case ConversionProgressType.processingState:
        return Icons.sync;
      case ConversionProgressType.finalizing:
        return Icons.flag_outlined;
      case ConversionProgressType.completed:
        return Icons.check_circle_outline;
      case ConversionProgressType.error:
        return Icons.error_outline;
      case ConversionProgressType.batchProgress:
        return Icons.view_list_outlined;
      case ConversionProgressType.message:
        return Icons.info_outline;
    }
  }

  Widget _buildResultView(BuildContext context, ConversionProvider provider) {
    final result = provider.conversionResult;
    if (result == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('نتیجه‌ای برای نمایش وجود ندارد.'),
          ],
        ),
      );
    }

    final isSuccess = result.isSuccess;
    final theme = Theme.of(context);
    final color = isSuccess ? Colors.green : theme.colorScheme.error;

    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _resultController,
              curve: Curves.elasticOut,
            ),
            child: FadeTransition(
              opacity: _resultController,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      size: 72,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isSuccess ? 'تبدیل موفقیت‌آمیز بود!' : 'خطا در تبدیل',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Text(
                      isSuccess
                          ? 'NFA با موفقیت به DFA تبدیل شد. حالا می‌توانید نتیجه را بررسی کنید.'
                          : result.errorMessage ?? 'یک خطای ناشناخته رخ داده است.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (result.isSuccess && result.nfa != null && result.dfa != null) ...[
                    const SizedBox(height: 32),
                    _buildEnhancedResultStats(context, result),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _resultController,
              curve: Curves.easeOutCubic,
            )),
            child: Column(
              children: [
                if (isSuccess)
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.result,
                        arguments: result,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('مشاهده نتیجه DFA'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('بازگشت به صفحه ورود'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (isSuccess)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName(AppRoutes.home),
                      );
                    },
                    child: const Text('بازگشت به صفحه اصلی'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedResultStats(BuildContext context, ConversionResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEnhancedStatItem(
              'حالت‌های NFA',
              result.nfa!.stateCount.toString(),
              Icons.account_tree_outlined,
            ),
            VerticalDivider(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              thickness: 1,
            ),
            _buildEnhancedStatItem(
              'حالت‌های DFA',
              result.dfa!.stateCount.toString(),
              Icons.hub_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}