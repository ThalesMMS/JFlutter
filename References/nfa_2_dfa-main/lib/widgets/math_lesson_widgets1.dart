import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/models/math_content_data1.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryYellow = Color(0xFFFFC107);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color teacherBlue = Color(0xFF1976D2);
  static const Color studentGreen = Color(0xFF388E3C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF424242);
}

class MathLessonWidget extends StatefulWidget {
  final String lessonTitle;
  final String lessonSubtitle;
  final int estimatedTime;
  final List<String> learningObjectives;
  final List<LessonSectionWidget> sections;
  final VoidCallback? onComplete;

  const MathLessonWidget({
    Key? key,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.estimatedTime,
    required this.learningObjectives,
    required this.sections,
    this.onComplete,
  }) : super(key: key);

  @override
  State<MathLessonWidget> createState() => _MathLessonWidgetState();
}

class _MathLessonWidgetState extends State<MathLessonWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showObjectives = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // 📊 نوار بالا - عنوان و پیشرفت
            _buildHeader(),
            // 📱 محتوای اصلی
            Expanded(
              child: _showObjectives
                  ? _buildObjectivesView()
                  : _buildLessonContent(),
            ),
            // 🎮 نوار کنترل
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, Colors.blue[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lessonTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.lessonSubtitle} • ${widget.estimatedTime} دقیقه',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (!_showObjectives) ...[
              const SizedBox(height: 12),
              _buildProgressBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / (widget.sections.length + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'پیشرفت: ${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 3,
        ),
      ],
    );
  }

  Widget _buildObjectivesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // کارت خوش‌آمدگویی
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.successGreen, Colors.green[300]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  '🎉',
                  style: TextStyle(fontSize: 40),
                ),
                SizedBox(height: 8),
                Text(
                  'به درس مقدمات ریاضی خوش آمدید!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'آماده یادگیری مفاهیم جذاب ریاضی هستید؟',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // اهداف یادگیری
          const Text(
            '🎯 اهداف یادگیری',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          ...widget.learningObjectives.asMap().entries.map((entry) {
            final index = entry.key;
            final objective = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ObjectiveCard(
                objective: objective,
                index: index + 1,
              ),
            );
          }),

          const SizedBox(height: 24),

          // دکمه شروع
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showObjectives = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'شروع درس',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.play_arrow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      itemCount: widget.sections.length,
      itemBuilder: (context, index) {
        return widget.sections[index];
      },
    );
  }

  Widget _buildControlBar() {
    if (_showObjectives) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // دکمه قبلی
            if (_currentPage > 0)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: AppColors.darkGray,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16),
                      Text('قبلی'),
                    ],
                  ),
                ),
              ),

            if (_currentPage > 0) const SizedBox(width: 12),

            // اطلاعات صفحه
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPage + 1} از ${widget.sections.length}',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_currentPage < widget.sections.length - 1)
              const SizedBox(width: 12),

            // دکمه بعدی
            if (_currentPage < widget.sections.length - 1)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('بعدی'),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),

            // دکمه پایان درس
            if (_currentPage == widget.sections.length - 1)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    widget.onComplete?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('پایان درس'),
                      SizedBox(width: 4),
                      Icon(Icons.check_circle, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ObjectiveCard extends StatefulWidget {
  final String objective;
  final int index;

  const ObjectiveCard({
    Key? key,
    required this.objective,
    required this.index,
  }) : super(key: key);

  @override
  State<ObjectiveCard> createState() => _ObjectiveCardState();
}

class _ObjectiveCardState extends State<ObjectiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.objective,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGray,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.successGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LessonSectionWidget extends StatefulWidget {
  final String id;
  final String title;
  final int order;
  final List<DialogueMessageWidget> dialogues;
  final int estimatedTime;
  final String? summary;

  const LessonSectionWidget({
    Key? key,
    required this.id,
    required this.title,
    required this.order,
    required this.dialogues,
    required this.estimatedTime,
    this.summary,
  }) : super(key: key);

  @override
  State<LessonSectionWidget> createState() => _LessonSectionWidgetState();
}

class _LessonSectionWidgetState extends State<LessonSectionWidget>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  int _currentDialogueIndex = 0;
  bool _autoScroll = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController.forward();

    // شروع نمایش تدریجی گفتگوها
    _startDialogueAnimation();
  }

  void _startDialogueAnimation() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _currentDialogueIndex < widget.dialogues.length - 1) {
        setState(() {
          _currentDialogueIndex++;
        });

        // اسکرول خودکار
        if (_autoScroll) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }

        _startDialogueAnimation();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان بخش
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.teacherBlue, Colors.blue[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teacherBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.estimatedTime} دقیقه',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // گفتگوها
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _currentDialogueIndex + 1,
              itemBuilder: (context, index) {
                if (index < widget.dialogues.length) {
                  return AnimatedOpacity(
                    opacity: index <= _currentDialogueIndex ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: widget.dialogues[index],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // کنترل‌ها
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // دکمه نمایش همه
          if (_currentDialogueIndex < widget.dialogues.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentDialogueIndex = widget.dialogues.length - 1;
                    _autoScroll = false;
                  });
                },
                icon: const Icon(Icons.fast_forward, size: 16),
                label: const Text('نمایش همه'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (_currentDialogueIndex < widget.dialogues.length - 1)
            const SizedBox(width: 12),

          // دکمه اسکرول خودکار
          Container(
            decoration: BoxDecoration(
              color: _autoScroll ? AppColors.successGreen : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _autoScroll = !_autoScroll;
                });
              },
              icon: Icon(
                _autoScroll ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                color: _autoScroll ? Colors.white : Colors.grey[600],
              ),
              tooltip: 'اسکرول خودکار',
            ),
          ),
        ],
      ),
    );
  }
}

