import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// کلاس توابع کمکی مرتبط با رابط کاربری
class UIHelpers {
  UIHelpers._();

  /// نمایش SnackBar با امکانات پیشرفته
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool showCloseIcon = false,
    VoidCallback? onVisible,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = StatusColors.success;
        textColor = Colors.white;
        icon = AppConstants.defaultIcons['success']!;
        break;
      case SnackBarType.error:
        backgroundColor = StatusColors.error;
        textColor = Colors.white;
        icon = AppConstants.defaultIcons['error']!;
        break;
      case SnackBarType.warning:
        backgroundColor = StatusColors.warning;
        textColor = Colors.black87;
        icon = AppConstants.defaultIcons['warning']!;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = StatusColors.info;
        textColor = Colors.white;
        icon = AppConstants.defaultIcons['info']!;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        action: action,
        showCloseIcon: showCloseIcon,
        closeIconColor: textColor,
        onVisible: onVisible,
      ),
    );
  }

  /// نمایش دیالوگ تایید پیشرفته
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'تایید',
    String cancelText = 'لغو',
    IconData? icon,
    Color? iconColor,
    bool isDangerous = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ??
                      (isDangerous ? StatusColors.error : StatusColors.info),
                  size: 28,
                ),
                const SizedBox(width: AppConstants.smallPadding),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppConstants.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: AppConstants.fontSizeMedium,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                onCancel?.call();
                Navigator.of(context).pop(false);
              },
              child: Text(
                cancelText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            ElevatedButton(
              onPressed: () {
                onConfirm?.call();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDangerous
                    ? StatusColors.error
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// نمایش دیالوگ اطلاعات
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'فهمیدم',
    IconData? icon,
    Color? iconColor,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? StatusColors.info,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.smallPadding),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppConstants.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: AppConstants.fontSizeMedium,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// نمایش bottom sheet سفارشی
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.largeBorderRadius),
            topRight: Radius.circular(AppConstants.largeBorderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle برای کشیدن
            Container(
              margin: const EdgeInsets.symmetric(
                  vertical: AppConstants.smallPadding),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  /// پنهان کردن کیبورد
  static void hideKeyboard(BuildContext context) {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// لرزش برای هپتیک فیدبک
  static void hapticFeedback({HapticType type = HapticType.light}) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// محاسبه اندازه متن
  static Size calculateTextSize({
    required String text,
    required TextStyle style,
    int maxLines = 1,
    double maxWidth = double.infinity,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: maxWidth);

    return textPainter.size;
  }

  /// تشخیص جهت زبان
  static TextDirection getTextDirection(String text) {
    // تشخیص ساده فارسی/عربی
    final persianArabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');
    return persianArabicRegex.hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// کپی کردن متن در کلیپ‌بورد
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// خواندن متن از کلیپ‌بورد
  static Future<String?> getFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    return clipboardData?.text;
  }
}

/// کلاس توابع کمکی مرتبط با اعتبارسنجی
class ValidationHelpers {
  ValidationHelpers._();

  /// بررسی null یا خالی بودن
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// اعتبارسنجی نام state
  static String? validateStateName(String? value) {
    if (isNullOrEmpty(value)) {
      return AppConstants.errorMessages['fieldRequired'];
    }

    final trimmedValue = value!.trim();

    if (trimmedValue.length < AppConstants.minStateNameLength) {
      return AppConstants.errorMessages['stateTooShort'];
    }

    if (trimmedValue.length > AppConstants.maxStateNameLength) {
      return AppConstants.errorMessages['stateTooLong'];
    }

    final RegExp validChars = RegExp(AppConstants.stateNamePattern);
    if (!validChars.hasMatch(trimmedValue)) {
      return AppConstants.errorMessages['invalidStateName'];
    }

    return null;
  }

  /// اعتبارسنجی نماد انتقال
  static String? validateTransitionSymbol(String? value) {
    if (isNullOrEmpty(value)) {
      return AppConstants.errorMessages['fieldRequired'];
    }

    final trimmedValue = value!.trim();
    final RegExp validSymbol = RegExp(AppConstants.symbolPattern);

    if (!validSymbol.hasMatch(trimmedValue)) {
      return 'نماد انتقال معتبر نیست';
    }

    return null;
  }

  /// اعتبارسنجی ایمیل (برای آینده)
  static String? validateEmail(String? value) {
    if (isNullOrEmpty(value)) {
      return AppConstants.errorMessages['fieldRequired'];
    }

    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(value!)) {
      return 'فرمت ایمیل صحیح نیست';
    }

    return null;
  }

  /// اعتبارسنجی شماره تلفن
  static String? validatePhoneNumber(String? value) {
    if (isNullOrEmpty(value)) {
      return AppConstants.errorMessages['fieldRequired'];
    }

    final RegExp phoneRegex = RegExp(r'^09\d{9}$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'شماره تلفن صحیح نیست';
    }

    return null;
  }

  /// اعتبارسنجی رمز عبور
  static String? validatePassword(
    String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = false,
  }) {
    if (isNullOrEmpty(value)) {
      return AppConstants.errorMessages['fieldRequired'];
    }

    if (value!.length < minLength) {
      return 'رمز عبور باید حداقل $minLength کاراکتر باشد';
    }

    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
      return 'رمز عبور باید شامل حروف بزرگ باشد';
    }

    if (requireLowercase && !RegExp(r'[a-z]').hasMatch(value)) {
      return 'رمز عبور باید شامل حروف کوچک باشد';
    }

    if (requireNumbers && !RegExp(r'\d').hasMatch(value)) {
      return 'رمز عبور باید شامل اعداد باشد';
    }

    if (requireSpecialChars &&
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'رمز عبور باید شامل کاراکترهای خاص باشد';
    }

    return null;
  }
}

/// کلاس توابع کمکی عمومی
class GeneralHelpers {
  GeneralHelpers._();

  /// تبدیل timestamp به تاریخ فارسی
  static String formatPersianDate(DateTime dateTime) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// تبدیل اعداد انگلیسی به فارسی
  static String toPersianNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  /// تبدیل اعداد فارسی به انگلیسی
  static String toEnglishNumbers(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < persian.length; i++) {
      result = result.replaceAll(persian[i], english[i]);
    }
    return result;
  }

  /// فرمت کردن اندازه فایل
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// ایجاد رنگ تصادفی
  static Color generateRandomColor() {
    return Color((0xFF000000 +
            (0xFFFFFF * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000))
        .round());
  }

  /// تاخیر async
  static Future<void> delay(Duration duration) async {
    await Future.delayed(duration);
  }

  /// دیباگ پرینت با فرمت
  static void debugPrint(String message, {String tag = 'DEBUG'}) {
    if (DebugConstants.enableLogging) {
      print('[$tag] ${DateTime.now()}: $message');
    }
  }

  /// محاسبه درصد
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// گرد کردن عدد به تعداد رقم مشخص
  static double roundToDecimalPlaces(double value, int decimalPlaces) {
    final multiplier = 10.0 * decimalPlaces;
    return (value * multiplier).round() / multiplier;
  }

  /// تولید UUID ساده (برای موارد غیر حیاتی)
  static String generateSimpleUUID() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (now * 1000 + (now % 1000)).toString();
    return random.substring(random.length - 8);
  }
}

/// انواع SnackBar
enum SnackBarType {
  info,
  success,
  warning,
  error,
}

/// انواع هپتیک فیدبک
enum HapticType {
  light,
  medium,
  heavy,
  selection,
}
