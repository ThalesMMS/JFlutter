import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/nfa.dart';
import '../models/dfa.dart';
import '../models/state_model.dart';

/// کلاس ابزاری برای محاسبات مربوط به گراف
class GraphUtils {
  /// محاسبه فاصله بین دو نقطه
  static double distance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p1.dx - p2.dx, 2) + math.pow(p1.dy - p2.dy, 2));
  }

  /// محاسبه زاویه بین دو نقطه
  static double angle(Offset from, Offset to) {
    return math.atan2(to.dy - from.dy, to.dx - from.dx);
  }

  /// تبدیل درجه به رادیان
  static double degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }

  /// تبدیل رادیان به درجه
  static double radianToDegree(double radian) {
    return radian * 180 / math.pi;
  }

  /// محاسبه نقطه میانی دو نقطه
  static Offset midPoint(Offset p1, Offset p2) {
    return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
  }

  /// چرخاندن نقطه به دور مرکز
  static Offset rotatePoint(Offset point, Offset center, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    final translatedX = point.dx - center.dx;
    final translatedY = point.dy - center.dy;

    return Offset(
      translatedX * cos - translatedY * sin + center.dx,
      translatedX * sin + translatedY * cos + center.dy,
    );
  }

  /// محاسبه مستطیل محدود کننده مجموعه‌ای از نقاط
  static Rect getBoundingRect(List<Offset> points, {double padding = 0}) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// بررسی اینکه آیا نقطه درون دایره است یا نه
  static bool isPointInCircle(Offset point, Offset center, double radius) {
    return distance(point, center) <= radius;
  }

  /// محاسبه نقطه تقاطع خط با دایره
  static Offset? lineCircleIntersection(
    Offset lineStart,
    Offset lineEnd,
    Offset circleCenter,
    double circleRadius,
  ) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final fx = lineStart.dx - circleCenter.dx;
    final fy = lineStart.dy - circleCenter.dy;

    final a = dx * dx + dy * dy;
    final b = 2 * (fx * dx + fy * dy);
    final c = (fx * fx + fy * fy) - circleRadius * circleRadius;

    final discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return null;

    final discriminantSqrt = math.sqrt(discriminant);
    final t1 = (-b - discriminantSqrt) / (2 * a);
    final t2 = (-b + discriminantSqrt) / (2 * a);

    final t = (t1 >= 0 && t1 <= 1) ? t1 : t2;

    if (t < 0 || t > 1) return null;

    return Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
  }

  /// تولید رنگ تصادفی
  static Color generateRandomColor({double opacity = 1.0}) {
    final random = math.Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      opacity,
    );
  }

  /// تولید رنگ بر اساس رشته (هش)
  static Color colorFromString(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final r = (hash >> 16) & 0xFF;
    final g = (hash >> 8) & 0xFF;
    final b = hash & 0xFF;

    return Color.fromRGBO(r, g, b, 1.0);
  }

  /// محاسبه رنگ متضاد
  static Color getContrastColor(Color color) {
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// انیمیشن نرم بین دو مقدار
  static double lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  /// انیمیشن نرم بین دو نقطه
  static Offset lerpOffset(Offset start, Offset end, double t) {
    return Offset(lerp(start.dx, end.dx, t), lerp(start.dy, end.dy, t));
  }

  /// تابع easing برای انیمیشن‌های نرم
  static double easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// محاسبه نقاط کنترل برای منحنی بزیه
  static List<Offset> calculateBezierControlPoints(Offset start, Offset end) {
    final midPoint = GraphUtils.midPoint(start, end);
    final distance = GraphUtils.distance(start, end);
    final controlOffset = distance * 0.3;

    final perpendicular =
        Offset(-(end.dy - start.dy), end.dx - start.dx).normalize() *
        controlOffset;

    return [start + perpendicular, end + perpendicular];
  }
}

