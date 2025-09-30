import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/models/math_content_data1.dart';
import '/widgets/math_lesson_widgets1.dart';

class InteractiveDialogueLessonScreen extends StatefulWidget {
  const InteractiveDialogueLessonScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveDialogueLessonScreen> createState() =>
      _InteractiveDialogueLessonScreenState();
}

class _InteractiveDialogueLessonScreenState
    extends State<InteractiveDialogueLessonScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  int _currentSectionIndex = 0;
  bool _isCompleted = false;
  DateTime? _lessonStartTime;

  final List<String> _completedSections = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLesson();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeLesson() {
    _lessonStartTime = DateTime.now();
    _updateProgress();
    _progressAnimationController.forward();
  }

  Future<void> _saveProgress() async {
    debugPrint('پیشرفت ذخیره شد: بخش $_currentSectionIndex');
  }

  Duration _getTotalTimeSpent() {
    if (_lessonStartTime == null) return Duration.zero;
    return DateTime.now().difference(_lessonStartTime!);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentSectionIndex = index;
    });
    final currentSection = MathContentData.sections[index];
    if (!_completedSections.contains(currentSection.id)) {
      _completedSections.add(currentSection.id);
      debugPrint('بخش تکمیل شد: ${currentSection.title}');
    }
    _updateProgress();
    _saveProgress();
  }

  void _nextSection() {
    if (_currentSectionIndex < MathContentData.sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeLesson();
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateProgress() {
    double currentProgress =
        (_currentSectionIndex + 1) / MathContentData.sections.length;

    if (_progressAnimationController.isCompleted ||
        _progressAnimationController.isDismissed) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: currentProgress,
          ).animate(
            CurvedAnimation(
              parent: _progressAnimationController,
              curve: Curves.easeInOut,
            ),
          );
      _progressAnimationController.forward(from: 0.0);
    } else {
      _progressAnimation = Tween<double>(begin: 0.0, end: currentProgress)
          .animate(
            CurvedAnimation(
              parent: _progressAnimationController,
              curve: Curves.easeInOut,
            ),
          );
    }
  }

  void _completeLesson() {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    debugPrint('درس تکمیل شد!');
    _showCompletionDialog();
  }

  void _restartLesson() {
    Navigator.of(context).pop();
    setState(() {
      _isCompleted = false;
      _completedSections.clear();
      _lessonStartTime = DateTime.now();
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: MathContentData.sections.length,
                itemBuilder: (context, index) {
                  final sectionData = MathContentData.sections[index];
                  return LessonSectionWidget(
                    id: sectionData.id,
                    title: sectionData.title,
                    order: sectionData.order,
                    estimatedTime: sectionData.estimatedTime,
                    summary: sectionData.summary,
                    dialogues: sectionData.dialogues.map((dialogueData) {
                      return DialogueMessageWidget(
                        speaker: dialogueData.speaker,
                        avatar: dialogueData.avatar,
                        message: dialogueData.message,
                        isTeacher: dialogueData.isTeacher,
                        hasExample: dialogueData.hasExample,
                        example: dialogueData.example,
                        hasFormula: dialogueData.hasFormula,
                        formula: dialogueData.formula,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(),
          ),
          Expanded(
            child: Text(
              MathContentData.lessonTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'تنظیمات',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.primaryBlue,
          ),
          minHeight: 5,
        );
      },
    );
  }

  Widget _buildBottomControls() {
    bool isFirstSection = _currentSectionIndex == 0;
    bool isLastSection =
        _currentSectionIndex == MathContentData.sections.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('قبلی'),
            onPressed: isFirstSection ? null : _previousSection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGray,
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          Text(
            'بخش ${(_currentSectionIndex + 1)} از ${MathContentData.sections.length}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: Text(isLastSection ? 'پایان' : 'بعدی'),
            onPressed: _nextSection,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastSection
                  ? AppColors.successGreen
                  : AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: AppColors.successGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'تبریک! 🎉',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'شما این درس را با موفقیت به پایان رساندید',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildLessonStats(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _restartLesson(),
                  child: const Text('تکرار درس'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ادامه'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonStats() {
    final timeSpent = _getTotalTimeSpent();
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('زمان صرف شده', _formatDuration(timeSpent)),
            const Divider(height: 16),
            _buildStatRow(
              'بخش‌های تکمیل شده',
              '${MathContentData.sections.length}/${MathContentData.sections.length}',
            ),
            const Divider(height: 16),
            _buildStatRow('پیشرفت کلی', '100%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از درس'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید از درس خارج شوید؟ پیشرفت شما ذخیره خواهد شد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنظیمات درس'),
        content: const Text('تنظیمات درس در نسخه‌های بعدی اضافه خواهد شد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }
}
