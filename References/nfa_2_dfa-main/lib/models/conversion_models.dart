/// enum برای انواع مراحل تبدیل
enum ConversionStepType {
  started,
  epsilonClosure,
  subsetConstruction,
  processingState,
  finalizing,
  completed,
}

/// کلاس برای نمایش هر مرحله از تبدیل
class ConversionStep {
  final ConversionStepType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  ConversionStep({
    required this.type,
    required this.message,
    DateTime? timestamp,
    this.additionalData,
  }) : timestamp = timestamp ?? DateTime.now();

  /// متد برای ایجاد پیام مناسب برای هر نوع مرحله
  static String getMessageForStep(ConversionStepType type, {String? details}) {
    switch (type) {
      case ConversionStepType.started:
        return 'شروع فرآیند تبدیل NFA به DFA';
      case ConversionStepType.epsilonClosure:
        return 'محاسبه epsilon-closure${details != null ? ': $details' : ''}';
      case ConversionStepType.subsetConstruction:
        return 'اجرای subset construction algorithm${details != null ? ': $details' : ''}';
      case ConversionStepType.processingState:
        return 'پردازش حالت${details != null ? ' $details' : ''}';
      case ConversionStepType.finalizing:
        return 'نهایی‌سازی DFA و تعیین حالات نهایی';
      case ConversionStepType.completed:
        return 'تبدیل با موفقیت تکمیل شد';
    }
  }

  @override
  String toString() {
    return 'ConversionStep(type: $type, message: $message, timestamp: $timestamp)';
  }
}