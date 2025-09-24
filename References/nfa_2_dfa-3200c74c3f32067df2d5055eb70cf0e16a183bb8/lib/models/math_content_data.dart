import 'dart:math' as math;
import 'extended_math_questions.dart';

class MathContentData {
  static const String lessonTitle = 'مقدمات ریاضی و مجموعه‌ها';
  static const String lessonSubtitle = 'تعریف زبان - گرامر - ماشین';
  static const int estimatedTime = 45; // minutes

  // محتوای اصلی درس
  static final Map<int, LessonContent> lessonSections = {
    0: LessonContent(
      id: 0,
      title: 'مقدمات و تعاریف',
      subtitle: 'آشنایی با مفاهیم پایه',
      difficulty: DifficultyLevel.easy,
      content: IntroductionContent(sectionId: 0),
    ),
    1: LessonContent(
      id: 1,
      title: 'خصوصیات مجموعه‌ها',
      subtitle: 'چهار خاصیت اساسی',
      difficulty: DifficultyLevel.easy,
      content: SetPropertiesContent(sectionId: 1),
    ),
    2: LessonContent(
      id: 2,
      title: 'زیرمجموعه و زیرمجموعه محض',
      subtitle: 'روابط بین مجموعه‌ها',
      difficulty: DifficultyLevel.medium,
      content: SubsetContent(sectionId: 2),
    ),
    3: LessonContent(
      id: 3,
      title: 'مجموعه توانی',
      subtitle: 'قدرت مجموعه‌ها',
      difficulty: DifficultyLevel.medium,
      content: PowerSetContent(sectionId: 3),
    ),
    4: LessonContent(
      id: 4,
      title: 'توابع',
      subtitle: 'نگاشت بین مجموعه‌ها',
      difficulty: DifficultyLevel.medium,
      content: FunctionContent(sectionId: 4),
    ),
    5: LessonContent(
      id: 5,
      title: 'مجموعه متناهی و نامتناهی',
      subtitle: 'طبقه‌بندی مجموعه‌ها',
      difficulty: DifficultyLevel.hard,
      content: FiniteInfiniteContent(sectionId: 5),
    ),
    6: LessonContent(
      id: 6,
      title: 'زبان، گرامر و ماشین',
      subtitle: 'مفاهیم علوم کامپیوتر',
      difficulty: DifficultyLevel.hard,
      content: LanguageGrammarContent(sectionId: 6),
    ),
  };
}

// انواع سطح دشواری
enum DifficultyLevel {
  easy('آسان', 1),
  medium('متوسط', 2),
  hard('سخت', 3);

  const DifficultyLevel(this.label, this.value);
  final String label;
  final int value;
}

// کلاس اصلی محتوای درس
class LessonContent {
  final int id;
  final String title;
  final String subtitle;
  final DifficultyLevel difficulty;
  final SectionContentBase content;

  LessonContent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.content,
  });
}

// کلاس پایه برای محتوای هر بخش
abstract class SectionContentBase {
  final int sectionId;
  SectionContentBase({required this.sectionId});

  List<ContentBlock> get theory;
  List<ExampleItem> get examples;
  List<QuizQuestion> get questions;
  List<String> get keyPoints;
  Map<String, String> get definitions;
}

// بلوک‌های محتوا
class ContentBlock {
  final String title;
  final String content;
  final ContentType type;
  final String? formula;
  final String? visualization;

  ContentBlock({
    required this.title,
    required this.content,
    required this.type,
    this.formula,
    this.visualization,
  });
}

enum ContentType {
  definition,
  explanation,
  formula,
  theorem,
  note,
  warning,
}

// مثال‌ها
class ExampleItem {
  final String title;
  final String problem;
  final String solution;
  final List<String> steps;
  final DifficultyLevel difficulty;

  ExampleItem({
    required this.title,
    required this.problem,
    required this.solution,
    required this.steps,
    required this.difficulty,
  });
}

// سوالات تست
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final DifficultyLevel difficulty;
  final QuestionType type;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.type,
  });
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInTheBlank,
  matching,
}

// محتوای بخش اول: مقدمات
class IntroductionContent extends SectionContentBase {
  IntroductionContent({required super.sectionId});

  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف مجموعه',
      content:
      'مجموعه یکی از مفاهیم بنیادی ریاضیات است. مجموعه را می‌توان به عنوان جمع‌آوری اشیاء مشخص تعریف کرد که این اشیاء را اعضای مجموعه می‌نامند.',
      type: ContentType.definition,
    ),
    ContentBlock(
      title: 'نحوه نمایش مجموعه‌ها',
      content:
      'مجموعه‌ها را می‌توان به سه روش نمایش داد:\n• روش فهرست‌سازی\n• روش بیان خاصیت\n• نمودار ون',
      type: ContentType.explanation,
    ),
    ContentBlock(
      title: 'مجموعه خالی',
      content:
      'مجموعه‌ای که هیچ عضوی نداشته باشد، مجموعه خالی نامیده می‌شود و با ∅ یا {} نمایش داده می‌شود.',
      type: ContentType.definition,
      formula: '∅ = {}',
    ),
    ContentBlock(
      title: 'عضویت و عدم عضویت',
      content:
      'برای نشان دادن اینکه عنصر a عضو مجموعه A است از نماد ∈ استفاده می‌کنیم. برای عدم عضویت از نماد ∉ استفاده می‌شود.',
      type: ContentType.explanation,
      formula: 'a ∈ A یا a ∉ A',
    ),
  ];

  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'نمایش مجموعه با روش فهرست‌سازی',
      problem:
      'مجموعه اعداد زوج کمتر از 10 را با روش فهرست‌سازی نمایش دهید.',
      solution: 'A = {0, 2, 4, 6, 8}',
      steps: [
        'اعداد زوج کمتر از 10 را شناسایی کنیم',
        'آنها را در داخل {} قرار دهیم',
        'ترتیب آنها اهمیت ندارد'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'نمایش مجموعه با روش خاصیت',
      problem:
      'مجموعه اعداد طبیعی بزرگتر از 5 را با روش خاصیت نمایش دهید.',
      solution: 'B = {x ∈ ℕ | x > 5}',
      steps: [
        'متغیر x را انتخاب کنیم',
        'مجموعه مرجع (اعداد طبیعی) را مشخص کنیم',
        'شرط (بزرگتر از 5) را بنویسیم'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'تشخیص عضویت',
      problem: 'A = {1, 3, 5, 7} باشد. آیا 4 ∈ A؟',
      solution: 'خیر، 4 ∉ A',
      steps: [
        'اعضای مجموعه A را بررسی کنیم',
        '4 در فهرست اعضا وجود ندارد',
        'پس 4 ∉ A'
      ],
      difficulty: DifficultyLevel.easy,
    ),
  ];

  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'کدام روش برای نمایش مجموعه {2, 4, 6, 8, 10} مناسب‌تر است؟',
        options: ['روش فهرست‌سازی', 'روش خاصیت', 'نمودار ون', 'هیچ‌کدام'],
        correctAnswer: 0,
        explanation:
        'چون تعداد اعضا محدود و مشخص است، روش فهرست‌سازی بهترین انتخاب است.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'مجموعه خالی دارای هیچ عضوی نیست.',
        options: ['درست', 'نادرست'],
        correctAnswer: 0,
        explanation: 'تعریف مجموعه خالی همین است که هیچ عضوی ندارد.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'اگر A = {x | x² = 4} باشد، کدام گزینه درست است؟',
        options: ['A = {2}', 'A = {-2}', 'A = {2, -2}', 'A = {4}'],
        correctAnswer: 2,
        explanation: 'معادله x² = 4 دو جواب دارد: x = 2 و x = -2',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس به EnhancedQuizQuestions تغییر یافت
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedIntroductionQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'مجموعه مجموعه‌ای از اشیاء مشخص است',
    'سه روش نمایش: فهرست‌سازی، خاصیت، نمودار ون',
    'مجموعه خالی با ∅ نمایش داده می‌شود',
    'a ∈ A یعنی a عضو A است',
    'ترتیب و تکرار اعضا در مجموعه اهمیت ندارد'
  ];

  @override
  Map<String, String> get definitions => {
    'مجموعه': 'جمع‌آوری از اشیاء مشخص که اعضا نامیده می‌شوند',
    'عضو': 'هر شیء که جزء یک مجموعه باشد',
    'مجموعه خالی': 'مجموعه‌ای که هیچ عضوی ندارد',
    'عضویت': 'رابطه‌ای که نشان می‌دهد عنصری جزء مجموعه است',
  };
}