/// Extension برای کلاس Offset
extension OffsetExtensions on Offset {
  /// نرمال کردن بردار
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }

  /// چرخاندن بردار
  Offset rotate(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }

  /// محاسبه طول بردار
  double get length => math.sqrt(dx * dx + dy * dy);

  /// محاسبه زاویه بردار
  double get angle => math.atan2(dy, dx);

  /// محدود کردن بردار در محدوده مشخص
  Offset clamp(Rect bounds) {
    return Offset(
      dx.clamp(bounds.left, bounds.right),
      dy.clamp(bounds.top, bounds.bottom),
    );
  }
}

/// Extension برای کلاس Color
extension ColorExtensions on Color {
  /// تیره کردن رنگ
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }

  /// روشن کردن رنگ
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      alpha,
      red + ((255 - red) * amount).round(),
      green + ((255 - green) * amount).round(),
      blue + ((255 - blue) * amount).round(),
    );
  }

  /// تبدیل به رنگ hex
  String toHex() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// کلاس کمکی برای انیمیشن‌ها
class AnimationHelper {
  /// ایجاد انیمیشن ورود با افکت bounce
  static Animation<double> createBounceAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
  }

  /// ایجاد انیمیشن fade
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// ایجاد انیمیشن اسلاید
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  /// ایجاد انیمیشن چرخش
  static Animation<double> createRotationAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }
}

/// کلاس برای محاسبات مربوط به اتوماتا
class AutomatonUtils {
  /// استخراج تمام حالات از اتوماتا
  static List<String> extractStates(dynamic automaton) {
    if (automaton is NFA) {
      return automaton.states.toList()..sort();
    } else if (automaton is DFA) {
      return automaton.states.map((s) => automaton.getStateName(s)).toList()
        ..sort();
    }
    return [];
  }

  /// استخراج الفبا از اتوماتا
  static List<String> extractAlphabet(dynamic automaton) {
    if (automaton is NFA) {
      return automaton.alphabet.toList()..sort();
    } else if (automaton is DFA) {
      return automaton.alphabet.toList()..sort();
    }
    return [];
  }

  /// استخراج حالت شروع
  static String getStartState(dynamic automaton) {
    if (automaton is NFA) {
      return automaton.startState;
    } else if (automaton is DFA) {
      return automaton.startState != null
          ? automaton.getStateName(automaton.startState!)
          : '';
    }
    return '';
  }

  /// استخراج حالات پایانی
  static Set<String> getFinalStates(dynamic automaton) {
    if (automaton is NFA) {
      return automaton.finalStates;
    } else if (automaton is DFA) {
      return automaton.finalStates
          .map((s) => automaton.getStateName(s))
          .toSet();
    }
    return {};
  }

  /// بررسی معتبر بودن رشته ورودی
  static bool isValidInput(String input, List<String> alphabet) {
    for (int i = 0; i < input.length; i++) {
      if (!alphabet.contains(input[i])) {
        return false;
      }
    }
    return true;
  }

  static StateSet? findStateSetByName(DFA dfa, String name) {
    for (final stateSet in dfa.states) {
      if (dfa.getStateName(stateSet) == name) {
        return stateSet;
      }
    }
    return null;
  }

  /// شبیه‌سازی گام به گام NFA
  static List<String> simulateNFAStep(
    NFA nfa,
    List<String> currentStates,
    String symbol,
  ) {
    final newStates = <String>{};

    for (final state in currentStates) {
      final transitions = nfa.getTransitions(state, symbol);
      newStates.addAll(transitions);
    }

    return nfa.epsilonClosure(newStates).toList();
  }

  /// شبیه‌سازی گام به گام DFA
  static String? simulateDFAStep(
    DFA dfa,
    String currentStateName,
    String symbol,
  ) {
    final currentStateSet = findStateSetByName(dfa, currentStateName);
    if (currentStateSet == null) return null;

    final nextStateSet = dfa.getTransition(currentStateSet, symbol);

    return nextStateSet != null ? dfa.getStateName(nextStateSet) : null;
  }

  /// بررسی پذیرش رشته
  static bool isAccepted(dynamic automaton, List<String> currentStates) {
    final finalStates = getFinalStates(automaton);
    return currentStates.any((state) => finalStates.contains(state));
  }