class DialogueMessageWidget extends StatefulWidget {
  final String speaker;
  final String avatar;
  final String message;
  final bool isTeacher;
  final bool hasExample;
  final String? example;
  final bool hasFormula;
  final String? formula;

  const DialogueMessageWidget({
    Key? key,
    required this.speaker,
    required this.avatar,
    required this.message,
    required this.isTeacher,
    this.hasExample = false,
    this.example,
    this.hasFormula = false,
    this.formula,
  }) : super(key: key);

  @override
  State<DialogueMessageWidget> createState() => _DialogueMessageWidgetState();
}

class _DialogueMessageWidgetState extends State<DialogueMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isTeacher ? -1.0 : 1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isTeacher) ...[
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(child: _buildMessageBubble()),
              ] else ...[
                Expanded(child: _buildMessageBubble()),
                const SizedBox(width: 12),
                _buildAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            widget.isTeacher ? AppColors.teacherBlue : AppColors.studentGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (widget.isTeacher
                    ? AppColors.teacherBlue
                    : AppColors.studentGreen)
                .withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.avatar,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Column(
      crossAxisAlignment:
          widget.isTeacher ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // نام گوینده
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            widget.speaker,
            style: TextStyle(
              fontSize: 12,
              color: widget.isTeacher
                  ? AppColors.teacherBlue
                  : AppColors.studentGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // حباب پیام
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isTeacher
                ? AppColors.teacherBlue.withOpacity(0.1)
                : AppColors.studentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(widget.isTeacher ? 4 : 16),
              bottomRight: Radius.circular(widget.isTeacher ? 16 : 4),
            ),
            border: Border.all(
              color: widget.isTeacher
                  ? AppColors.teacherBlue.withOpacity(0.3)
                  : AppColors.studentGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
        ),

        // مثال (در صورت وجود)
        if (widget.hasExample && widget.example != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondaryYellow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.warningOrange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'مثال:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.example!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

        // فرمول (در صورت وجود)
        if (widget.hasFormula && widget.formula != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.functions,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'فرمول:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.formula!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InteractiveQuizWidget extends StatefulWidget {
  final QuizQuestion questionData;
  final Function(bool isCorrect)? onAnswered;

  const InteractiveQuizWidget({
    Key? key,
    required this.questionData,
    this.onAnswered,
  }) : super(key: key);

  @override
  State<InteractiveQuizWidget> createState() => _InteractiveQuizWidgetState();
}

class _InteractiveQuizWidgetState extends State<InteractiveQuizWidget>
    with TickerProviderStateMixin {
  int? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  late AnimationController _shakeController;
  late AnimationController _celebrateController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _celebrateAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _celebrateController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeAnimation =
        Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _celebrateAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _celebrateController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_showResult) return;

    setState(() {
      _selectedOption = index;
    });
  }

  void _submitAnswer() {
    if (_selectedOption == null || _showResult) return;

    _isCorrect = _selectedOption == widget.questionData.correctAnswer;

    setState(() {
      _showResult = true;
    });

    if (_isCorrect) {
      HapticFeedback.heavyImpact();
      _celebrateController.forward();
    } else {
      HapticFeedback.lightImpact();
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    }

    widget.onAnswered?.call(_isCorrect);
  }

  void _resetQuiz() {
    setState(() {
      _selectedOption = null;
      _showResult = false;
      _isCorrect = false;
    });
    _celebrateController.reset();
    _shakeController.reset();
  }

  Widget _buildDifficultyIndicator(int difficulty) {
    final List<Widget> stars = List.generate(
      3,
      (index) => Icon(
        index < difficulty ? Icons.star : Icons.star_border,
        color: AppColors.warningOrange,
        size: 18,
      ),
    );

    String difficultyText;
    switch (difficulty) {
      case 1:
        difficultyText = 'آسان';
        break;
      case 2:
        difficultyText = 'متوسط';
        break;
      case 3:
        difficultyText = 'سخت';
        break;
      default:
        difficultyText = 'نامشخص';
    }

    return Row(
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          difficultyText,
          style: const TextStyle(
            color: AppColors.darkGray,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر تست
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🧪 تست تعاملی',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              if (_showResult)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isCorrect
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isCorrect ? '✅ درست' : '❌ غلط',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDifficultyIndicator(widget.questionData.difficulty),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.questionData.points} امتیاز',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          if (widget.questionData.context.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teacherBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.teacherBlue.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.questionData.context,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.teacherBlue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Text(
                  widget.questionData.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // گزینه‌ها
          ...widget.questionData.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedOption == index;
            final isCorrectOption = index == widget.questionData.correctAnswer;

            Color backgroundColor = Colors.grey[50]!;
            Color borderColor = Colors.grey[300]!;
            Color textColor = AppColors.darkGray;

            if (_showResult) {
              if (isCorrectOption) {
                backgroundColor = AppColors.successGreen.withOpacity(0.1);
                borderColor = AppColors.successGreen;
                textColor = AppColors.successGreen;
              } else if (isSelected && !isCorrectOption) {
                backgroundColor = AppColors.errorRed.withOpacity(0.1);
                borderColor = AppColors.errorRed;
                textColor = AppColors.errorRed;
              }
            } else if (isSelected) {
              backgroundColor = AppColors.primaryBlue.withOpacity(0.1);
              borderColor = AppColors.primaryBlue;
              textColor = AppColors.primaryBlue;
            }

            return AnimatedBuilder(
              animation: _celebrateAnimation,
              builder: (context, child) {
                final scale = (_showResult && isCorrectOption && _isCorrect)
                    ? _celebrateAnimation.value
                    : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: () => _selectOption(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  isSelected || (_showResult && isCorrectOption)
                                      ? borderColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child:
                                isSelected || (_showResult && isCorrectOption)
                                    ? Icon(
                                        _showResult && isCorrectOption
                                            ? Icons.check
                                            : Icons.circle,
                                        color: Colors.white,
                                        size: 12,
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: isSelected ||
                                        (_showResult && isCorrectOption)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_showResult && isCorrectOption)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.successGreen,
                              size: 20,
                            ),
                          if (_showResult && isSelected && !isCorrectOption)
                            const Icon(
                              Icons.cancel,
                              color: AppColors.errorRed,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 16),

          // دکمه‌های کنترل
          if (!_showResult) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedOption != null ? _submitAnswer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ثبت پاسخ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (widget.questionData.hint != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _showHint(context);
                    },
                    icon: const Icon(Icons.help_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.warningOrange.withOpacity(0.1),
                      foregroundColor: AppColors.warningOrange,
                    ),
                    tooltip: 'راهنمایی',
                  ),
                ],
              ],
            ),
          ] else ...[
            // نمایش نتیجه
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? AppColors.successGreen.withOpacity(0.1)
                    : AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _isCorrect ? AppColors.successGreen : AppColors.errorRed,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCorrect ? Icons.celebration : Icons.info_outline,
                        color: _isCorrect
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'آفرین!' : 'توضیح:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.questionData.explanation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teacherBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('👨‍🏫', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.questionData.teacherResponse,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.teacherBlue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // دکمه تلاش مجدد
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showHint(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: AppColors.warningOrange),
            SizedBox(width: 8),
            Text(
              'راهنمایی',
              style: TextStyle(color: AppColors.warningOrange),
            ),
          ],
        ),
        content: Text(
          widget.questionData.hint!,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }
}