// محتوای بخش دوم: خصوصیات مجموعه‌ها
class SetPropertiesContent extends SectionContentBase {
  SetPropertiesContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'خاصیت اول: اصل دوگانگی',
      content:
      'برای هر عنصر x و مجموعه A، یا x ∈ A یا x ∉ A. هیچ حالت سومی وجود ندارد.',
      type: ContentType.theorem,
      formula: 'x ∈ A ∨ x ∉ A',
    ),
    ContentBlock(
      title: 'خاصیت دوم: عدم اهمیت ترتیب',
      content:
      'ترتیب اعضا در یک مجموعه اهمیت ندارد. {1, 2, 3} و {3, 1, 2} یکسان هستند.',
      type: ContentType.explanation,
      formula: '{a, b, c} = {c, a, b} = {b, c, a}',
    ),
    ContentBlock(
      title: 'خاصیت سوم: یکتایی اعضا',
      content: 'تکرار اعضا در مجموعه معنی ندارد. هر عضو یا هست یا نیست.',
      type: ContentType.explanation,
      formula: '{a, a, b} = {a, b}',
    ),
    ContentBlock(
      title: 'خاصیت چهارم: تعین‌بودگی',
      content:
      'برای هر مجموعه باید کاملاً مشخص باشد که کدام عناصر عضو آن هستند و کدام نیستند.',
      type: ContentType.explanation,
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'اصل دوگانگی',
      problem: 'A = {1, 3, 5} باشد. عدد 2 چه وضعیتی نسبت به A دارد؟',
      solution: '2 ∉ A (عضو نیست)',
      steps: [
        'اعضای A را بررسی می‌کنیم: 1, 3, 5',
        '2 در این فهرست نیست',
        'پس 2 ∉ A'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'عدم اهمیت ترتیب',
      problem: 'آیا {a, b, c} = {c, a, b}؟',
      solution: 'بله، این دو مجموعه برابرند',
      steps: [
        'هر دو مجموعه شامل عناصر a, b, c هستند',
        'ترتیب اعضا در تعریف مجموعه اهمیت ندارد',
        'پس دو مجموعه برابرند'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'یکتایی اعضا',
      problem: '{1, 2, 2, 3, 1} را ساده کنید.',
      solution: '{1, 2, 3}',
      steps: [
        'عناصر تکراری را حذف می‌کنیم',
        '1 و 2 تکرار شده‌اند',
        'مجموعه نهایی: {1, 2, 3}'
      ],
      difficulty: DifficultyLevel.easy,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'کدام خاصیت مجموعه‌ها اشتباه است؟',
        options: [
          'ترتیب اعضا مهم نیست',
          'تکرار اعضا مجاز نیست',
          'ترتیب اعضا باید حفظ شود',
          'هر عضو یا هست یا نیست'
        ],
        correctAnswer: 2,
        explanation: 'ترتیب اعضا در مجموعه اهمیت ندارد و نیازی به حفظ آن نیست.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'مجموعه {x, x, y, z} چند عضو دارد؟',
        options: ['2', '3', '4', '1'],
        correctAnswer: 1,
        explanation: 'تکرار x حذف می‌شود، پس اعضا عبارتند از: x, y, z (سه عضو)',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedSetPropertiesQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'اصل دوگانگی: هر عنصر یا عضو است یا نیست',
    'ترتیب اعضا در مجموعه اهمیت ندارد',
    'تکرار اعضا معنی ندارد',
    'مجموعه‌ها باید کاملاً تعین باشند'
  ];
  @override
  Map<String, String> get definitions => {
    'اصل دوگانگی': 'هر عنصر نسبت به مجموعه یا عضو است یا غیرعضو',
    'یکتایی': 'هر عضو در مجموعه حداکثر یک بار در نظر گرفته می‌شود',
    'تعین‌بودگی': 'برای هر عنصر مشخص است که آیا عضو مجموعه است یا خیر',
  };
}

// محتوای بخش سوم: زیرمجموعه
class SubsetContent extends SectionContentBase {
  SubsetContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف زیرمجموعه',
      content: 'مجموعه A زیرمجموعه B است اگر هر عضو A عضو B نیز باشد.',
      type: ContentType.definition,
      formula: 'A ⊆ B ⟺ ∀x(x ∈ A → x ∈ B)',
    ),
    ContentBlock(
      title: 'تعریف زیرمجموعه محض',
      content: 'مجموعه A زیرمجموعه محض B است اگر A ⊆ B و A ≠ B باشد.',
      type: ContentType.definition,
      formula: 'A ⊂ B ⟺ (A ⊆ B) ∧ (A ≠ B)',
    ),
    ContentBlock(
      title: 'خصوصیات زیرمجموعه',
      content:
      '• هر مجموعه زیرمجموعه خودش است\n• مجموعه خالی زیرمجموعه هر مجموعه‌ای است\n• رابطه زیرمجموعه متعدی است',
      type: ContentType.theorem,
    ),
    ContentBlock(
      title: 'تساوی مجموعه‌ها',
      content:
      'دو مجموعه برابرند اگر و تنها اگر هر کدام زیرمجموعه دیگری باشند.',
      type: ContentType.theorem,
      formula: 'A = B ⟺ (A ⊆ B) ∧ (B ⊆ A)',
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'تشخیص زیرمجموعه',
      problem: 'A = {1, 2} و B = {1, 2, 3, 4} باشند. آیا A ⊆ B؟',
      solution: 'بله، A ⊆ B',
      steps: [
        'هر عضو A را بررسی می‌کنیم',
        '1 ∈ A و 1 ∈ B ✓',
        '2 ∈ A و 2 ∈ B ✓',
        'پس A ⊆ B'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'زیرمجموعه محض',
      problem: 'A = {a, b} و B = {a, b, c} باشند. نوع رابطه بین A و B چیست؟',
      solution: 'A ⊂ B (زیرمجموعه محض)',
      steps: [
        'A ⊆ B را بررسی می‌کنیم: درست',
        'A = B را بررسی می‌کنیم: نادرست (c ∈ B اما c ∉ A)',
        'پس A ⊂ B'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'مجموعه خالی',
      problem: 'آیا ∅ ⊆ {1, 2, 3}؟',
      solution: 'بله، مجموعه خالی زیرمجموعه هر مجموعه‌ای است',
      steps: [
        'مجموعه خالی هیچ عضوی ندارد',
        'شرط زیرمجموعه: هر عضو A باید عضو B باشد',
        'چون ∅ عضوی ندارد، شرط به طور خودکار برقرار است'
      ],
      difficulty: DifficultyLevel.hard,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'اگر A = {1, 3} و B = {1, 2, 3, 4} باشد، کدام گزینه درست است؟',
        options: ['A = B', 'A ⊂ B', 'B ⊂ A', 'A و B مجزا هستند'],
        correctAnswer: 1,
        explanation: 'A زیرمجموعه محض B است چون A ⊆ B اما A ≠ B',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'هر مجموعه زیرمجموعه خودش است.',
        options: ['درست', 'نادرست'],
        correctAnswer: 0,
        explanation: 'این یکی از خصوصیات اساسی رابطه زیرمجموعه است: A ⊆ A',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'چند زیرمجموعه از {a, b} وجود دارد؟',
        options: ['2', '3', '4', '5'],
        correctAnswer: 2,
        explanation: 'زیرمجموعه‌ها: ∅, {a}, {b}, {a,b} - در مجموع 4 تا',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedSubsetQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'A ⊆ B: هر عضو A عضو B نیز است',
    'A ⊂ B: A زیرمجموعه محض B است',
    'مجموعه خالی زیرمجموعه همه مجموعه‌هاست',
    'هر مجموعه زیرمجموعه خودش است',
    'A = B وقتی A ⊆ B و B ⊆ A'
  ];
  @override
  Map<String, String> get definitions => {
    'زیرمجموعه': 'مجموعه A زیرمجموعه B است اگر هر عضو A عضو B باشد',
    'زیرمجموعه محض': 'A زیرمجموعه محض B است اگر A ⊆ B و A ≠ B',
    'تساوی مجموعه‌ها': 'دو مجموعه برابرند اگر دارای اعضای یکسانی باشند',
  };
}

// محتوای بخش چهارم: مجموعه توانی
class PowerSetContent extends SectionContentBase {
  PowerSetContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف مجموعه توانی',
      content: 'مجموعه توانی مجموعه A، مجموعه‌ای از تمام زیرمجموعه‌های A است.',
      type: ContentType.definition,
      formula: 'P(A) = {S | S ⊆ A}',
    ),
    ContentBlock(
      title: 'اندازه مجموعه توانی',
      content:
      'اگر مجموعه A دارای n عضو باشد، آنگاه P(A) دارای 2ⁿ عضو است.',
      type: ContentType.theorem,
      formula: '|A| = n ⟹ |P(A)| = 2ⁿ',
    ),
    ContentBlock(
      title: 'خصوصیات مجموعه توانی',
      content:
      '• ∅ همیشه عضو P(A) است\n• A همیشه عضو P(A) است\n• اگر A ⊆ B آنگاه P(A) ⊆ P(B)',
      type: ContentType.theorem,
    ),
    ContentBlock(
      title: 'محاسبه سریع',
      content:
      'برای پیدا کردن تمام زیرمجموعه‌ها می‌توان از نمایش دودویی استفاده کرد.',
      type: ContentType.note,
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'محاسبه P(A) برای مجموعه کوچک',
      problem: 'اگر A = {1, 2} باشد، P(A) را بیابید.',
      solution: 'P(A) = {∅, {1}, {2}, {1,2}}',
      steps: [
        'تمام زیرمجموعه‌های A را می‌یابیم',
        'زیرمجموعه خالی: ∅',
        'زیرمجموعه‌های تک‌عضوی: {1}, {2}',
        'خود A: {1,2}'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'اندازه مجموعه توانی',
      problem: 'اگر |A| = 3 باشد، |P(A)| چقدر است؟',
      solution: '|P(A)| = 2³ = 8',
      steps: [
        'از فرمول |P(A)| = 2ⁿ استفاده می‌کنیم',
        'n = 3',
        '2³ = 8'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'مجموعه توانی مجموعه سه‌عضوی',
      problem: 'A = {a, b, c} باشد. P(A) را بنویسید.',
      solution:
      'P(A) = {∅, {a}, {b}, {c}, {a,b}, {a,c}, {b,c}, {a,b,c}}',
      steps: [
        'زیرمجموعه خالی: ∅',
        'زیرمجموعه‌های یک‌عضوی: {a}, {b}, {c}',
        'زیرمجموعه‌های دوعضوی: {a,b}, {a,c}, {b,c}',
        'خود A: {a,b,c}'
      ],
      difficulty: DifficultyLevel.medium,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'اگر |A| = 4 باشد، |P(A)| کدام است؟',
        options: ['8', '12', '16', '24'],
        correctAnswer: 2,
        explanation: '|P(A)| = 2⁴ = 16',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'مجموعه خالی همیشه عضو هر مجموعه توانی است.',
        options: ['درست', 'نادرست'],
        correctAnswer: 0,
        explanation:
        'مجموعه خالی زیرمجموعه هر مجموعه‌ای است، پس همیشه در مجموعه توانی قرار دارد.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'اگر A = {x} باشد، P(A) کدام است؟',
        options: ['{∅, x}', '{∅, {x}}', '{{x}}', '{x}'],
        correctAnswer: 1,
        explanation: 'P(A) شامل مجموعه خالی و خود مجموعه A است: {∅, {x}}',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedPowerSetQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'P(A) = مجموعه تمام زیرمجموعه‌های A',
    '|P(A)| = 2^|A|',
    '∅ و A همیشه عضو P(A) هستند',
    'برای محاسبه می‌توان از روش دودویی استفاده کرد'
  ];
  @override
  Map<String, String> get definitions => {
    'مجموعه توانی': 'مجموعه تمام زیرمجموعه‌های یک مجموعه',
    'اندازه مجموعه توانی':
    'تعداد اعضای مجموعه توانی برابر 2 به توان تعداد اعضای مجموعه اصلی',
  };
}

// محتوای بخش پنجم: توابع
class FunctionContent extends SectionContentBase {
  FunctionContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف تابع',
      content:
      'تابع f از مجموعه A به مجموعه B قاعده‌ای است که به هر عضو A دقیقاً یک عضو از B نسبت می‌دهد.',
      type: ContentType.definition,
      formula: 'f: A → B',
    ),
    ContentBlock(
      title: 'اجزای تابع',
      content:
      '• دامنه (Domain): مجموعه A\n• مدامنه (Codomain): مجموعه B\n• برد (Range/Image): تصاویر واقعی در B',
      type: ContentType.explanation,
    ),
    ContentBlock(
      title: 'انواع توابع',
      content:
      '• تابع یکی (Injective): f(x₁) = f(x₂) ⟹ x₁ = x₂\n• تابع پوشا (Surjective): ∀y ∈ B, ∃x ∈ A: f(x) = y\n• تابع دوسویه (Bijective): هم یکی و هم پوشا',
      type: ContentType.theorem,
    ),
    ContentBlock(
      title: 'تابع مرکب',
      content:
      'اگر f: A → B و g: B → C باشند، آنگاه g∘f: A → C تابع مرکب است.',
      type: ContentType.definition,
      formula: '(g∘f)(x) = g(f(x))',
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'تابع ساده',
      problem:
      'f: {1,2,3} → {a,b,c} با f(1)=a, f(2)=b, f(3)=c تعریف شده است. نوع این تابع چیست؟',
      solution: 'تابع دوسویه (یکی و پوشا)',
      steps: [
        'بررسی یکی بودن: هر دو عنصر متفاوت تصویر متفاوت دارند ✓',
        'بررسی پوشا بودن: هر عنصر مدامنه تصویر دارد ✓',
        'پس تابع دوسویه است'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'تابع غیریکی',
      problem:
      'f: {1,2,3,4} → {a,b} با f(1)=f(2)=a و f(3)=f(4)=b تعریف شده است. چرا این تابع یکی نیست؟',
      solution: 'چون f(1) = f(2) = a اما 1 ≠ 2',
      steps: [
        'دو عنصر متفاوت 1 و 2 را در نظر می‌گیریم',
        'f(1) = a و f(2) = a',
        'پس f(1) = f(2) اما 1 ≠ 2، که نقض یکی است'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'ترکیب توابع',
      problem: 'f(x) = 2x و g(x) = x + 1 باشند. (g∘f)(3) را محاسبه کنید.',
      solution: '(g∘f)(3) = 7',
      steps: [
        'ابتدا f(3) را محاسبه می‌کنیم: f(3) = 2×3 = 6',
        'سپس g(6) را محاسبه می‌کنیم: g(6) = 6 + 1 = 7',
        'پس (g∘f)(3) = 7'
      ],
      difficulty: DifficultyLevel.hard,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'کدام شرط برای تعریف تابع ضروری است؟',
        options: [
          'هر عنصر دامنه دقیقاً یک تصویر داشته باشد',
          'هر عنصر مدامنه حداقل یک تصویر داشته باشد',
          'تابع باید یکی باشد',
          'تابع باید پوشا باشد'
        ],
        correctAnswer: 0,
        explanation:
        'تعریف اساسی تابع این است که هر عنصر دامنه دقیقاً یک تصویر داشته باشد.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'تابع یکی تابعی است که عناصر متفاوت دامنه تصاویر متفاوت داشته باشند.',
        options: ['درست', 'نادرست'],
        correctAnswer: 0,
        explanation: 'این دقیقاً تعریف تابع یکی (injective) است.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'اگر f: A → B یکی و |A| = |B| باشد، آنگاه f چه نوع تابعی است؟',
        options: ['فقط یکی', 'فقط پوشا', 'دوسویه', 'نمی‌توان تشخیص داد'],
        correctAnswer: 2,
        explanation:
        'وقتی تابع یکی است و |A| = |B|، حتماً پوشا نیز هست، پس دوسویه است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedFunctionQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'تابع: f: A → B هر عنصر A دقیقاً یک تصویر در B دارد',
    'دامنه: مجموعه ورودی‌ها',
    'مدامنه: مجموعه هدف',
    'برد: تصاویر واقعی',
    'یکی: تصاویر متفاوت برای ورودی‌های متفاوت',
    'پوشا: هر عنصر مدامنه حداقل یک اصل دارد'
  ];
  @override
  Map<String, String> get definitions => {
    'تابع': 'قاعده‌ای که به هر عنصر دامنه دقیقاً یک عنصر مدامنه نسبت می‌دهد',
    'تابع یکی': 'تابعی که عناصر متفاوت دامنه تصاویر متفاوت دارند',
    'تابع پوشا': 'تابعی که هر عنصر مدامنه حداقل یک اصل دارد',
    'تابع دوسویه': 'تابعی که هم یکی و هم پوشا است',
  };
}

// محتوای بخش ششم: مجموعه‌های متناهی و نامتناهی
class FiniteInfiniteContent extends SectionContentBase {
  FiniteInfiniteContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف مجموعه متناهی',
      content:
      'مجموعه‌ای که تعداد اعضایش قابل شمارش و محدود باشد، متناهی نامیده می‌شود.',
      type: ContentType.definition,
      formula: '|A| = n ∈ ℕ',
    ),
    ContentBlock(
      title: 'تعریف مجموعه نامتناهی',
      content: 'مجموعه‌ای که تعداد اعضایش نامحدود باشد، نامتناهی نامیده می‌شود.',
      type: ContentType.definition,
    ),
    ContentBlock(
      title: 'انواع نامتناهی',
      content:
      '• قابل شمارش (Countably Infinite): مانند ℕ\n• غیرقابل شمارش (Uncountably Infinite): مانند ℝ',
      type: ContentType.explanation,
    ),
    ContentBlock(
      title: 'خصوصیات مهم',
      content:
      '• زیرمجموعه مجموعه متناهی، متناهی است\n• اتحاد متناهی از مجموعه‌های متناهی، متناهی است\n• حاصل‌ضرب دکارتی دو مجموعه متناهی، متناهی است',
      type: ContentType.theorem,
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'مجموعه متناهی',
      problem: 'کدام مجموعه‌ها متناهی هستند؟',
      solution: '{1,2,3}, مجموعه دانشجویان دانشگاه, حروف الفبا',
      steps: [
        'مجموعه‌هایی که می‌توان اعضایشان را شمرد',
        'تعداد مشخص و محدود دارند',
        'مثال‌ها: {1,2,3} دارای 3 عضو'
      ],
      difficulty: DifficultyLevel.easy,
    ),
    ExampleItem(
      title: 'مجموعه نامتناهی قابل شمارش',
      problem: 'اعداد طبیعی ℕ = {1,2,3,...} چه نوع مجموعه‌ای است؟',
      solution: 'نامتناهی قابل شمارش',
      steps: [
        'تعداد اعضا نامحدود است',
        'اما می‌توان آنها را با اعداد طبیعی شماره‌گذاری کرد',
        'پس قابل شمارش است'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'مجموعه نامتناهی غیرقابل شمارش',
      problem: 'اعداد حقیقی ℝ چه نوع مجموعه‌ای است؟',
      solution: 'نامتناهی غیرقابل شمارش',
      steps: [
        'تعداد اعضا نامحدود است',
        'نمی‌توان آنها را با اعداد طبیعی شماره‌گذاری کرد',
        'پس غیرقابل شمارش است'
      ],
      difficulty: DifficultyLevel.hard,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'کدام مجموعه متناهی است؟',
        options: ['اعداد طبیعی', 'اعداد حقیقی', 'حروف الفبای فارسی', 'اعداد گویا'],
        correctAnswer: 2,
        explanation: 'حروف الفبای فارسی تعداد محدودی دارند، پس متناهی هستند.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'مجموعه اعداد زوج نامتناهی است.',
        options: ['درست', 'نادرست'],
        correctAnswer: 0,
        explanation: 'اعداد زوج {2, 4, 6, 8, ...} تعداد نامحدودی دارند.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'اگر A متناهی و B ⊆ A باشد، آنگاه B:',
        options: [
          'حتماً متناهی است',
          'حتماً نامتناهی است',
          'ممکن است متناهی یا نامتناهی باشد',
          'هیچ‌کدام'
        ],
        correctAnswer: 0,
        explanation: 'زیرمجموعه هر مجموعه متناهی حتماً متناهی است.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedFiniteInfiniteQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'متناهی: تعداد اعضا محدود و قابل شمارش',
    'نامتناهی: تعداد اعضا نامحدود',
    'قابل شمارش: قابل شماره‌گذاری با اعداد طبیعی',
    'غیرقابل شمارش: غیرقابل شماره‌گذاری',
    'زیرمجموعه مجموعه متناهی متناهی است'
  ];
  @override
  Map<String, String> get definitions => {
    'مجموعه متناهی': 'مجموعه‌ای با تعداد اعضای محدود و قابل شمارش',
    'مجموعه نامتناهی': 'مجموعه‌ای با تعداد اعضای نامحدود',
    'قابل شمارش': 'قابل برقراری تناظر یکی با اعداد طبیعی',
    'غیرقابل شمارش': 'غیرقابل برقراری تناظر یکی با اعداد طبیعی',
  };
}

// محتوای بخش هفتم: زبان، گرامر و ماشین
class LanguageGrammarContent extends SectionContentBase {
  LanguageGrammarContent({required super.sectionId});
  @override
  List<ContentBlock> get theory => [
    ContentBlock(
      title: 'تعریف الفبا',
      content:
      'الفبا مجموعه متناهی و غیرخالی از نمادهاست که با Σ نمایش داده می‌شود.',
      type: ContentType.definition,
      formula: 'Σ = {a₁, a₂, ..., aₙ}',
    ),
    ContentBlock(
      title: 'تعریف رشته',
      content:
      'رشته دنباله متناهی از نمادهای یک الفباست. رشته خالی با ε نمایش داده می‌شود.',
      type: ContentType.definition,
    ),
    ContentBlock(
      title: 'تعریف زبان',
      content: 'زبان زیرمجموعه‌ای از تمام رشته‌های ممکن روی یک الفباست.',
      type: ContentType.definition,
      formula: 'L ⊆ Σ*',
    ),
    ContentBlock(
      title: 'تعریف گرامر',
      content:
      'گرامر چهارتایی مرتب G = (V, T, P, S) است که:\n• V: متغیرها\n• T: نمادهای پایانی\n• P: قوانین تولید\n• S: نماد شروع',
      type: ContentType.definition,
    ),
    ContentBlock(
      title: 'انواع گرامر (طبقه‌بندی چامسکی)',
      content:
      '• نوع 0: گرامر عمومی\n• نوع 1: گرامر وابسته به متن\n• نوع 2: گرامر مستقل از متن\n• نوع 3: گرامر منظم',
      type: ContentType.theorem,
    ),
    ContentBlock(
      title: 'ماشین‌های محاسباتی',
      content:
      '• ماشین تورینگ: برای زبان‌های نوع 0\n• اتوماتای خطی محدود: برای زبان‌های نوع 1\n• اتوماتای پشته‌ای: برای زبان‌های نوع 2\n• اتوماتای متناهی: برای زبان‌های نوع 3',
      type: ContentType.explanation,
    ),
  ];
  @override
  List<ExampleItem> get examples => [
    ExampleItem(
      title: 'الفبا و رشته',
      problem: 'Σ = {0, 1} باشد. چند رشته طول 3 وجود دارد؟',
      solution: '8 رشته: 000, 001, 010, 011, 100, 101, 110, 111',
      steps: [
        'برای هر موقعیت 2 انتخاب داریم (0 یا 1)',
        'برای 3 موقعیت: 2³ = 8 رشته',
        'همه حالات ممکن را فهرست می‌کنیم'
      ],
      difficulty: DifficultyLevel.medium,
    ),
    ExampleItem(
      title: 'زبان ساده',
      problem: 'L = {0ⁿ1ⁿ | n ≥ 1} روی Σ = {0, 1} چه زبانی است؟',
      solution:
      'زبان رشته‌هایی که تعداد مساوی 0 و 1 دارند و ابتدا 0ها سپس 1ها می‌آیند',
      steps: [
        'n = 1: رشته 01',
        'n = 2: رشته 0011',
        'n = 3: رشته 000111',
        'الگو: تعداد برابر 0 و 1'
      ],
      difficulty: DifficultyLevel.hard,
    ),
    ExampleItem(
      title: 'گرامر ساده',
      problem: 'گرامری برای تولید زبان {aⁿbⁿ | n ≥ 1} بنویسید.',
      solution: 'S → aSb | ab',
      steps: [
        'نماد شروع: S',
        'قانون بازگشتی: S → aSb',
        'قانون پایانی: S → ab',
        'این گرامر رشته‌های aⁿbⁿ تولید می‌کند'
      ],
      difficulty: DifficultyLevel.hard,
    ),
  ];
  @override
  List<QuizQuestion> get questions {
    final originalQuestions = [
      QuizQuestion(
        question: 'اگر |Σ| = k باشد، چند رشته طول n وجود دارد؟',
        options: ['kⁿ', 'nᵏ', 'k + n', 'k × n'],
        correctAnswer: 0,
        explanation: 'برای هر موقعیت k انتخاب داریم، پس برای n موقعیت kⁿ رشته.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'رشته خالی عضو هر زبانی است.',
        options: ['درست', 'نادرست'],
        correctAnswer: 1,
        explanation:
        'رشته خالی فقط اگر صراحتاً در تعریف زبان گنجانده شده باشد، عضو آن زبان است.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.trueFalse,
      ),
      QuizQuestion(
        question: 'گرامر منظم (نوع 3) با کدام ماشین متناظر است؟',
        options: [
          'ماشین تورینگ',
          'اتوماتای پشته‌ای',
          'اتوماتای متناهی',
          'اتوماتای خطی محدود'
        ],
        correctAnswer: 2,
        explanation: 'گرامر منظم (نوع 3) با اتوماتای متناهی متناظر است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
    // FIX: نام کلاس و متد اصلاح شد
    return [
      ...originalQuestions,
      ...EnhancedQuizQuestions.getAdvancedLanguageGrammarQuestions()
    ];
  }

  @override
  List<String> get keyPoints => [
    'الفبا: مجموعه متناهی از نمادها',
    'رشته: دنباله متناهی از نمادهای الفبا',
    'زبان: مجموعه‌ای از رشته‌ها',
    'گرامر: چهارتایی (V, T, P, S)',
    'طبقه‌بندی چامسکی: 4 نوع گرامر',
    'هر نوع گرامر با ماشین خاصی متناظر است'
  ];
  @override
  Map<String, String> get definitions => {
    'الفبا': 'مجموعه متناهی و غیرخالی از نمادها',
    'رشته': 'دنباله متناهی از نمادهای یک الفبا',
    'زبان': 'مجموعه‌ای از رشته‌ها روی یک الفبا',
    'گرامر': 'سیستم قوانین برای تولید رشته‌های یک زبان',
    'ماشین محاسباتی': 'مدل ریاضی برای پردازش رشته‌ها',
  };
}

// کلاس‌های کمکی برای مدیریت پیشرفت و آمار
class ProgressTracker {
  final Map<int, bool> _completedSections = {};
  final Map<int, List<int>> _correctAnswers = {};
  final Map<int, int> _timeSpent = {}; // minutes

  bool isSectionCompleted(int sectionId) {
    return _completedSections[sectionId] ?? false;
  }

  void markSectionCompleted(int sectionId) {
    _completedSections[sectionId] = true;
  }

  void addCorrectAnswer(int sectionId, int questionId) {
    _correctAnswers.putIfAbsent(sectionId, () => []);
    if (!_correctAnswers[sectionId]!.contains(questionId)) {
      _correctAnswers[sectionId]!.add(questionId);
    }
  }

  double getSectionScore(int sectionId) {
    final content = MathContentData.lessonSections[sectionId]?.content;
    if (content == null) return 0.0;

    final totalQuestions = content.questions.length;
    if (totalQuestions == 0) return 1.0;

    final correctCount = _correctAnswers[sectionId]?.length ?? 0;
    return correctCount / totalQuestions;
  }

  double getOverallProgress() {
    final totalSections = MathContentData.lessonSections.length;
    if (totalSections == 0) return 0.0;

    final completedCount = _completedSections.values.where((v) => v).length;
    return completedCount / totalSections;
  }

  int getTotalTimeSpent() {
    return _timeSpent.values.fold(0, (sum, time) => sum + time);
  }

  void addTimeSpent(int sectionId, int minutes) {
    _timeSpent[sectionId] = (_timeSpent[sectionId] ?? 0) + minutes;
  }

  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    // آمار کلی
    stats['totalSections'] = MathContentData.lessonSections.length;
    stats['completedSections'] =
        _completedSections.values.where((v) => v).length;
    stats['overallProgress'] = getOverallProgress();
    stats['totalTimeSpent'] = getTotalTimeSpent();

    // آمار هر بخش
    stats['sectionStats'] = <int, Map<String, dynamic>>{};
    for (var sectionId in MathContentData.lessonSections.keys) {
      stats['sectionStats'][sectionId] = {
        'completed': isSectionCompleted(sectionId),
        'score': getSectionScore(sectionId),
        'timeSpent': _timeSpent[sectionId] ?? 0,
        'difficulty':
        MathContentData.lessonSections[sectionId]?.difficulty.label,
      };
    }

    return stats;
  }
}

// کلاس برای مدیریت تنظیمات یادگیری
class LearningSettings {
  bool showHints = true;
  bool autoAdvance = false;
  DifficultyLevel preferredDifficulty = DifficultyLevel.medium;
  bool enableSound = true;
  bool enableHaptic = true;
  int studyTime = 25; // minutes for pomodoro

  Map<String, dynamic> toJson() {
    return {
      'showHints': showHints,
      'autoAdvance': autoAdvance,
      'preferredDifficulty': preferredDifficulty.value,
      'enableSound': enableSound,
      'enableHaptic': enableHaptic,
      'studyTime': studyTime,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    showHints = json['showHints'] ?? true;
    autoAdvance = json['autoAdvance'] ?? false;
    preferredDifficulty = DifficultyLevel.values.firstWhere(
          (d) => d.value == json['preferredDifficulty'],
      orElse: () => DifficultyLevel.medium,
    );
    enableSound = json['enableSound'] ?? true;
    enableHaptic = json['enableHaptic'] ?? true;
    studyTime = json['studyTime'] ?? 25;
  }
}

// کلاس برای مدیریت نشان‌ها و دستاوردها
class AchievementSystem {
  static final List<Achievement> allAchievements = [
    Achievement(
      id: 'first_section',
      title: 'قدم اول',
      description: 'اولین بخش را تکمیل کردید',
      icon: '🏆',
      condition: (ProgressTracker tracker) =>
          tracker._completedSections.values.any((completed) => completed),
    ),
    Achievement(
      id: 'perfect_score',
      title: 'کامل',
      description: 'در یک بخش نمره کامل گرفتید',
      icon: '⭐',
      condition: (ProgressTracker tracker) =>
      tracker._correctAnswers.values.any((answers) => answers.isNotEmpty) &&
          MathContentData.lessonSections.entries
              .any((entry) => tracker.getSectionScore(entry.key) == 1.0),
    ),
    Achievement(
      id: 'speed_learner',
      title: 'یادگیرنده سریع',
      description: 'یک بخش را در کمتر از 10 دقیقه تکمیل کردید',
      icon: '⚡',
      condition: (ProgressTracker tracker) =>
          tracker._timeSpent.values.any((time) => time > 0 && time < 10),
    ),
    Achievement(
      id: 'marathon',
      title: 'ماراتن مطالعه',
      description: 'بیش از 60 دقیقه مطالعه کردید',
      icon: '🏃‍♂️',
      condition: (ProgressTracker tracker) => tracker.getTotalTimeSpent() >= 60,
    ),
    Achievement(
      id: 'master',
      title: 'استاد',
      description: 'تمام بخش‌ها را با موفقیت تکمیل کردید',
      icon: '🎓',
      condition: (ProgressTracker tracker) => tracker.getOverallProgress() == 1.0,
    ),
    Achievement(
      id: 'hard_mode',
      title: 'چالش‌جو',
      description: 'یک سوال سخت را درست پاسخ دادید',
      icon: '💪',
      condition: (ProgressTracker tracker) {
        // بررسی اینکه آیا سوال سختی درست پاسخ داده شده
        for (var sectionId in MathContentData.lessonSections.keys) {
          final content = MathContentData.lessonSections[sectionId]?.content;
          if (content != null) {
            final hardQuestions = content.questions
                .asMap()
                .entries
                .where((entry) => entry.value.difficulty == DifficultyLevel.hard)
                .map((entry) => entry.key);
            final correctAnswers = tracker._correctAnswers[sectionId] ?? [];
            if (hardQuestions.any((qId) => correctAnswers.contains(qId))) {
              return true;
            }
          }
        }
        return false;
      },
    ),
  ];

  static List<Achievement> getUnlockedAchievements(ProgressTracker tracker) {
    return allAchievements
        .where((achievement) => achievement.condition(tracker))
        .toList();
  }

  static List<Achievement> getNewAchievements(
      ProgressTracker oldTracker, ProgressTracker newTracker) {
    final oldUnlocked = getUnlockedAchievements(oldTracker);
    final newUnlocked = getUnlockedAchievements(newTracker);

    return newUnlocked
        .where((achievement) => !oldUnlocked.any((old) => old.id == achievement.id))
        .toList();
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool Function(ProgressTracker) condition;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.condition,
  });
}

// کلاس برای مدیریت تمرین‌های تدریجی
class PracticeManager {
  static List<QuizQuestion> getAdaptiveQuestions(int sectionId,
      ProgressTracker tracker,
      {int count = 5}) {
    final content = MathContentData.lessonSections[sectionId]?.content;
    if (content == null) return [];

    final score = tracker.getSectionScore(sectionId);
    final questions = content.questions;

    List<QuizQuestion> selectedQuestions = [];

    if (score < 0.3) {
      // نمره پایین: سوالات آسان
      selectedQuestions = questions
          .where((q) => q.difficulty == DifficultyLevel.easy)
          .take(count)
          .toList();
    } else if (score < 0.7) {
      // نمره متوسط: ترکیب آسان و متوسط
      final easy = questions
          .where((q) => q.difficulty == DifficultyLevel.easy)
          .take(count ~/ 2)
          .toList();
      final medium = questions
          .where((q) => q.difficulty == DifficultyLevel.medium)
          .take(count - easy.length)
          .toList();
      selectedQuestions = [...easy, ...medium];
    } else {
      // نمره بالا: ترکیب متوسط و سخت
      final medium = questions
          .where((q) => q.difficulty == DifficultyLevel.medium)
          .take(count ~/ 2)
          .toList();
      final hard = questions
          .where((q) => q.difficulty == DifficultyLevel.hard)
          .take(count - medium.length)
          .toList();
      selectedQuestions = [...medium, ...hard];
    }

    // اگر سوال کافی نیست، از همه استفاده کن
    if (selectedQuestions.length < count) {
      selectedQuestions = questions.take(count).toList();
    }

    return selectedQuestions..shuffle();
  }

  static List<ExampleItem> getRelevantExamples(
      int sectionId, DifficultyLevel difficulty) {
    final content = MathContentData.lessonSections[sectionId]?.content;
    if (content == null) return [];

    return content.examples
        .where((example) => example.difficulty == difficulty)
        .toList();
  }
}

// کلاس برای مدیریت یادداشت‌های کاربر
class UserNotes {
  final Map<int, List<Note>> _notes = {};

  void addNote(int sectionId, String content, NoteType type) {
    _notes.putIfAbsent(sectionId, () => []);
    _notes[sectionId]!.add(Note(
      id: DateTime.now().millisecondsSinceEpoch,
      content: content,
      type: type,
      timestamp: DateTime.now(),
    ));
  }

  void removeNote(int sectionId, int noteId) {
    _notes[sectionId]?.removeWhere((note) => note.id == noteId);
  }

  List<Note> getNotes(int sectionId) {
    return _notes[sectionId] ?? [];
  }

  List<Note> getAllNotes() {
    return _notes.values.expand((notes) => notes).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<String, dynamic> toJson() {
    return _notes.map((sectionId, notes) => MapEntry(
      sectionId.toString(),
      notes.map((note) => note.toJson()).toList(),
    ));
  }

  void fromJson(Map<String, dynamic> json) {
    _notes.clear();
    json.forEach((sectionIdStr, notesList) {
      final sectionId = int.parse(sectionIdStr);
      final notes = (notesList as List)
          .map((noteJson) => Note.fromJson(noteJson as Map<String, dynamic>))
          .toList();
      _notes[sectionId] = notes;
    });
  }
}

class Note {
  final int id;
  final String content;
  final NoteType type;
  final DateTime timestamp;

  Note({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'],
      type: NoteType.values[json['type']],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

enum NoteType {
  personal, // یادداشت شخصی
  important, // نکته مهم
  question, // سوال
  reminder, // یادآوری
}

// کلاس برای مدیریت فلش کارت‌ها
class FlashCardManager {
  static List<FlashCard> generateFlashCards() {
    final flashCards = <FlashCard>[];

    // تولید فلش کارت از تعاریف هر بخش
    for (var entry in MathContentData.lessonSections.entries) {
      final sectionId = entry.key;
      final content = entry.value.content;

      content.definitions.forEach((term, definition) {
        flashCards.add(FlashCard(
          id: '${sectionId}_def_${term.hashCode}',
          front: term,
          back: definition,
          sectionId: sectionId,
          type: FlashCardType.definition,
        ));
      });

      // تولید فلش کارت از نکات کلیدی
      for (var i = 0; i < content.keyPoints.length; i++) {
        final point = content.keyPoints[i];
        flashCards.add(FlashCard(
          id: '${sectionId}_key_$i',
          front: 'نکته کلیدی ${i + 1} - ${entry.value.title}',
          back: point,
          sectionId: sectionId,
          type: FlashCardType.keyPoint,
        ));
      }
    }

    return flashCards;
  }

  static List<FlashCard> getFlashCardsForSection(int sectionId) {
    return generateFlashCards()
        .where((card) => card.sectionId == sectionId)
        .toList();
  }
}

class FlashCard {
  final String id;
  final String front;
  final String back;
  final int sectionId;
  final FlashCardType type;
  bool isKnown = false;

  FlashCard({
    required this.id,
    required this.front,
    required this.back,
    required this.sectionId,
    required this.type,
    this.isKnown = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'sectionId': sectionId,
      'type': type.index,
      'isKnown': isKnown,
    };
  }

  static FlashCard fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      sectionId: json['sectionId'],
      type: FlashCardType.values[json['type']],
      isKnown: json['isKnown'] ?? false,
    );
  }
}

enum FlashCardType {
  definition,
  keyPoint,
  formula,
  example,
}

// کلاس برای مدیریت تقویم مطالعه
class StudyScheduler {
  final Map<DateTime, StudySession> _sessions = {};

  void scheduleSession(DateTime date, List<int> sectionIds, int duration) {
    _sessions[date] = StudySession(
      date: date,
      sectionIds: sectionIds,
      plannedDuration: duration,
      status: SessionStatus.planned,
    );
  }

  void markSessionCompleted(DateTime date, int actualDuration) {
    if (_sessions.containsKey(date)) {
      _sessions[date]!.status = SessionStatus.completed;
      _sessions[date]!.actualDuration = actualDuration;
      _sessions[date]!.completedAt = DateTime.now();
    }
  }

  void markSessionSkipped(DateTime date) {
    if (_sessions.containsKey(date)) {
      _sessions[date]!.status = SessionStatus.skipped;
    }
  }

  List<StudySession> getUpcomingSessions() {
    final now = DateTime.now();
    return _sessions.values
        .where((session) =>
    session.date.isAfter(now) &&
        session.status == SessionStatus.planned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<StudySession> getCompletedSessions() {
    return _sessions.values
        .where((session) => session.status == SessionStatus.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int getWeeklyStudyTime() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return _sessions.values
        .where((session) =>
    session.date.isAfter(weekStart) &&
        session.status == SessionStatus.completed)
        .fold(0, (sum, session) => sum + (session.actualDuration ?? 0));
  }

  Map<String, dynamic> toJson() {
    return _sessions.map((date, session) => MapEntry(
      date.toIso8601String(),
      session.toJson(),
    ));
  }

  void fromJson(Map<String, dynamic> json) {
    _sessions.clear();
    json.forEach((dateStr, sessionJson) {
      final date = DateTime.parse(dateStr);
      final session =
      StudySession.fromJson(sessionJson as Map<String, dynamic>);
      _sessions[date] = session;
    });
  }
}

class StudySession {
  final DateTime date;
  final List<int> sectionIds;
  final int plannedDuration; // minutes
  SessionStatus status;
  int? actualDuration;
  DateTime? completedAt;

  StudySession({
    required this.date,
    required this.sectionIds,
    required this.plannedDuration,
    required this.status,
    this.actualDuration,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sectionIds': sectionIds,
      'plannedDuration': plannedDuration,
      'status': status.index,
      'actualDuration': actualDuration,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static StudySession fromJson(Map<String, dynamic> json) {
    return StudySession(
      date: DateTime.parse(json['date']),
      sectionIds: List<int>.from(json['sectionIds']),
      plannedDuration: json['plannedDuration'],
      status: SessionStatus.values[json['status']],
      actualDuration: json['actualDuration'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

enum SessionStatus {
  planned,
  completed,
  skipped,
  inProgress,
}

// کلاس اصلی برای مدیریت کل داده‌ها
class MathLearningManager {
  final ProgressTracker progressTracker = ProgressTracker();
  final LearningSettings settings = LearningSettings();
  final UserNotes userNotes = UserNotes();
  final StudyScheduler scheduler = StudyScheduler();

  // متدهای کمکی برای کار با داده‌ها

  /// دریافت محتوای مناسب بر اساس سطح یادگیرنده
  List<ContentBlock> getAdaptiveContent(int sectionId) {
    final content = MathContentData.lessonSections[sectionId]?.content;
    if (content == null) return [];

    final score = progressTracker.getSectionScore(sectionId);
    final preferredDifficulty = settings.preferredDifficulty;

    // اگر نمره پایین است، محتوای ساده‌تر ارائه دهید
    if (score < 0.5 && preferredDifficulty != DifficultyLevel.easy) {
      return content.theory
          .where((block) =>
      block.type == ContentType.definition ||
          block.type == ContentType.explanation)
          .toList();
    }

    return content.theory;
  }

  /// پیشنهاد بخش بعدی بر اساس پیشرفت
  int? getNextRecommendedSection() {
    final completedSections = progressTracker._completedSections;

    // پیدا کردن اولین بخش تکمیل نشده
    for (var sectionId in MathContentData.lessonSections.keys.toList()..sort()) {
      if (!(completedSections[sectionId] ?? false)) {
        return sectionId;
      }
    }

    // اگر همه تکمیل شده، پیشنهاد مرور بخش‌هایی با نمره پایین
    double lowestScore = 1.0;
    int? weakestSection;

    for (var sectionId in MathContentData.lessonSections.keys) {
      final score = progressTracker.getSectionScore(sectionId);
      if (score < lowestScore) {
        lowestScore = score;
        weakestSection = sectionId;
      }
    }

    return weakestSection;
  }

  /// محاسبه زمان تخمینی برای تکمیل درس
  int getEstimatedRemainingTime() {
    final totalSections = MathContentData.lessonSections.length;
    final completedSections =
        progressTracker._completedSections.values.where((v) => v).length;
    final remainingSections = totalSections - completedSections;

    // فرض: هر بخش در میانگین 8 دقیقه
    return remainingSections * 8;
  }

  /// دریافت آمار عملکرد کاربر
  Map<String, dynamic> getPerformanceAnalytics() {
    final stats = progressTracker.getStatistics();

    // محاسبه نرخ موفقیت
    double totalScore = 0;
    int sectionsWithQuestions = 0;

    for (var sectionId in MathContentData.lessonSections.keys) {
      final content = MathContentData.lessonSections[sectionId]?.content;
      if (content != null && content.questions.isNotEmpty) {
        totalScore += progressTracker.getSectionScore(sectionId);
        sectionsWithQuestions++;
      }
    }

    final averageScore =
    sectionsWithQuestions > 0 ? totalScore / sectionsWithQuestions : 0.0;

    stats['averageScore'] = averageScore;
    stats['estimatedRemainingTime'] = getEstimatedRemainingTime();
    stats['weeklyStudyTime'] = scheduler.getWeeklyStudyTime();
    stats['totalNotes'] = userNotes.getAllNotes().length;

    // تحلیل نقاط قوت و ضعف
    final strengths = <String>[];
    final weaknesses = <String>[];

    for (var entry in MathContentData.lessonSections.entries) {
      final score = progressTracker.getSectionScore(entry.key);
      final sectionTitle = entry.value.title;

      if (score >= 0.8) {
        strengths.add(sectionTitle);
      } else if (score < 0.5 && score > 0) {
        weaknesses.add(sectionTitle);
      }
    }

    stats['strengths'] = strengths;
    stats['weaknesses'] = weaknesses;

    return stats;
  }

  /// ذخیره و بازیابی داده‌ها
  Map<String, dynamic> exportData() {
    return {
      'progress': progressTracker.getStatistics(),
      'settings': settings.toJson(),
      'notes': userNotes.toJson(),
      'schedule': scheduler.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  void importData(Map<String, dynamic> data) {
    try {
      if (data.containsKey('settings')) {
        settings.fromJson(data['settings']);
      }
      if (data.containsKey('notes')) {
        userNotes.fromJson(data['notes']);
      }
      if (data.containsKey('schedule')) {
        scheduler.fromJson(data['schedule']);
      }
      // Note: Progress data would need special handling for reconstruction
    } catch (e) {
      // ignore: avoid_print
      print('Error importing data: $e');
    }
  }

  /// تولید گزارش پیشرفت
  String generateProgressReport() {
    final stats = getPerformanceAnalytics();
    final overallProgress = (stats['overallProgress'] * 100).round();
    final averageScore = ((stats['averageScore'] ?? 0) * 100).round();
    final totalTime = stats['totalTimeSpent'];

    final report = StringBuffer();
    report.writeln('📊 گزارش پیشرفت درس مقدمات ریاضی');
    report.writeln('=' * 40);
    report.writeln('📈 پیشرفت کلی: $overallProgress%');
    report.writeln('🎯 میانگین نمرات: $averageScore%');
    report.writeln('⏰ مدت زمان مطالعه: $totalTime دقیقه');
    report.writeln('📝 تعداد یادداشت‌ها: ${stats['totalNotes']}');

    if (stats['strengths'].isNotEmpty) {
      report.writeln('\n💪 نقاط قوت:');
      for (var strength in stats['strengths']) {
        report.writeln('  • $strength');
      }
    }

    if (stats['weaknesses'].isNotEmpty) {
      report.writeln('\n⚠️ نیاز به تمرین بیشتر:');
      for (var weakness in stats['weaknesses']) {
        report.writeln('  • $weakness');
      }
    }

    final nextSection = getNextRecommendedSection();
    if (nextSection != null) {
      final sectionTitle = MathContentData.lessonSections[nextSection]?.title;
      report.writeln('\n🎯 پیشنهاد بعدی: $sectionTitle');
    }

    final remainingTime = getEstimatedRemainingTime();
    if (remainingTime > 0) {
      report.writeln('⏱️ زمان تخمینی باقی‌مانده: $remainingTime دقیقه');
    } else {
      report.writeln('🎉 تبریک! درس را با موفقیت تکمیل کردید!');
    }

    return report.toString();
  }
}