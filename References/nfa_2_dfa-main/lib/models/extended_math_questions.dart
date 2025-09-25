import 'dart:math' as math;
import 'math_content_data.dart';

class EnhancedQuizQuestions {
  // سوالات پیشرفته برای مقدمات ریاضی و مجموعه‌ها
  static List<QuizQuestion> getAdvancedIntroductionQuestions() {
    return [
      QuizQuestion(
        question:
        'اگر A = {x | x ∈ ℕ ∧ x mod 3 = 1} و B = {x | x ∈ ℕ ∧ x² < 50} باشد، کاردینال A ∩ B چقدر است؟',
        options: ['2', '3', '4', '5'],
        correctAnswer: 1, // پاسخ صحیح 3 است. A ∩ B = {1, 4, 7}
        explanation:
        'A = {1, 4, 7, 10, 13, ...} و B = {1, 2, 3, 4, 5, 6, 7}, پس A ∩ B = {1, 4, 7} با کاردینال 3',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'در بیان خاصیت مجموعه، کدام عبارت معادل {x | x ∈ ℤ ∧ -3 ≤ x ≤ 3} است؟',
        options: [
          '{-3, -2, -1, 0, 1, 2, 3}',
          '{-3, -2, -1, 1, 2, 3}',
          '{-2, -1, 0, 1, 2}',
          '{0, ±1, ±2, ±3}'
        ],
        correctAnswer: 0,
        explanation:
        'مجموعه شامل تمام اعداد صحیح از -3 تا 3 می‌باشد که شامل صفر نیز هست.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'اگر مجموعه A = {{a}, {b, c}, ∅} باشد، کدام عبارت صحیح است؟',
        options: ['a ∈ A', '∅ ⊆ A', '{∅} ⊆ A', 'b ∈ A'],
        correctAnswer: 2,
        explanation:
        'A شامل سه عضو است: {a}، {b, c} و ∅. پس {∅} زیرمجموعه A است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'تعداد زیرمجموعه‌های مجموعه A = {∅, {1}, {{2}}} چقدر است؟',
        options: ['6', '7', '8', '9'],
        correctAnswer: 2,
        explanation: '|A| = 3، پس تعداد زیرمجموعه‌ها = 2³ = 8',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'مجموعه تمام زیرمجموعه‌های مجموعه {a, b} که شامل عنصر a باشند، کدام است؟',
        options: [
          '{{a}, {a, b}}',
          '{{a}, {b}, {a, b}}',
          '{{a}, ∅, {a, b}}',
          'P({a, b})'
        ],
        correctAnswer: 0,
        explanation: 'زیرمجموعه‌هایی که شامل a هستند: {a} و {a, b}',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای خصوصیات مجموعه‌ها
  static List<QuizQuestion> getAdvancedSetPropertiesQuestions() {
    return [
      QuizQuestion(
        question: 'کدام مجموعه نقض خاصیت "تعین‌بودگی" می‌کند؟',
        options: [
          'مجموعه اعداد بزرگ',
          'مجموعه دانشجویان باهوش کلاس',
          'مجموعه شهرهای زیبای ایران',
          'همه موارد فوق'
        ],
        correctAnswer: 3,
        explanation:
        'همه این مجموعه‌ها دارای تعاریف مبهم هستند و نمی‌توان به طور قطعی تشخیص داد عنصری عضو آنها است یا نه.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'اگر A = {1, 2, {3, 4}} باشد، کدام گزینه نادرست است؟',
        options: ['1 ∈ A', '{3, 4} ∈ A', '3 ∈ A', '|A| = 3'],
        correctAnswer: 2,
        explanation:
        '3 عضو مجموعه {3, 4} است که خود عضو A است، اما 3 مستقیماً عضو A نیست.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'در کدام مورد خاصیت "یکتایی اعضا" نقش اساسی دارد؟',
        options: [
          '{a, a, b, b, c} = {a, b, c}',
          '{1, 2, 3} ≠ {3, 2, 1}',
          '{x, y} = {y, x}',
          'هیچکدام'
        ],
        correctAnswer: 0,
        explanation:
        'خاصیت یکتایی اعضا باعث می‌شود تکرار عناصر در نمایش مجموعه حذف شود.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'کدام عبارت بیان‌گر اصل دوگانگی (Law of Excluded Middle) در مجموعه‌ها است؟',
        options: [
          'x ∈ A ∨ x ∉ A',
          'x ∈ A ∧ x ∉ A',
          'x ∈ A ↔ x ∉ A',
          'x ∈ A → x ∉ A'
        ],
        correctAnswer: 0,
        explanation:
        'اصل دوگانگی می‌گوید هر عنصر یا عضو مجموعه است یا نیست، حالت سومی وجود ندارد.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر دو مجموعه A و B را فقط بر اساس "عدم اهمیت ترتیب" مقایسه کنیم، کدام درست است؟',
        options: [
          '{1, 2, 3} = {3, 1, 2}',
          '{a, b, a} ≠ {b, a}',
          '{x, y, z} ⊂ {z, y, x}',
          'هیچکدام'
        ],
        correctAnswer: 0,
        explanation:
        'خاصیت عدم اهمیت ترتیب نشان می‌دهد که ترتیب عناصر در تعریف مجموعه مهم نیست.',
        difficulty: DifficultyLevel.easy,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای زیرمجموعه و زیرمجموعه محض
  static List<QuizQuestion> getAdvancedSubsetQuestions() {
    return [
      QuizQuestion(
        question: 'اگر A ⊆ B، B ⊆ C و C ⊂ A باشد، کدام نتیجه صحیح است؟',
        options: ['A = B = C', 'A ⊂ B ⊂ C', 'این شرایط ممکن نیست', 'A ⊂ C'],
        correctAnswer: 2,
        explanation:
        'اگر A ⊆ B ⊆ C و C ⊂ A، آنگاه باید C ⊂ A ⊆ B ⊆ C باشد که ممکن نیست زیرا C نمی‌تواند هم زیرمجموعه محض A و هم شامل A باشد.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'تعداد زیرمجموعه‌های محض مجموعه A = {1, 2, 3, 4} چقدر است؟',
        options: ['15', '16', '14', '12'],
        correctAnswer: 0,
        explanation:
        'کل زیرمجموعه‌ها: 2⁴ = 16، زیرمجموعه محض: 16 - 1 = 15 (خود مجموعه A را کم می‌کنیم)',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر |A| = n باشد، تعداد زیرمجموعه‌هایی که شامل عنصر مشخص x ∈ A هستند چقدر است؟',
        options: ['2ⁿ⁻¹', '2ⁿ', 'n', '2ⁿ + 1'],
        correctAnswer: 0,
        explanation:
        'برای n-1 عنصر باقی‌مانده، هر کدام می‌توانند در زیرمجموعه باشند یا نباشند: 2ⁿ⁻¹',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام شرط لازم و کافی برای A ⊂ B است؟',
        options: [
          'A ⊆ B و A ≠ B',
          'A ⊆ B و B ⊄ A',
          'هر عضو A عضو B است و حداقل یک عضو B عضو A نیست',
          'همه موارد فوق'
        ],
        correctAnswer: 3,
        explanation: 'هر سه شرط معادل تعریف زیرمجموعه محض هستند.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر A = {x | x ∈ ℕ ∧ x < 5} و B = {x | x ∈ ℕ ∧ x ≤ 5} باشد، رابطه بین A و B کدام است؟',
        options: ['A = B', 'A ⊂ B', 'B ⊂ A', 'A و B مجزا هستند'],
        correctAnswer: 1,
        explanation: 'A = {1, 2, 3, 4} و B = {1, 2, 3, 4, 5}، پس A ⊂ B',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای مجموعه توانی
  static List<QuizQuestion> getAdvancedPowerSetQuestions() {
    return [
      QuizQuestion(
        question: 'اگر A = {1, {2, 3}} باشد، کدام عضو P(A) است؟',
        options: ['{2, 3}', '{{2, 3}}', '{1, 2, 3}', '{1, {2, 3}, 2, 3}'],
        correctAnswer: 1,
        explanation:
        'P(A) = {∅, {1}, {{2, 3}}, {1, {2, 3}}}. گزینه {{2, 3}} یکی از اعضاست.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'حداکثر عمق تو در توی مجموعه در P(P({a})) چقدر است؟',
        options: ['2', '3', '4', '5'],
        correctAnswer: 1,
        explanation:
        'P({a}) = {∅, {a}}، سپس P(P({a})) = {∅, {∅}, {{a}}, {∅, {a}}}. حداکثر عمق در {{a}} است که 3 است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر |P(A)| = 64 باشد، حداکثر تعداد زیرمجموعه‌های A که دقیقاً k عضو دارند برای کدام k بیشینه است؟',
        options: ['k = 2', 'k = 3', 'k = 4', 'k = 6'],
        correctAnswer: 1,
        explanation:
        '|A| = 6 (زیرا 2⁶ = 64). حداکثر C(6,k) برای k = 3 است: C(6,3) = 20',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام رابطه همیشه درست است؟',
        options: [
          'P(A ∪ B) = P(A) ∪ P(B)',
          'P(A ∩ B) = P(A) ∩ P(B)',
          'P(A) ∪ P(B) ⊆ P(A ∪ B)',
          'P(A ∪ B) ⊆ P(A) ∪ P(B)'
        ],
        correctAnswer: 2,
        explanation:
        'هر زیرمجموعه A یا B، زیرمجموعه A ∪ B نیز هست، پس P(A) ∪ P(B) ⊆ P(A ∪ B)',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'اگر A ⊆ B باشد، کدام رابطه درست است؟',
        options: ['P(A) ⊆ P(B)', 'P(B) ⊆ P(A)', 'P(A) = P(B)', 'P(A) ∩ P(B) = ∅'],
        correctAnswer: 0,
        explanation:
        'اگر A ⊆ B، آنگاه هر زیرمجموعه A، زیرمجموعه B نیز هست، پس P(A) ⊆ P(B)',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای توابع
  static List<QuizQuestion> getAdvancedFunctionQuestions() {
    return [
      QuizQuestion(
        question:
        'اگر f: A → B و g: B → C دو تابع باشند و |A| = m، |B| = n، |C| = p، تعداد توابع مرکب ممکن g∘f چقدر است؟',
        options: ['pᵐ', 'nᵐ × pⁿ', 'p^(m×n)', 'بستگی به f و g دارد'],
        correctAnswer: 3,
        explanation:
        'تعداد توابع مرکب به توابع خاص f و g بستگی دارد، نه فقط به اندازه مجموعه‌ها.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'تابع f: ℝ → ℝ تعریف شده با f(x) = x³ - 3x دارای کدام خاصیت است؟',
        options: [
          'یکی و پوشا',
          'یکی اما نه پوشا',
          'پوشا اما نه یکی',
          'نه یکی نه پوشا'
        ],
        correctAnswer: 2,
        explanation:
        'f(-1) = f(1) = -2 پس یکی نیست. اما مشتق f\'(x) = 3x² - 3 نشان می‌دهد f پوشاست.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر f: A → B پوشا و g: B → C یکی باشد، تابع مرکب g∘f دارای کدام خاصیت است؟',
        options: [
          'حتماً یکی است',
          'حتماً پوشا است',
          'هم یکی هم پوشا است',
          'ممکن است یکی نباشد'
        ],
        correctAnswer: 0,
        explanation: 'اگر g یکی باشد، g∘f نیز یکی است (صرف‌نظر از خاصیت f)',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام شرط لازم و کافی برای وجود تابع معکوس f⁻¹ است؟',
        options: [
          'f پوشا باشد',
          'f یکی باشد',
          'f دوسویه باشد',
          'دامنه و مدامنه f برابر باشند'
        ],
        correctAnswer: 2,
        explanation:
        'تابع معکوس وجود دارد اگر و تنها اگر تابع دوسویه (یکی و پوشا) باشد.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر f: A → B و |A| = 5، |B| = 3 باشد، حداکثر تعداد توابع یکی از A به B چقدر است؟',
        options: ['0', '3!', '5!/2!', 'P(5,3)'],
        correctAnswer: 0,
        explanation:
        'چون |A| > |B|، نمی‌توان تابع یکی تعریف کرد (اصل لانه کبوتری)',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای مجموعه‌های متناهی و نامتناهی
  static List<QuizQuestion> getAdvancedFiniteInfiniteQuestions() {
    return [
      QuizQuestion(
        question: 'کدام مجموعه دارای همان کاردینال اعداد طبیعی است؟',
        options: [
          'اعداد صحیح',
          'اعداد گویا',
          'اعداد حقیقی مثبت',
          'گزینه‌های 1 و 2'
        ],
        correctAnswer: 3,
        explanation:
        'اعداد صحیح و گویا قابل شمارش هستند و همان کاردینال اعداد طبیعی را دارند (ℵ₀)',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر A مجموعه‌ای نامتناهی قابل شمارش و B مجموعه‌ای متناهی غیرخالی باشد، A × B کدام خاصیت را دارد؟',
        options: [
          'متناهی است',
          'نامتناهی قابل شمارش است',
          'نامتناهی غیرقابل شمارش است',
          'بستگی به B دارد'
        ],
        correctAnswer: 1,
        explanation:
        'حاصل‌ضرب دکارتی مجموعه نامتناهی قابل شمارش و مجموعه متناهی، نامتناهی قابل شمارش است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'براساس قضیه کانتور، کدام عبارت درست است؟',
        options: [
          '|A| = |P(A)| همیشه',
          '|A| < |P(A)| همیشه',
          '|A| > |P(A)| گاهی',
          '|A| ≤ |P(A)| همیشه'
        ],
        correctAnswer: 1,
        explanation:
        'قضیه کانتور بیان می‌کند که کاردینال هر مجموعه از کاردینال مجموعه توانی آن کوچکتر است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'مجموعه اعداد جبری (ریشه‌های چندجمله‌ای با ضرایب گویا) دارای کدام خاصیت است؟',
        options: ['متناهی', 'نامتناهی قابل شمارش', 'نامتناهی غیرقابل شمارش', 'نامعین'],
        correctAnswer: 1,
        explanation:
        'اعداد جبری قابل شمارش هستند زیرا چندجمله‌ای‌های با ضرایب گویا قابل شمارش هستند.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام مجموعه نمونه‌ای از نامتناهی غیرقابل شمارش است؟',
        options: [
          'مجموعه تمام دنباله‌های متناهی از 0 و 1',
          'مجموعه تمام دنباله‌های نامتناهی از 0 و 1',
          'مجموعه تمام زیرمجموعه‌های متناهی ℕ',
          'مجموعه اعداد گویا بین 0 و 1'
        ],
        correctAnswer: 1,
        explanation:
        'مجموعه دنباله‌های نامتناهی دودویی همان کاردینال اعداد حقیقی را دارد (غیرقابل شمارش).',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات پیشرفته برای زبان، گرامر و ماشین
  static List<QuizQuestion> getAdvancedLanguageGrammarQuestions() {
    return [
      QuizQuestion(
        question:
        'اگر Σ = {a, b} باشد، زبان L = {aⁿbᵐ | n ≥ m ≥ 0} شامل کدام رشته نیست؟',
        options: ['aaab', 'aabb', 'abb', 'aaaa'],
        correctAnswer: 2,
        explanation:
        'در رشته "abb" داریم n=1, m=2 و n < m که شرط n ≥ m را نقض می‌کند.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'در گرامر G = ({S, A}, {a, b}, P, S) با قوانین S → aAb | ab و A → aAb | ab، زبان تولید شده کدام است؟',
        options: [
          '{aⁿbⁿ | n ≥ 1}',
          '{aⁿbᵐ | n, m ≥ 1}',
          '{a²ⁿb²ⁿ | n ≥ 1}',
          '{(ab)ⁿ | n ≥ 1}'
        ],
        correctAnswer: 0,
        explanation:
        'این گرامر تولید زبان {ab, aabb, aaabbb, ...} = {aⁿbⁿ | n ≥ 1} می‌کند.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام گزاره درباره سلسله‌مراتب چامسکی درست است؟',
        options: [
          'زبان‌های نوع 3 ⊂ زبان‌های نوع 2 ⊂ زبان‌های نوع 1 ⊂ زبان‌های نوع 0',
          'زبان‌های نوع 0 ⊂ زبان‌های نوع 1 ⊂ زبان‌های نوع 2 ⊂ زبان‌های نوع 3',
          'همه شمول‌ها محض هستند',
          'زبان‌های نوع 2 و نوع 1 یکسان هستند'
        ],
        correctAnswer: 0,
        explanation:
        'سلسله‌مراتب چامسکی: منظم ⊂ مستقل از متن ⊂ وابسته به متن ⊂ بازشناختنی',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'زبان L = {ww^R | w ∈ {a,b}*} (w^R معکوس w) نمونه‌ای از کدام کلاس زبان است؟',
        options: [
          'زبان منظم',
          'زبان مستقل از متن',
          'زبان وابسته به متن',
          'زبان غیر بازشناختنی'
        ],
        correctAnswer: 1,
        explanation:
        'زبان palindrome مستقل از متن است و با اتوماتای پشته‌ای قابل پذیرش است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر Σ = {0, 1} و L₁ = {0ⁿ1ⁿ | n ≥ 0}، L₂ = {1ⁿ0ⁿ | n ≥ 0} باشد، L₁ ∪ L₂ چه خاصیتی دارد؟',
        options: [
          'منظم است',
          'مستقل از متن اما نه منظم',
          'وابسته به متن است',
          'غیر بازشناختنی است'
        ],
        correctAnswer: 1,
        explanation:
        'اتحاد دو زبان مستقل از متن، مستقل از متن است. اما این زبان منظم نیست.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'در اتوماتای متناهی قطعی (DFA)، کدام شرط ضروری است؟',
        options: [
          'برای هر حالت و هر نماد ورودی، دقیقاً یک انتقال وجود دارد',
          'حداقل یک حالت پذیرنده وجود دارد',
          'ε-انتقال مجاز است',
          'چندین حالت شروع می‌تواند داشته باشد'
        ],
        correctAnswer: 0,
        explanation: 'در DFA، تابع انتقال باید کاملاً تعریف شده باشد: δ: Q × Σ → Q',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام زبان توسط اتوماتای متناهی قابل پذیرش نیست؟',
        options: [
          '{aⁿbⁿcⁿ | n ≥ 0}',
          '{(ab)*}',
          '{a*b*}',
          '{w | w شامل تعداد زوج a است}'
        ],
        correctAnswer: 0,
        explanation:
        'زبان {aⁿbⁿcⁿ | n ≥ 0} وابسته به متن است و نیازمند حافظه نامحدود دارد.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'عبارت منظم (regular expression) برای زبان "رشته‌هایی که با a شروع و با b پایان می‌یابند" کدام است؟',
        options: ['a(a|b)*b', 'a*b*', 'a(a|b)*', '(a|b)*ab'],
        correctAnswer: 0,
        explanation:
        'باید با a شروع شود، سپس هر ترکیبی از a و b، و در آخر با b پایان یابد.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'اگر L زبانی منظم باشد، کدام گزاره همیشه درست است؟',
        options: [
          'L^R (معکوس L) منظم است',
          'L̄ (متمم L) منظم است',
          'L* (بسته ستاره‌ای L) منظم است',
          'همه موارد فوق'
        ],
        correctAnswer: 3,
        explanation:
        'زبان‌های منظم تحت عملیات معکوس، متمم، و بسته ستاره‌ای بسته هستند.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'در ماشین تورینگ، نوار (tape) کدام خاصیت را دارد؟',
        options: [
          'فقط خواندنی است',
          'طول آن متناهی است',
          'دو طرفه نامتناهی است',
          'نمی‌تواند خالی باشد'
        ],
        correctAnswer: 2,
        explanation:
        'نوار ماشین تورینگ دو طرفه نامتناهی است و قابل خواندن و نوشتن.',
        difficulty: DifficultyLevel.medium,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // سوالات چالشی و تشریحی برای سطح پیشرفته
  static List<QuizQuestion> getChallengeQuestions() {
    return [
      QuizQuestion(
        question:
        'ثابت کنید یا رد کنید: اگر A و B دو مجموعه متناهی باشند، آنگاه |P(A ∪ B)| = |P(A)| × |P(B)|',
        options: [
          'درست است',
          'نادرست است',
          'فقط وقتی A ∩ B = ∅ درست است',
          'فقط وقتی A = B درست است'
        ],
        correctAnswer: 2,
        explanation:
        'فقط زمانی که A و B مجزا باشند: |P(A ∪ B)| = 2^|A∪B| = 2^(|A|+|B|) = 2^|A| × 2^|B| = |P(A)| × |P(B)|',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'فرض کنید f: ℕ → ℕ با f(n) = ⌊n/2⌋ تعریف شده باشد. تابع f کدام خاصیت را دارد؟',
        options: [
          'یکی است',
          'پوشا است',
          'نه یکی نه پوشا',
          'یکی نیست اما پوشا است'
        ],
        correctAnswer: 3,
        explanation:
        'f(4) = f(5) = 2 پس یکی نیست. اما هر n ∈ ℕ تصویر 2n+1 است، پس پوشا است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question: 'کدام گزاره درباره قدرت محاسباتی ماشین‌ها درست است؟',
        options: [
          'اتوماتای متناهی = عبارات منظم = گرامر نوع 3',
          'اتوماتای پشته‌ای = گرامر مستقل از متن = گرامر نوع 2',
          'ماشین تورینگ = گرامر عمومی = گرامر نوع 0',
          'همه موارد فوق'
        ],
        correctAnswer: 3,
        explanation:
        'این سه معادل‌سازی اساس نظریه محاسبات و زبان‌های صوری هستند.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'اگر G گرامری مستقل از متن باشد، کدام تبدیل آن را به شکل نرمال چامسکی می‌برد؟',
        options: [
          'حذف قوانین ε و قوانین واحد، سپس تبدیل به A → BC یا A → a',
          'فقط حذف قوانین ε',
          'فقط تبدیل به دوتایی',
          'افزودن نمادهای کمکی'
        ],
        correctAnswer: 0,
        explanation:
        'شکل نرمال چامسکی نیازمند حذف ε-قوانین و قوانین واحد، سپس تبدیل به شکل A → BC یا A → a است.',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
      QuizQuestion(
        question:
        'مسئله "آیا دو گرامر مستقل از متن، زبان یکسانی تولید می‌کنند؟" چه وضعیتی دارد؟',
        options: [
          'همیشه تصمیم‌پذیر است',
          'غیرتصمیم‌پذیر است',
          'فقط برای گرامرهای LL(1) تصمیم‌پذیر است',
          'پیچیدگی نمایی دارد اما تصمیم‌پذیر است'
        ],
        correctAnswer: 1,
        explanation:
        'مسئله تساوی دو گرامر مستقل از متن غیرتصمیم‌پذیر است (نتیجه قضیه رایس).',
        difficulty: DifficultyLevel.hard,
        type: QuestionType.multipleChoice,
      ),
    ];
  }

  // متد کمکی برای ترکیب تمام سوالات پیشرفته
  static Map<int, List<QuizQuestion>> getAllAdvancedQuestions() {
    return {
      0: getAdvancedIntroductionQuestions(),
      1: getAdvancedSetPropertiesQuestions(),
      2: getAdvancedSubsetQuestions(),
      3: getAdvancedPowerSetQuestions(),
      4: getAdvancedFunctionQuestions(),
      5: getAdvancedFiniteInfiniteQuestions(),
      6: getAdvancedLanguageGrammarQuestions(),
      7: getChallengeQuestions(), // سوالات چالشی برای تمام مباحث
    };
  }

  // متد برای ترکیب سوالات اصلی، اضافی و پیشرفته
  static List<QuizQuestion> getComprehensiveQuestions(int sectionId) {
    final originalContent = MathContentData.lessonSections[sectionId]?.content;
    if (originalContent == null) return [];

    final originalQuestions = originalContent.questions;

    // سوالات پیشرفته جدید
    final advancedQuestions = getAllAdvancedQuestions()[sectionId] ?? [];

    return [...originalQuestions, ...advancedQuestions];
  }

  // متد برای تولید آزمون سطح بین‌المللی
  static List<QuizQuestion> generateInternationalLevelQuiz({
    required int sectionId,
    int easyCount = 2,
    int mediumCount = 4,
    int hardCount = 4,
  }) {
    final allQuestions = getComprehensiveQuestions(sectionId);

    final easyQuestions = allQuestions
        .where((q) => q.difficulty == DifficultyLevel.easy)
        .toList()
      ..shuffle();

    final mediumQuestions = allQuestions
        .where((q) => q.difficulty == DifficultyLevel.medium)
        .toList()
      ..shuffle();

    final hardQuestions = allQuestions
        .where((q) => q.difficulty == DifficultyLevel.hard)
        .toList()
      ..shuffle();

    final quiz = <QuizQuestion>[];
    quiz.addAll(easyQuestions.take(easyCount));
    quiz.addAll(mediumQuestions.take(mediumCount));
    quiz.addAll(hardQuestions.take(hardCount));

    quiz.shuffle();
    return quiz;
  }

  static List<QuizQuestion> generateCSFocusedQuiz({int maxQuestions = 15}) {
    final languageQuestions = getAdvancedLanguageGrammarQuestions();
    final functionQuestions = getAdvancedFunctionQuestions();
    final setQuestions = getAdvancedSetPropertiesQuestions();
    final challengeQuestions = getChallengeQuestions();

    final focusedQuiz = <QuizQuestion>[];
    focusedQuiz.addAll(languageQuestions.take(6));
    focusedQuiz.addAll(functionQuestions.take(4));
    focusedQuiz.addAll(setQuestions.take(3));
    focusedQuiz.addAll(challengeQuestions.take(2));

    focusedQuiz.shuffle();
    return focusedQuiz.take(maxQuestions).toList();
  }

  // آمار کامل سوالات
  static Map<String, dynamic> getComprehensiveStatistics() {
    final stats = <String, dynamic>{};
    final allAdvancedQuestions = getAllAdvancedQuestions();

    int totalAdvanced = 0;
    int easyCount = 0;
    int mediumCount = 0;
    int hardCount = 0;

    final sectionStats = <String, int>{};

    for (var entry in allAdvancedQuestions.entries) {
      final sectionId = entry.key;
      final questions = entry.value;

      sectionStats['section_$sectionId'] = questions.length;

      for (var question in questions) {
        totalAdvanced++;
        switch (question.difficulty) {
          case DifficultyLevel.easy:
            easyCount++;
            break;
          case DifficultyLevel.medium:
            mediumCount++;
            break;
          case DifficultyLevel.hard:
            hardCount++;
            break;
        }
      }
    }

    stats['total_advanced'] = totalAdvanced;
    stats['difficulty_distribution'] = {
      'easy': easyCount,
      'medium': mediumCount,
      'hard': hardCount,
    };
    stats['section_distribution'] = sectionStats;

    stats['previous_questions'] = {'total': 0};
    stats['grand_total'] = totalAdvanced;

    return stats;
  }

  // متد برای تولید گزارش جامع
  static String generateQualityReport() {
    final stats = getComprehensiveStatistics();

    return '''
📊 گزارش کیفیت سوالات نظریه زبان‌ها و ماشین‌ها
═══════════════════════════════════════════════════

🎯 آمار کلی:
• مجموع سوالات پیشرفته: ${stats['total_advanced']}
• مجموع سوالات قبلی: ${stats['previous_questions']['total']}
• مجموع کل: ${stats['grand_total']}

📈 توزیع سطح دشواری (سوالات جدید):
• آسان: ${stats['difficulty_distribution']['easy']} سوال
• متوسط: ${stats['difficulty_distribution']['medium']} سوال
• سخت: ${stats['difficulty_distribution']['hard']} سوال

🏆 ویژگی‌های کیفی:
✅ پوشش کامل مطالب درسی
✅ ترکیب مناسب مفاهیم تئوری و کاربردی
✅ تنوع در انواع سوالات
✅ توضیحات جامع برای هر سوال

📚 پوشش موضوعی:
• مقدمات ریاضی و مجموعه‌ها
• خصوصیات و عملیات مجموعه‌ها
• زیرمجموعه و مجموعه توانی
• توابع و انواع آنها
• مجموعه‌های متناهی و نامتناهی
• زبان، گرامر و ماشین
• سوالات چالشی پیشرفته
    ''';
  }
}