  /// تولید گزارش شبیه‌سازی
  static String generateSimulationReport(
    String input,
    List<String> path,
    bool accepted,
    String automatonType,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== گزارش شبیه‌سازی ===');
    buffer.writeln('نوع اتوماتا: $automatonType');
    buffer.writeln('ورودی: $input');
    buffer.writeln('نتیجه: ${accepted ? "پذیرفته شده ✓" : "رد شده ✗"}');
    buffer.writeln('مسیر طی شده:');

    if (path.isNotEmpty) {
      buffer.write('  ${path.first}');
      for (int i = 0; i < input.length; i++) {
        if (i + 1 < path.length) {
          buffer.write(' --${input[i]}--> ${path[i + 1]}');
        }
      }
    }
    buffer.writeln('\n  حالت نهایی: ${path.isNotEmpty ? path.last : 'نامشخص'}');

    return buffer.toString();
  }
}

/// کلاس برای تنظیمات و تم‌های رنگی
class ThemeHelper {
  /// دریافت تم روشن
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      fontFamily: 'Vazir',
    );
  }

  /// دریافت تم تیره
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Vazir',
    );
  }

  /// پالت رنگی برای نمودارها
  static List<Color> getGraphColorPalette() {
    return [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.pink.shade400,
    ];
  }
}

/// کلاس کمکی برای validation
class ValidationHelper {
  /// بررسی معتبر بودن نام حالت
  static bool isValidStateName(String name) {
    if (name.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name);
  }

  /// بررسی معتبر بودن نماد
  static bool isValidSymbol(String symbol) {
    if (symbol.isEmpty) return false;
    // Allows epsilon symbol as well
    return symbol.length == 1 || symbol == NFA.epsilon;
  }

  /// بررسی معتبر بودن رشته ورودی
  static ValidationResult validateInput(String input, List<String> alphabet) {
    if (input.isEmpty) {
      // Empty string is often a valid input to check
      return ValidationResult(true, 'رشته ورودی خالی است (معتبر)');
    }

    for (int i = 0; i < input.length; i++) {
      if (!alphabet.contains(input[i])) {
        return ValidationResult(
          false,
          'نماد "${input[i]}" در موقعیت $i در الفبا وجود ندارد',
        );
      }
    }

    return ValidationResult(true, 'رشته ورودی معتبر است');
  }
}

/// کلاس نتیجه validation
class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult(this.isValid, this.message);
}

/// کلاس کمکی برای export و import
class FileHelper {
  /// تولید نام فایل با timestamp
  static String generateFileName(String prefix, String extension) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${prefix}_$timestamp.$extension';
  }

  /// تبدیل اتوماتا به JSON
  static Map<String, dynamic> automatonToJson(dynamic automaton) {
    if (automaton is NFA) {
      return automaton.toJson();
    } else if (automaton is DFA) {
      return automaton.toJson();
    }
    return {};
  }

  static Map<String, Map<String, List<String>>> _nfaTransitionsToJson(NFA nfa) {
    final transitions = <String, Map<String, List<String>>>{};

    for (final state in nfa.states) {
      transitions[state] = {};
      final allSymbols = nfa.alphabet.union({NFA.epsilon});

      for (final symbol in allSymbols) {
        final nextStates = nfa.getTransitions(state, symbol);
        if (nextStates.isNotEmpty) {
          transitions[state]![symbol] = nextStates.toList()..sort();
        }
      }
    }

    return transitions;
  }

  static Map<String, Map<String, String>> _dfaTransitionsToJson(DFA dfa) {
    final transitions = <String, Map<String, String>>{};
    final stateNames = AutomatonUtils.extractStates(dfa);

    for (final stateName in stateNames) {
      transitions[stateName] = {};
      final stateSet = AutomatonUtils.findStateSetByName(dfa, stateName);
      if (stateSet == null) continue;

      for (final symbol in dfa.alphabet) {
        final nextStateSet = dfa.getTransition(stateSet, symbol);
        if (nextStateSet != null) {
          transitions[stateName]![symbol] = dfa.getStateName(nextStateSet);
        }
      }
    }

    return transitions;
  }
}