// 📊 ویجت نمایش پیشرفت
class ProgressIndicatorWidget extends StatefulWidget {
  final double progress;
  final String label;
  final Color color;
  final Duration animationDuration;

  const ProgressIndicatorWidget({
    Key? key,
    required this.progress,
    required this.label,
    this.color = AppColors.primaryBlue,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<ProgressIndicatorWidget> createState() =>
      _ProgressIndicatorWidgetState();
}

class _ProgressIndicatorWidgetState extends State<ProgressIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ProgressIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                minHeight: 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

// 📝 ویجت نکته مهم
class ImportantNoteWidget extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  final IconData? icon;

  const ImportantNoteWidget({
    Key? key,
    required this.title,
    required this.content,
    required this.type,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData noteIcon;

    switch (type) {
      case 'warning':
        color = AppColors.warningOrange;
        noteIcon = Icons.warning_outlined;
        break;
      case 'tip':
        color = AppColors.successGreen;
        noteIcon = Icons.lightbulb_outlined;
        break;
      case 'formula':
        color = AppColors.primaryBlue;
        noteIcon = Icons.functions;
        break;
      case 'important':
        color = AppColors.errorRed;
        noteIcon = Icons.priority_high;
        break;
      case 'key':
        color = AppColors.secondaryYellow;
        noteIcon = Icons.key;
        break;
      default:
        color = AppColors.primaryBlue;
        noteIcon = Icons.info_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon ?? noteIcon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
