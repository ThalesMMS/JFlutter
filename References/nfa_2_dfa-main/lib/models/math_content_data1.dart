class MathContentData {
  static const String lessonTitle =
      "مقدمات ریاضی و مجموعه‌ها - تعریف زبان و گرامر";
  static const String lessonSubtitle = "جلسه 1";
  static const int estimatedTime = 45;

  static const List<String> learningObjectives = [
    "درک مفهوم مجموعه و خصوصیات آن",
    "تمایز بین زیرمجموعه و زیرمجموعه محض",
    "آشنایی با مجموعه توانی",
    "درک مفهوم تابع",
    "تفاوت مجموعه متناهی و نامتناهی",
    "آشنایی اولیه با زبان، گرامر و ماشین",
    "حل مسائل کاربردی مجموعه‌ها",
    "درک عملیات روی مجموعه‌ها",
  ];

  static final List<LessonSection> sections = [
    LessonSection(
      id: "sets_intro",
      title: "📚 مقدمات مجموعه‌ها",
      order: 1,
      dialogues: setsIntroDialogues,
      estimatedTime: 12,
      keywords: ["مجموعه", "عنصر", "عضویت", "مجموعه خالی"],
    ),
    LessonSection(
      id: "set_properties",
      title: "⚡ خصوصیات مجموعه‌ها",
      order: 2,
      dialogues: setPropertiesDialogues,
      estimatedTime: 10,
      keywords: ["ترتیب", "تکرار", "برابری", "مشخص بودن"],
    ),
    LessonSection(
      id: "set_operations",
      title: "🔧 عملیات روی مجموعه‌ها",
      order: 3,
      dialogues: setOperationsDialogues,
      estimatedTime: 12,
      keywords: ["اجتماع", "اشتراک", "تفاضل", "متمم"],
    ),
    LessonSection(
      id: "subsets_power",
      title: "🔍 زیرمجموعه و مجموعه توانی",
      order: 4,
      dialogues: subsetsDialogues,
      estimatedTime: 15,
      keywords: ["زیرمجموعه", "زیرمجموعه محض", "مجموعه توانی"],
    ),
    LessonSection(
      id: "finite_infinite",
      title: "♾️ مجموعه‌های متناهی و نامتناهی",
      order: 5,
      dialogues: finiteInfiniteDialogues,
      estimatedTime: 8,
      keywords: ["متناهی", "نامتناهی", "شمارش پذیر", "قدر"],
    ),
    LessonSection(
      id: "functions",
      title: "📈 مفهوم تابع",
      order: 6,
      dialogues: functionsDialogues,
      estimatedTime: 8,
      keywords: ["تابع", "دامنه", "برد", "یک به یک", "پوشا"],
    ),
    LessonSection(
      id: "language_grammar",
      title: "🗣️ زبان، گرامر و ماشین",
      order: 7,
      dialogues: languageDialogues,
      estimatedTime: 10,
      keywords: ["زبان", "گرامر", "ماشین", "الفبا", "رشته"],
    ),
    LessonSection(
      id: "practical_problems",
      title: "🎯 حل مسائل کاربردی",
      order: 8,
      dialogues: practicalProblemsDialogues,
      estimatedTime: 12,
      keywords: ["مسئله", "کاربرد", "حل تمرین", "نکات امتحان"],
    ),
  ];

  static const String teacherName = "استاد حسینی";
  static const String studentName = "نوید";
  static const String teacherAvatar = "👨‍🏫";
  static const String studentAvatar = "🎓";

  static final List<DialogueMessage> setsIntroDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "سلام نوید! امروز می‌خواهیم با مفهوم مجموعه آشنا بشیم. تا حالا کلمه مجموعه رو شنیدی؟",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message:
          "سلام استاد! آره، مثل مجموعه اعداد فرد یا زوج. اما دقیق نمی‌دونم چطور تعریفش کنم.",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "عالی! **تعریف رسمی:** مجموعه یعنی مجموعه‌ای از اشیاء، عناصر، یا اعضای مشخص و متمایز که با هم گروه‌بندی شده‌اند.",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال‌های مجموعه:\n• A = {1, 2, 3, 4} - مجموعه اعداد\n• B = {a, b, c, d} - مجموعه حروف\n• C = {قرمز، آبی، سبز} - مجموعه رنگ‌ها",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس اون علامت {} یعنی مجموعه؟ و اون اعداد توش، عناصر مجموعه‌ن؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً! **{} = کروشه** علامت مجموعه است. هر چیز داخلش یک **عنصر یا عضو** نامیده می‌شود.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "نماد عضویت:\n• x ∈ A  ← x عضو مجموعه A است\n• y ∉ A  ← y عضو مجموعه A نیست",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "بیا با مثال کاملتر یادبگیریم. A = {1, 2, 3, 4} رو در نظر بگیر:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3, 4}\n\n✅ درست:\n• 1 ∈ A (یک عضو A است)\n• 3 ∈ A (سه عضو A است)\n\n❌ غلط:\n• 5 ∉ A (پنج عضو A نیست)\n• 0 ∉ A (صفر عضو A نیست)",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message:
          "حالا فهمیدم! پس اگه بخوام مجموعه اعداد زوج کوچکتر از 10 رو بنویسم؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "آفرین! دو طریقه داریم:\n**روش 1:** فهرست کردن = {0, 2, 4, 6, 8}\n**روش 2:** ویژگی = {x | x زوج و x < 10}",
      isTeacher: true,
      hasExample: true,
      example:
          "روش‌های نمایش مجموعه:\n1️⃣ فهرست‌گذاری: {0, 2, 4, 6, 8}\n2️⃣ ویژگی: {x | x زوج، x < 10}\n3️⃣ نمودار ون\n4️⃣ توصیف کلامی",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "اون علامت | یعنی چی استاد؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "علامت | یعنی **چنان که** یا **به طوری که**. {x | شرط} یعنی همه x هایی که در شرط صدق می‌کنند.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "{x | شرط} خوانده می‌شود:\n\"مجموعه همه x هایی که در شرط صدق می‌کنند\"",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **مجموعه خالی** هم داریم. وقتی هیچ عنصری نداشته باشیم: ∅ یا {}",
      isTeacher: true,
      hasExample: true,
      example:
          "مجموعه خالی:\n• نماد: ∅ یا {}\n• مثال: {x | x² = -1, x ∈ ℝ}\n• توضیح: هیچ عدد حقیقی نداریم که مربعش منفی باشد",
    ),
  ];

  static final List<DialogueMessage> setPropertiesDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **خصوصیات اساسی مجموعه‌ها** رو یاد بگیریم. اولین خصوصیت: **ترتیب مهم نیست!**",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "یعنی چی استاد؟ مگه فرقی نمی‌کنه اول 1 بیاد یا اول 3؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "نه! **خصوصیت 1:** در مجموعه ترتیب اهمیت ندارد. همه اینها برابرند:",
      isTeacher: true,
      hasExample: true,
      example:
          "ترتیب مهم نیست:\n{1, 2, 3} = {3, 1, 2} = {2, 3, 1} = {1, 3, 2}\n\nهمه یک مجموعه‌اند!",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**خصوصیت 2:** تکرار وجود ندارد. هر عنصر فقط یکبار حساب میشه.",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس اگه بنویسم {1, 2, 2, 3} اشتباهه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "نه اشتباه نیست، ولی **ساده میشه** به {1, 2, 3}. چون تکرار معنا نداره:",
      isTeacher: true,
      hasExample: true,
      example:
          "تکرار معنا ندارد:\n{1, 2, 2, 3} = {1, 2, 3}\n{a, a, b, c, c} = {a, b, c}\n{5, 5, 5, 5} = {5}",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**خصوصیت 3:** عناصر مجموعه باید **کاملاً مشخص** باشند. نمی‌تونیم بگیم {اعداد بزرگ}",
      isTeacher: true,
      hasExample: true,
      example:
          "✅ مشخص: {1, 2, 3}, {اعداد فرد < 10}\n❌ نامشخص: {اعداد بزرگ}, {آدم‌های قدبلند}",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "چرا {اعداد بزرگ} مشخص نیست؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "چون **\"بزرگ\"** نسبی‌ست! برای کسی 100 بزرگه، برای کسی 1000000. باید معیار مشخص باشه.",
      isTeacher: true,
      hasExample: true,
      example:
          "درست کردن:\n❌ {اعداد بزرگ}\n✅ {x | x > 1000}\n\n❌ {دانشجوهای خوب}\n✅ {دانشجویانی که نمره > 17 دارند}",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**خصوصیت 4:** برابری مجموعه‌ها. دو مجموعه برابرند اگر دقیقاً همان عناصر را داشته باشند.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "A = B ⟺ (هر عنصر A در B هست) و (هر عنصر B در A هست)\n\nبه عبارت ریاضی:\nA = B ⟺ (A ⊆ B و B ⊆ A)",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس {1, 2} و {2, 1} برابرن؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "کاملاً درست! {1, 2} = {2, 1} چون هر دو شامل عناصر 1 و 2 هستند.",
      isTeacher: true,
    ),
  ];

  static final List<DialogueMessage> setOperationsDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **عملیات روی مجموعه‌ها** رو یاد بگیریم! مثل جمع و تفریق اعداد، برای مجموعه‌ها هم عملیات داریم.",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "واقعاً؟ میشه مجموعه‌ها رو با هم جمع کرد؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "بله! اولین عملیات **اجتماع (Union)** است. A ∪ B یعنی همه عناصری که در A یا B یا هر دو هستند:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "اجتماع (Union):\nA ∪ B = {x | x ∈ A یا x ∈ B}\n\nخوانده می‌شود: \"A اجتماع B\"",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال: A = {1, 2, 3} و B = {3, 4, 5} باشد:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3}, B = {3, 4, 5}\n\nA ∪ B = {1, 2, 3, 4, 5}\n\n💡 توجه: عنصر 3 که در هر دو مجموعه بود، فقط یکبار در نتیجه آمد!",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس چی میشه اگه فقط عناصر مشترک رو بخوایم؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "سؤال عالی! این **اشتراک (Intersection)** است. A ∩ B یعنی عناصری که **هم در A هم در B** هستند:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "اشتراک (Intersection):\nA ∩ B = {x | x ∈ A و x ∈ B}\n\nخوانده می‌شود: \"A اشتراک B\"",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "همان مثال قبلی:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3}, B = {3, 4, 5}\n\nA ∩ B = {3}\n\nفقط عنصر 3 در هر دو مجموعه موجود است.",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**تفاضل مجموعه‌ها** هم داریم: A - B یا A \\ B یعنی عناصری که در A هستند ولی در B نیستند:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "تفاضل (Difference):\nA - B = {x | x ∈ A و x ∉ B}\n\nخوانده می‌شود: \"A منهای B\"",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3}, B = {3, 4, 5}\n\nA - B = {1, 2}\nB - A = {4, 5}\n\n⚠️ توجه: A - B ≠ B - A",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "متمم چی هست استاد؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**متمم (Complement):** فرض کن مجموعه کل U داریم. متمم A یعنی همه عناصر U که در A نیستند:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "متمم (Complement):\nA' = U - A = {x | x ∈ U و x ∉ A}\n\nیا نماد: A^c, A̅, ~A",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال عملی:",
      isTeacher: true,
      hasExample: true,
      example:
          "U = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10} (اعداد 1 تا 10)\nA = {2, 4, 6, 8, 10} (اعداد زوج)\n\nA' = {1, 3, 5, 7, 9} (اعداد فرد)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**قوانین مهم عملیات:**",
      isTeacher: true,
      hasFormula: true,
      formula:
          "قوانین اساسی:\n• A ∪ A = A (خود جذبی)\n• A ∩ A = A (خود جذبی)\n• A ∪ ∅ = A (عنصر خنثی)\n• A ∩ U = A (عنصر خنثی)\n• A ∪ A' = U (متمم)\n• A ∩ A' = ∅ (متمم)",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "این قوانین عین جبر معمولی‌ن! جالبه!",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "دقیقاً! **قوانین دمورگان** هم داریم - خیلی مهمن برای امتحان:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "قوانین دمورگان:\n(A ∪ B)' = A' ∩ B'\n(A ∩ B)' = A' ∪ B'\n\nبه زبان ساده:\n\"متمم اجتماع = اشتراک متمم‌ها\"",
    ),
  ];

  static final List<DialogueMessage> finiteInfiniteDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا بحث **متناهی و نامتناهی بودن** مجموعه‌ها! این مفهوم توی بسیاری از علوم مهمه.",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "متناهی یعنی محدوده؟ نامتناهی یعنی بی‌نهایت؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "درست فکر می‌کنی! **مجموعه متناهی:** تعداد عناصرش عدد طبیعی مشخصی است:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "مجموعه متناهی:\n|A| = n (n ∈ ℕ ∪ {0})\n\nیعنی می‌توان عناصرش را شمرد و به عدد مشخصی رسید",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال‌های مجموعه متناهی:",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال‌های متناهی:\n• A = {1, 2, 3} → |A| = 3\n• B = ∅ → |B| = 0\n• C = {دانشجوهای کلاس ما} → |C| = 30\n• D = {روزهای هفته} → |D| = 7",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**مجموعه نامتناهی:** تعداد عناصرش قابل شمارش با اعداد طبیعی نیست:",
      isTeacher: true,
      hasFormula: true,
      formula: "مجموعه نامتناهی:\n|A| = ∞\n\nنمی‌توان همه عناصرش را فهرست کرد",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "مثل مجموعه اعداد طبیعی؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "بله! مثال‌های عالی:",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال‌های نامتناهی:\n• ℕ = {1, 2, 3, ...}\n• ℤ = {..., -2, -1, 0, 1, 2, ...}\n• ℝ = اعداد حقیقی\n• {x | x > 0}\n• {اعداد اول}",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**نکته جالب:** نامتناهی هم انواع داره! **شمارش‌پذیر** و **شمارش‌ناپذیر**:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "انواع نامتناهی:\n• شمارش‌پذیر: مثل ℕ، ℤ، ℚ\n• شمارش‌ناپذیر: مثل ℝ، فاصله [0,1]",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "فرقشون چیه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**شمارش‌پذیر:** می‌شه با ℕ تناظر برقرار کرد (حتی اگه نامتناهی باشه)\n**شمارش‌ناپذیر:** حتی با ℕ هم تناظر برقرار نمیشه!",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال جالب:\n• ℚ (کسرها) نامتناهی ولی شمارش‌پذیر!\n• ℝ (اعداد حقیقی) شمارش‌ناپذیر\n• حتی فاصله کوچک [0,1] شمارش‌ناپذیره!",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**کاربرد عملی:** در برنامه‌نویسی و پایگاه داده این مفاهیم خیلی مهمن:",
      isTeacher: true,
      hasExample: true,
      example:
          "کاربردها:\n• آرایه‌ها: مجموعه متناهی\n• لیست‌های بینامتناهی در برنامه‌نویسی\n• فضای جستجو در الگوریتم‌ها\n• مجموعه حالات در ماشین‌های اتوماتا",
    ),
  ];

  static final List<DialogueMessage> subsetsDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا برسیم به **زیرمجموعه**. فرض کن A = {1, 2, 3, 4} داریم و B = {1, 3}. نظرت چیه؟",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "همه عناصر B (یعنی 1 و 3) توی A هستن! پس B یه قسمت از A هست؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "بله! **تعریف زیرمجموعه:** اگر همه عناصر B در A موجود باشند، می‌گوییم B زیرمجموعه A است.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "B ⊆ A ⟺ (∀x)(x ∈ B → x ∈ A)\n\nخوانده می‌شود: \"B زیرمجموعه A است\"",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "بیا همه زیرمجموعه‌های A = {1, 2, 3} رو پیدا کنیم:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3}\n\nهمه زیرمجموعه‌های A:\n• ∅ (مجموعه خالی)\n• {1}\n• {2} \n• {3}\n• {1, 2}\n• {1, 3}\n• {2, 3}\n• {1, 2, 3} (خود A)",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "چرا مجموعه خالی و خود A هم زیرمجموعه محسوب میشن؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "سؤال عالی! **مجموعه خالی:** زیرمجموعه همه مجموعه‌هاست چون هیچ عنصری نداره که مخالف باشه!\n**خود A:** چون همه عناصرش توی خودش هست!",
      isTeacher: true,
      hasFormula: true,
      formula:
          "قوانین مهم:\n• ∅ ⊆ A (برای هر مجموعه A)\n• A ⊆ A (هر مجموعه زیرمجموعه خودش است)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **زیرمجموعه محض** رو ببین. اگه B ⊆ A ولی B ≠ A باشه، میگیم B زیرمجموعه محض A هست:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "زیرمجموعه محض:\nB ⊂ A ⟺ (B ⊆ A) و (B ≠ A)\n\nیعنی B زیرمجموعه A است ولی برابر A نیست",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس فرق ⊆ و ⊂ اینه که یکی برابری رو شامل میشه و یکی نه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً! مثل ≤ و < توی اعداد:\n• A ⊆ B: برابری مجاز\n• A ⊂ B: برابری مجاز نیست",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال:\nA = {1, 2}, B = {1, 2, 3}\n\n✅ A ⊆ B (درست)\n✅ A ⊂ B (درست)\n\nولی:\nA = {1, 2}, B = {1, 2}\n\n✅ A ⊆ B (درست)\n❌ A ⊂ B (غلط، چون A = B)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **مجموعه توانی** - یکی از مهم‌ترین مفاهیم! اگه A = {1, 2} باشه:",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**تعریف:** مجموعه توانی A شامل **همه** زیرمجموعه‌های A است. نمادش P(A) یا 2^A:",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2}\n\nP(A) = { ∅, {1}, {2}, {1,2} }\n\n✨ توضیح:\n• ∅ → زیرمجموعه خالی\n• {1} → زیرمجموعه شامل فقط 1\n• {2} → زیرمجموعه شامل فقط 2  \n• {1,2} → خود A",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس P(A) خودش یه مجموعه است که عناصرش، مجموعه‌ن؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "آفرین! دقیقاً. P(A) **مجموعه‌ای از مجموعه‌ها** است. برای مثال: {1} ∈ P(A)",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال بزرگتر:\nA = {a, b, c}\n\nP(A) = {\n  ∅,\n  {a}, {b}, {c},\n  {a,b}, {a,c}, {b,c},\n  {a,b,c}\n}\n\nتعداد عناصر P(A) = 2³ = 8",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**فرمول مهم:** اگر A دارای n عنصر باشد، آنگاه P(A) دارای 2^n عنصر است.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "|A| = n ⟹ |P(A)| = 2ⁿ\n\nمثال‌ها:\n• A = {1} ⟹ |P(A)| = 2¹ = 2\n• A = {1,2} ⟹ |P(A)| = 2² = 4\n• A = {1,2,3} ⟹ |P(A)| = 2³ = 8",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "چرا 2 به توان n؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "چون برای **هر عنصر** دو انتخاب داریم: یا توی زیرمجموعه باشه، یا نباشه. n عنصر ⟹ 2×2×...×2 = 2^n",
      isTeacher: true,
      hasExample: true,
      example:
          "A = {1, 2, 3}\n\nبرای ساخت هر زیرمجموعه:\n• عنصر 1: بگیریم یا نگیریم؟ (2 حالت)\n• عنصر 2: بگیریم یا نگیریم؟ (2 حالت)  \n• عنصر 3: بگیریم یا نگیریم؟ (2 حالت)\n\nکل: 2 × 2 × 2 = 8 حالت",
    ),
  ];

  static final List<DialogueMessage> functionsDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا برسیم به **تابع** - یکی از مهم‌ترین مفاهیم ریاضی! تابع یه **رابطه خاص** بین دو مجموعه‌ست.",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "مثل f(x) = 2x که توی ریاضی داشتیم؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً! **تعریف رسمی:** تابع f از مجموعه A به مجموعه B قاعده‌ای است که به هر عنصر x در A، دقیقاً یک عنصر در B نسبت می‌دهد.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "f: A → B\n\n• A: دامنه (Domain)\n• B: برد (Range/Codomain)\n• f(x): تصویر x در B",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**کلید مهم:** به هر ورودی **فقط یک** خروجی! نه بیشتر، نه کمتر.",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال تابع:\nf: {1,2,3} → {2,4,6}\nf(1) = 2\nf(2) = 4  \nf(3) = 6\n\nیا به صورت کلی: f(x) = 2x",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس اگه یه عنصر دو تا خروجی داشته باشه، تابع نیست؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "دقیقاً! این **شرط اساسی تابع** است:",
      isTeacher: true,
      hasExample: true,
      example:
          "✅ تابع:\n• f(1) = 5\n• f(2) = 7\n• f(3) = 5  ← اشکال نداره، دو ورودی یک خروجی\n\n❌ تابع نیست:\n• f(1) = 5\n• f(1) = 7  ← غلط! یک ورودی دو خروجی",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا **انواع تابع** رو ببینیم. **تابع یک به یک (تزریقی):** اگر عناصر مختلف، تصاویر مختلف داشته باشند.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "f یک به یک ⟺ (∀x₁,x₂ ∈ A)(x₁ ≠ x₂ → f(x₁) ≠ f(x₂))\n\nیا معادل:\nf(x₁) = f(x₂) → x₁ = x₂",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "یعنی هر خروجی فقط یه ورودی داشته باشه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "آفرین! مثال:",
      isTeacher: true,
      hasExample: true,
      example:
          "✅ یک به یک:\nf(1) = 2, f(2) = 4, f(3) = 6\nهر خروجی یک ورودی دارد\n\n❌ یک به یک نیست:\nf(1) = 5, f(2) = 7, f(3) = 5\nخروجی 5 دو ورودی دارد (1 و 3)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**تابع پوشا (تصویری):** اگر هر عنصر B حداقل یک ریشه در A داشته باشد.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "f: A → B پوشا ⟺ (∀y ∈ B)(∃x ∈ A)(f(x) = y)\n\nیعنی برد تابع = کل مجموعه B",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**تابع دوسویه (یکتا):** هم یک به یک، هم پوشا.",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال تابع دوسویه:\nf: {1,2,3} → {a,b,c}\nf(1) = a, f(2) = b, f(3) = c\n\n✅ یک به یک: ورودی‌های مختلف → خروجی‌های مختلف\n✅ پوشا: هر خروجی حداقل یک ورودی دارد",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "چرا تابع دوسویه مهمه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "چون **معکوس** داره! اگه f دوسویه باشه، می‌تونیم f⁻¹ رو تعریف کنیم:",
      isTeacher: true,
      hasFormula: true,
      formula:
          "اگر f: A → B دوسویه باشد:\nf⁻¹: B → A\n\nطوری که: f⁻¹(f(x)) = x",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "آخر اینکه، **ترکیب تابع** هم داریم:",
      isTeacher: true,
      hasExample: true,
      example:
          "اگر f: A → B و g: B → C\nآنگاه g∘f: A → C\n\n(g∘f)(x) = g(f(x))\n\nمثال:\nf(x) = 2x, g(x) = x + 1\n(g∘f)(3) = g(f(3)) = g(6) = 7",
    ),
  ];

  static final List<DialogueMessage> languageDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "آخرین بخش امروز: **زبان، گرامر و ماشین** - پایه‌های علوم کامپیوتر!",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "مثل زبان فارسی یا انگلیسی؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "شبیه، ولی در علوم کامپیوتر **زبان** یعنی مجموعه‌ای از رشته‌های معتبر روی یک الفبا.",
      isTeacher: true,
      hasFormula: true,
      formula:
          "تعاریف پایه:\n• الفبا (Σ): مجموعه نمادها\n• رشته: دنباله‌ای از نمادهای الفبا\n• زبان (L): مجموعه‌ای از رشته‌های معتبر",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال ساده: الفبا = {a, b}",
      isTeacher: true,
      hasExample: true,
      example:
          "Σ = {a, b}\n\nرشته‌های ممکن:\n• ε (رشته خالی)\n• a, b\n• aa, ab, ba, bb  \n• aaa, aab, aba, abb, baa, bab, bba, bbb\n• ...\n\nزبان ممکن: L = {a, aa, aaa, ...} (رشته‌هایی که فقط شامل a هستند)",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس زبان یه **قانون** داره که میگه کدوم رشته‌ها قبولن؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً! و اون قانون رو **گرامر** می‌سازه. گرامر **دستور تولید** رشته‌های معتبر رو می‌ده.",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**گرامر** شامل چهار جزء است: G = (V, T, P, S)",
      isTeacher: true,
      hasFormula: true,
      formula:
          "اجزای گرامر:\n• V: متغیرها (نمادهای غیر پایانی)\n• T: پایانی‌ها (الفبا)\n• P: قوانین تولید  \n• S: نماد شروع",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "مثال گرامر برای زبان {a, aa, aaa, ...}:",
      isTeacher: true,
      hasExample: true,
      example:
          "G = (V, T, P, S)\n\nV = {S}      ← متغیر\nT = {a}      ← الفبا\nS = S        ← نماد شروع\nP = {        ← قوانین:\n  S → a      ← تولید یک a\n  S → aS     ← تولید a + ادامه\n}",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "چطور از این گرامر رشته \"aaa\" رو بسازیم؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "عالی! بیا **مرحله به مرحله اشتقاق** کنیم:",
      isTeacher: true,
      hasExample: true,
      example:
          "اشتقاق \"aaa\":\n\nS                    ← شروع\n⇒ aS     (S → aS)   ← اولین قانون  \n⇒ aaS    (S → aS)   ← دومین قانون\n⇒ aaa    (S → a)    ← سومین قانون\n\n✅ پس \"aaa\" جزو زبان است!",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "حالا **ماشین** چیه؟ ماشین **تشخیص‌دهنده** است - مثل یه قاضی!",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**نقش ماشین:** یه رشته بهش می‌دیم، می‌گه آیا جزو زبان هست یا نه.",
      isTeacher: true,
      hasExample: true,
      example:
          "مثال ماشین برای زبان {aⁿ | n ≥ 1}:\n\nورودی: \"aaa\"  → ✅ قبول\nورودی: \"ab\"   → ❌ رد\nورودی: \"bb\"   → ❌ رد\nورودی: \"a\"    → ✅ قبول",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "پس گرامر **می‌سازه** و ماشین **تشخیص می‌ده**؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "عالی خلاصه کردی! درست همینطوره:",
      isTeacher: true,
      hasExample: true,
      example:
          "خلاصه:\n\n🏗️ گرامر:\n• رشته‌های معتبر رو **تولید** می‌کنه\n• قوانین ساخت رو مشخص می‌کنه\n\n🔍 ماشین:\n• رشته‌ها رو **بررسی** می‌کنه  \n• تصمیم می‌گیره: قبول یا رد\n\n🎯 زبان:\n• مجموعه نهایی رشته‌های معتبر",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**کاربردها** خیلی زیاده: زبان‌های برنامه‌نویسی، پردازش متن، هوش مصنوعی...",
      isTeacher: true,
      hasExample: true,
      example:
          "کاربردهای واقعی:\n\n💻 زبان‌های برنامه‌نویسی:\n• Java، Python، C++ همه گرامر دارن\n\n🔍 موتورهای جستجو:\n• الگوهای جستجو\n\n🤖 پردازش زبان طبیعی:\n• ترجمه خودکار، تشخیص گفتار\n\n📱 اپلیکیشن‌ها:\n• اعتبارسنجی ایمیل، شماره موبایل",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message:
          "واقعاً جالبه! پس هر چیزی که با کامپیوتر کار می‌کنه، از این مفاهیم استفاده می‌کنه؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً نوید! این **پایه و اساس** علوم کامپیوتر هست. حالا که اصول رو فهمیدی، می‌تونی مفاهیم پیچیده‌تر رو یاد بگیری! 🎉",
      isTeacher: true,
    ),
  ];

  static final List<DialogueMessage> practicalProblemsDialogues = [
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "حالا بیاید با **حل مسائل کاربردی** همه چیزهایی که یاد گرفتیم رو تمرین کنیم! 🎯",
      isTeacher: true,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "عالی! من همیشه با مسائل بهتر یاد می‌گیرم.",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**مسئله 1:** در یک کلاس 30 نفره، 18 نفر ریاضی قبول شدن، 20 نفر فیزیک قبول شدن، و 25 نفر حداقل یک درس قبول شدن. چند نفر هر دو درس رو قبول شدن؟",
      isTeacher: true,
      type: MessageType.question,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message:
          "اول باید ببینم f چطور عمل می‌کنه. f(1) = 2, f(2) = 3, f(3) = 4, f(4) = 5, f(5) = 1؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "عالی! حالا بررسی کن:",
      isTeacher: true,
      hasExample: true,
      example:
          "بررسی تابع f(x) = x + 1 (mod 5):\n\nf(1) = 2, f(2) = 3, f(3) = 4, f(4) = 5, f(5) = 1\n\n🔍 یک به یک؟ بله! (هر خروجی یک ورودی)\n🔍 پوشا؟ بله! (همه عناصر A تصویر دارند)\n\n✅ نتیجه: f دوسویه است و معکوس دارد!\n✅ f⁻¹(x) = x - 1 (mod 5)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**مسئله 3:** گرامری بنویس که زبان L = {aⁿbⁿ | n ≥ 1} را تولید کند. (مثل ab, aabb, aaabbb)",
      isTeacher: true,
      type: MessageType.question,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "باید قانونی باشه که تعداد a ها و b ها برابر باشه...",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "درست فکر می‌کنی! این یه گرامر **متنی آزاد (Context-Free)** است:",
      isTeacher: true,
      hasExample: true,
      example:
          "گرامر برای L = {aⁿbⁿ | n ≥ 1}:\n\nG = (V, T, P, S)\nV = {S}\nT = {a, b}\nP = {\n  S → ab      ← حالت پایه\n  S → aSb     ← بازگشتی\n}\n\nاشتقاق \"aaabbb\":\nS ⇒ aSb ⇒ aaSbb ⇒ aaabbb ✅",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**مسئله 4:** اگر A = {x, y} باشد، P(P(A)) چند عنصر دارد؟",
      isTeacher: true,
      type: MessageType.question,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "وای! این پیچیده‌ست. اول باید P(A) رو پیدا کنم، بعد P(P(A)) رو؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "دقیقاً! بیا قدم به قدم:",
      isTeacher: true,
      hasExample: true,
      example:
          "حل مرحله‌ای:\n\n1️⃣ A = {x, y} → |A| = 2\n\n2️⃣ P(A) = {∅, {x}, {y}, {x,y}} → |P(A)| = 4\n\n3️⃣ |P(P(A))| = 2⁴ = 16\n\nیا فرمول کلی: |P(P(A))| = 2^(2^n)\nبرای n = 2: 2^(2²) = 2⁴ = 16 ✅",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "**مسئله 5 - چالش نهایی:** یک شرکت نرم‌افزاری می‌خواهد سیستم اعتبارسنجی رمز عبور طراحی کنه. رمز باید شامل حداقل یک حرف بزرگ، یک حرف کوچک و یک رقم باشه. چطور این رو با مفاهیم امروز مدل کنیم؟",
      isTeacher: true,
      type: MessageType.question,
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "این خیلی کاربردی‌ست! باید مجموعه‌ها و زبان رسمی استفاده کنم؟",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "عالی! بیا کامل مدلش کنیم:",
      isTeacher: true,
      hasExample: true,
      example:
          "مدل‌سازی سیستم رمز:\n\n📝 الفبا:\nΣ = {A,B,...,Z} ∪ {a,b,...,z} ∪ {0,1,...,9}\n\n📝 مجموعه‌ها:\n• U = حروف بزرگ = {A,B,...,Z}\n• L = حروف کوچک = {a,b,...,z}  \n• D = ارقام = {0,1,...,9}\n\n📝 شرط معتبر:\nرمز معتبر ⟺ (حداقل یک عنصر از U) ∩\n                (حداقل یک عنصر از L) ∩  \n                (حداقل یک عنصر از D)",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "و **ماشین محدود** برای تشخیص:",
      isTeacher: true,
      hasExample: true,
      example:
          "ماشین تشخیص رمز:\n\n🔄 حالات:\n• q₀: شروع\n• q₁: دیده حرف بزرگ\n• q₂: دیده حرف کوچک\n• q₃: دیده رقم\n• q₇: همه شروط OK (قبول)\n\n🎯 انتقالات:\n• از هر حالت، با دیدن نماد مربوطه، فلگ اون شرط فعال میشه\n• وقتی هر 3 فلگ فعال شد → قبول!",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message: "واو! پس همه این مفاهیم توی دنیای واقعی کاربرد دارن!",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "دقیقاً نوید! **از پایگاه داده تا هوش مصنوعی، از شبکه تا امنیت** - همه جا این مفاهیم هستن:",
      isTeacher: true,
      hasExample: true,
      example:
          "کاربردهای واقعی بیشتر:\n\n🔐 امنیت:\n• کنترل دسترسی، احراز هویت\n• الگوریتم‌های رمزنگاری\n\n🌐 شبکه:\n• پروتکل‌های ارتباطی\n• مسیریابی و توزیع بار\n\n🤖 هوش مصنوعی:\n• پردازش زبان طبیعی\n• الگوریتم‌های یادگیری\n\n📊 پایگاه داده:\n• طراحی جداول\n• کوئری‌ها و ایندکس‌ها",
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message: "**نکات طلایی برای امتحان:** 📝",
      isTeacher: true,
      hasExample: true,
      type: MessageType.tip,
      example:
          "🏆 نکات امتحانی مهم:\n\n1️⃣ فرمول |P(A)| = 2ⁿ حفظ کنید\n2️⃣ قوانین دمورگان اکثراً میاد\n3️⃣ تفاوت ⊆ و ⊂ رو یادتون باشه\n4️⃣ در مسائل تابع، همیشه بررسی کنید: یک به یک؟ پوشا؟\n5️⃣ برای گرامر، اشتقاق کامل بنویسید\n6️⃣ مسائل ترکیبی مجموعه‌ها خیلی میان",
    ),
    DialogueMessage(
      speaker: studentName,
      avatar: studentAvatar,
      message:
          "ممنونم استاد! امروز واقعاً چیزهای زیادی یاد گرفتم. حس می‌کنم این مفاهیم رو بتونم توی برنامه‌نویسی هم استفاده کنم!",
      isTeacher: false,
    ),
    DialogueMessage(
      speaker: teacherName,
      avatar: teacherAvatar,
      message:
          "عالی نوید! این همان هدف ما بود. **ریاضیات نه فقط تئوری، بلکه ابزار قدرتمند حل مسئله** است. برای جلسه بعد آماده باش - موضوعات جذاب‌تری در راهه! 🚀",
      isTeacher: true,
      type: MessageType.summary,
    ),
  ];

  static const String lessonSummary = """
🎯 خلاصه کامل درس: مقدمات ریاضی و مجموعه‌ها

📚 آنچه یاد گرفتیم:

1️⃣ مجموعه‌ها:
   • تعریف و خصوصیات اساسی (ترتیب، تکرار، مشخص بودن)
   • نحوه نمایش و علائم مربوطه (∈, ∉, {}, ∅)
   • مجموعه خالی و برابری مجموعه‌ها

2️⃣ عملیات روی مجموعه‌ها:
   • اجتماع (∪) و اشتراک (∩)
   • تفاضل (-) و متمم (')
   • قوانین دمورگان و خصوصیات عملیات

3️⃣ زیرمجموعه و مجموعه توانی:
   • مفهوم زیرمجموعه (⊆) و زیرمجموعه محض (⊂)
   • مجموعه توانی P(A) و فرمول طلایی |P(A)| = 2ⁿ
   • کاربردها و مثال‌های عملی

4️⃣ مجموعه‌های متناهی و نامتناهی:
   • تفاوت متناهی و نامتناهی
   • شمارش‌پذیر و شمارش‌ناپذیر
   • کاربردهای عملی در علوم کامپیوتر

5️⃣ توابع:
   • تعریف و انواع تابع (یک به یک، پوشا، دوسویه)
   • دامنه و برد، تابع معکوس
   • ترکیب توابع و خصوصیات آن‌ها

6️⃣ زبان و گرامر:
   • مفاهیم پایه‌ای زبان‌های رسمی (الفبا، رشته، زبان)
   • گرامر و قوانین تولید (V, T, P, S)
   • ماشین‌ها و تشخیص زبان، اشتقاق

7️⃣ حل مسائل کاربردی:
   • مسائل ترکیبی و کاربردهای واقعی
   • مدل‌سازی مسائل با مجموعه‌ها
   • نکات امتحانی و تکنیک‌های حل

🔑 فرمول‌های کلیدی:
   • |A ∪ B| = |A| + |B| - |A ∩ B|
   • |P(A)| = 2ⁿ
   • (A ∪ B)' = A' ∩ B' (دمورگان)
   • A = B ⟺ A ⊆ B و B ⊆ A

🚀 برای درس بعد آماده باشید!
  """;

  static final List<ImportantNote> importantNotes = [
    ImportantNote(
      title: "⚠️ خطای رایج: تکرار در مجموعه",
      content: "یادتان باشد مجموعه‌ها تکرار ندارند. {1, 2, 2, 3} = {1, 2, 3}",
      type: "warning",
    ),
    ImportantNote(
      title: "💡 نکته مهم: مجموعه خالی",
      content:
          "مجموعه خالی (∅) زیرمجموعه همه مجموعه‌هاست و این مورد در امتحانات پرسیده می‌شود.",
      type: "tip",
    ),
    ImportantNote(
      title: "🔥 فرمول طلایی",
      content: "تعداد زیرمجموعه‌های یک مجموعه n عضوی برابر 2^n است.",
      type: "formula",
    ),
    ImportantNote(
      title: "⚡ تفاوت مهم",
      content:
          "⊆ (زیرمجموعه) برابری را شامل می‌شود، ⊂ (زیرمجموعه محض) شامل نمی‌شود.",
      type: "important",
    ),
    ImportantNote(
      title: "🎯 کلید تابع",
      content:
          "در تابع، به هر ورودی دقیقاً یک خروجی تعلق می‌گیرد. نه بیشتر، نه کمتر!",
      type: "key",
    ),
    ImportantNote(
      title: "🧠 قوانین دمورگان",
      content: "متمم اجتماع = اشتراک متمم‌ها: (A∪B)' = A'∩B' و (A∩B)' = A'∪B'",
      type: "formula",
    ),
    ImportantNote(
      title: "⚙️ تابع دوسویه",
      content: "تابع دوسویه = یک به یک + پوشا. فقط این توابع معکوس دارند!",
      type: "key",
    ),
    ImportantNote(
      title: "📝 اشتقاق در گرامر",
      content:
          "همیشه مراحل اشتقاق را کامل بنویسید و قانون استفاده شده را مشخص کنید.",
      type: "tip",
    ),
  ];

  static final List<QuizQuestion> quizQuestions = [
    QuizQuestion(
      id: "q1",
      context: "استاد حسینی می‌پرسد:",
      question: "کدام گزینه یک مجموعه معتبر است؟",
      options: [
        "{1, 2, 3, 4}",
        "{a, b, c, a}",
        "مجموعه اعداد زوج کوچکتر از 10",
        "گزینه 1 و 3",
      ],
      correctAnswer: 3,
      explanation:
          "نوید جواب می‌دهد: گزینه 2 نادرست است چون 'a' تکرار شده و در مجموعه تکرار مجاز نیست.",
      teacherResponse: "آفرین نوید! دقیقاً درسته. مجموعه‌ها تکرار ندارند.",
      difficulty: 1,
      topics: ["مجموعه", "خصوصیات"],
    ),
    QuizQuestion(
      id: "q2",
      context: "استاد حسینی سؤال بعدی را می‌پرسد:",
      question: "اگر A = {1, 2, 3} باشد، کدام گزینه زیرمجموعه A است؟",
      options: ["{1, 2}", "{1, 4}", "{1, 2, 3, 4}", "هیچ کدام"],
      correctAnswer: 0,
      explanation:
          "نوید: چون همه عناصر {1, 2} داخل A هستند، پس {1, 2} ⊆ A است.",
      teacherResponse: "عالی! حالا فهمیدی مفهوم زیرمجموعه رو.",
      difficulty: 1,
      topics: ["زیرمجموعه"],
    ),
    QuizQuestion(
      id: "q3",
      context: "استاد حسینی می‌پرسد:",
      question: "اگر A = {x, y} باشد، مجموعه توانی P(A) چند عنصر دارد؟",
      options: ["2 عنصر", "3 عنصر", "4 عنصر", "5 عنصر"],
      correctAnswer: 2,
      explanation:
          "نوید حساب می‌کند: P(A) = { ∅, {x}, {y}, {x,y} } پس 4 عنصر دارد!",
      teacherResponse:
          "فوق‌العاده! فرمولش 2^n هست که n تعداد عناصر مجموعه اصلیه.",
      difficulty: 2,
      topics: ["مجموعه توانی", "فرمول"],
    ),
    QuizQuestion(
      id: "q4",
      context: "نوید کنجکاو می‌پرسد:",
      question: "اگر A = {1, 2, 3} و B = {2, 3, 4} باشد، A ∪ B کدام است؟",
      options: ["{1, 2, 3, 4}", "{2, 3}", "{1, 4}", "{1, 2, 2, 3, 3, 4}"],
      correctAnswer: 0,
      explanation:
          "استاد توضیح می‌دهد: اجتماع شامل همه عناصری است که در A یا B یا هر دو باشند.",
      teacherResponse: "درست! و یادت باشه که تکرار نداریم، پس {1,2,3,4} میشه.",
      difficulty: 2,
      topics: ["عملیات مجموعه", "اجتماع"],
    ),
    QuizQuestion(
      id: "q5",
      context: "استاد حسینی سؤال نهایی را می‌پرسد:",
      question:
          "تابع f: {1,2,3} → {a,b,c} با f(1)=a, f(2)=b, f(3)=c چه نوع تابعی است؟",
      options: ["فقط یک به یک", "فقط پوشا", "دوسویه", "هیچ کدام"],
      correctAnswer: 2,
      explanation:
          "نوید: هم یک به یک است (هر خروجی یک ورودی) هم پوشا (همه عناصر برد تصویر دارند).",
      teacherResponse: "تشبیه عالی! پس دوسویه است و معکوس دارد.",
      difficulty: 3,
      topics: ["تابع", "انواع تابع"],
    ),
    QuizQuestion(
      id: "q6",
      context: "استاد حسینی مسئله‌ای از دنیای واقعی می‌پرسد:",
      question:
          "در کلاس 25 نفره، 15 نفر انگلیسی، 12 نفر آلمانی بلدند و 3 نفر هیچ کدام. چند نفر هر دو زبان بلدند؟",
      options: ["3 نفر", "5 نفر", "7 نفر", "8 نفر"],
      correctAnswer: 1,
      explanation:
          "نوید با فرمول حل می‌کند: |E∪G| = 25-3 = 22، پس |E∩G| = 15+12-22 = 5",
      teacherResponse: "عالی! این همان کاربرد عملی مجموعه‌هاست که گفتیم.",
      difficulty: 3,
      topics: ["کاربرد مجموعه", "مسئله کلامی"],
      hint: "از فرمول |A∪B| = |A| + |B| - |A∩B| استفاده کن",
    ),
    QuizQuestion(
      id: "q7",
      context: "نوید در مورد گرامر می‌پرسد:",
      question: "کدام گرامر زبان {ab, aabb, aaabbb, ...} را تولید می‌کند؟",
      options: ["S → ab | aSb", "S → aS | b", "S → Sa | b", "S → ab | abS"],
      correctAnswer: 0,
      explanation:
          "استاد: قانون S → aSb باعث می‌شود تعداد a ها و b ها برابر باشند.",
      teacherResponse: "درست! این یک گرامر متنی آزاد کلاسیک است.",
      difficulty: 3,
      topics: ["گرامر", "زبان رسمی"],
    ),
  ];

  static const Map<String, dynamic> theme = {
    'primaryColor': '#2196F3',
    'secondaryColor': '#FFC107',
    'successColor': '#4CAF50',
    'warningColor': '#FF9800',
    'errorColor': '#F44336',
    'teacherColor': '#1976D2',
    'studentColor': '#388E3C',
    'backgroundColor': '#F5F5F5',
    'cardColor': '#FFFFFF',
    'textColor': '#333333',
    'accentColor': '#9C27B0',
  };

  static const Map<String, List<String>> detailedObjectives = {
    'knowledge': [
      'تعریف دقیق مجموعه و عناصر آن',
      'شناخت انواع مجموعه‌ها (متناهی، نامتناهی، خالی)',
      'درک مفهوم زیرمجموعه و مجموعه توانی',
      'آشنایی با تعریف و انواع توابع',
      'شناخت مفاهیم پایه زبان‌های رسمی',
    ],
    'comprehension': [
      'تفسیر نمادهای ریاضی مجموعه‌ها',
      'درک روابط بین مجموعه‌ها',
      'تشخیص انواع مختلف توابع',
      'فهم ارتباط بین گرامر و زبان',
    ],
    'application': [
      'استفاده از عملیات مجموعه‌ها در حل مسائل',
      'محاسبه مجموعه توانی',
      'تشخیص خصوصیات توابع',
      'نوشتن گرامرهای ساده',
    ],
    'analysis': [
      'تحلیل مسائل پیچیده با مجموعه‌ها',
      'بررسی خصوصیات توابع پیچیده',
      'تجزیه و تحلیل زبان‌های رسمی',
    ],
  };
}

class LessonSection {
  final String id;
  final String title;
  final int order;
  final List<DialogueMessage> dialogues;
  final int estimatedTime;
  final String? summary;
  final List<String>? keywords;
  final List<String>? prerequisites;
  final DifficultyLevel difficulty;

  LessonSection({
    required this.id,
    required this.title,
    required this.order,
    required this.dialogues,
    required this.estimatedTime,
    this.summary,
    this.keywords,
    this.prerequisites,
    this.difficulty = DifficultyLevel.beginner,
  });
}

class DialogueMessage {
  final String speaker;
  final String avatar;
  final String message;
  final bool isTeacher;
  final bool hasExample;
  final String? example;
  final bool hasFormula;
  final String? formula;
  final bool hasImage;
  final String? imagePath;
  final MessageType type;
  final List<String>? tags;
  final DateTime timestamp;

  DialogueMessage({
    required this.speaker,
    required this.avatar,
    required this.message,
    required this.isTeacher,
    this.hasExample = false,
    this.example,
    this.hasFormula = false,
    this.formula,
    this.hasImage = false,
    this.imagePath,
    this.type = MessageType.normal,
    this.tags,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum MessageType {
  normal,
  question,
  answer,
  example,
  formula,
  summary,
  warning,
  tip,
  challenge,
}

enum DifficultyLevel { beginner, intermediate, advanced, expert }

class QuizQuestion {
  final String id;
  final String context;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String teacherResponse;
  final String? hint;
  final int difficulty;
  final List<String> topics;
  final int timeLimit;
  final int points;

  QuizQuestion({
    required this.id,
    required this.context,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.teacherResponse,
    this.hint,
    this.difficulty = 1,
    this.topics = const [],
    this.timeLimit = 60,
    this.points = 10,
  });
}

class ImportantNote {
  final String title;
  final String content;
  final String type;
  final String? relatedSection;
  final Priority priority;

  ImportantNote({
    required this.title,
    required this.content,
    required this.type,
    this.relatedSection,
    this.priority = Priority.medium,
  });
}

enum Priority { low, medium, high, critical }

class ProgressData {
  final String lessonId;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, bool> sectionsCompleted;
  final Map<String, int> quizScores;
  final int totalTimeSpent;
  final Map<String, int> topicMastery;
  final List<String> strengthAreas;
  final List<String> weaknessAreas;

  ProgressData({
    required this.lessonId,
    required this.startTime,
    this.endTime,
    this.sectionsCompleted = const {},
    this.quizScores = const {},
    this.totalTimeSpent = 0,
    this.topicMastery = const {},
    this.strengthAreas = const [],
    this.weaknessAreas = const [],
  });

  double get completionPercentage {
    if (sectionsCompleted.isEmpty) return 0.0;
    final completed = sectionsCompleted.values.where((v) => v).length;
    return completed / sectionsCompleted.length;
  }

  double get averageQuizScore {
    if (quizScores.isEmpty) return 0.0;
    final total = quizScores.values.reduce((a, b) => a + b);
    return total / quizScores.length;
  }

  String get performanceLevel {
    final avgScore = averageQuizScore;
    if (avgScore >= 90) return "عالی";
    if (avgScore >= 75) return "خوب";
    if (avgScore >= 60) return "متوسط";
    return "نیاز به بهبود";
  }
}

class GamificationSystem {
  static const Map<String, Achievement> achievements = {
    'first_lesson': Achievement(
      id: 'first_lesson',
      title: 'شروع قدرتمند! 🚀',
      description: 'اولین درس را کامل کردید',
      points: 100,
      icon: '🏁',
    ),
    'perfect_quiz': Achievement(
      id: 'perfect_quiz',
      title: 'استاد کوچک! 🎯',
      description: 'نمره کامل در آزمون گرفتید',
      points: 200,
      icon: '🏆',
    ),
    'speed_learner': Achievement(
      id: 'speed_learner',
      title: 'یادگیر سریع! ⚡',
      description: 'درس را در کمتر از 30 دقیقه کامل کردید',
      points: 150,
      icon: '🔥',
    ),
    'theory_master': Achievement(
      id: 'theory_master',
      title: 'استاد تئوری! 📚',
      description: 'همه بخش‌های تئوری را کامل کردید',
      points: 300,
      icon: '🧠',
    ),
    'problem_solver': Achievement(
      id: 'problem_solver',
      title: 'حل‌کننده مسائل! 🔧',
      description: 'همه مسائل کاربردی را حل کردید',
      points: 250,
      icon: '🎯',
    ),
  };

  static const List<Badge> badges = [
    Badge(
      id: 'set_theory_expert',
      name: 'متخصص نظریه مجموعه‌ها',
      description: 'تسلط کامل بر مجموعه‌ها و عملیات آن‌ها',
      icon: '🎭',
      color: '#FFD700',
    ),
    Badge(
      id: 'function_guru',
      name: 'گورو توابع',
      description: 'درک عمیق انواع توابع و خصوصیات',
      icon: '📈',
      color: '#FF6B6B',
    ),
    Badge(
      id: 'grammar_wizard',
      name: 'جادوگر گرامر',
      description: 'تسلط بر گرامرها و زبان‌های رسمی',
      icon: '🧙‍♂️',
      color: '#4ECDC4',
    ),
  ];
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
  });
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class AdaptiveLearningSystem {
  static LessonPlan generatePersonalizedPlan(ProgressData progress) {
    final weakAreas = progress.weaknessAreas;
    final strengths = progress.strengthAreas;

    return LessonPlan(
      studentId: progress.lessonId,
      recommendedSections: _getRecommendedSections(weakAreas),
      additionalExercises: _getAdditionalExercises(weakAreas),
      reviewTopics: _getReviewTopics(strengths),
      estimatedTime: _calculateEstimatedTime(progress),
    );
  }

  static List<String> _getRecommendedSections(List<String> weakAreas) {
    Map<String, List<String>> recommendations = {
      'مجموعه': ['sets_intro', 'set_properties'],
      'تابع': ['functions', 'practical_problems'],
      'گرامر': ['language_grammar', 'practical_problems'],
    };

    List<String> result = [];
    for (String weakness in weakAreas) {
      result.addAll(recommendations[weakness] ?? []);
    }
    return result.toSet().toList();
  }

  static List<QuizQuestion> _getAdditionalExercises(List<String> weakAreas) {
    return MathContentData.quizQuestions
        .where((q) => q.topics.any((topic) => weakAreas.contains(topic)))
        .toList();
  }

  static List<String> _getReviewTopics(List<String> strengths) {
    return strengths.take(3).toList();
  }

  static int _calculateEstimatedTime(ProgressData progress) {
    double baseTime = 45;
    double efficiencyFactor = progress.averageQuizScore / 100;
    return (baseTime * (2 - efficiencyFactor)).round();
  }
}

class LessonPlan {
  final String studentId;
  final List<String> recommendedSections;
  final List<QuizQuestion> additionalExercises;
  final List<String> reviewTopics;
  final int estimatedTime;
  final DateTime createdAt;

  LessonPlan({
    required this.studentId,
    required this.recommendedSections,
    required this.additionalExercises,
    required this.reviewTopics,
    required this.estimatedTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class InteractiveSystem {
  static const List<ConversationTrigger> triggers = [
    ConversationTrigger(
      condition: TriggerCondition.lowScore,
      response:
          "نگران نباش نوید! بیا این قسمت رو دوباره مرور کنیم. کدوم بخش برات سخت بود؟",
      followUp: ["مثال بیشتر می‌خوای؟", "بیا قدم به قدم حلش کنیم"],
    ),
    ConversationTrigger(
      condition: TriggerCondition.perfectScore,
      response:
          "وای! عالی بود نوید! 🎉 انگار واقعاً متوجه شدی. حالا آماده‌ای برای چالش سخت‌تر؟",
      followUp: ["مسئله پیچیده‌تر می‌خوای؟", "بریم سراغ کاربردهای پیشرفته‌تر؟"],
    ),
    ConversationTrigger(
      condition: TriggerCondition.longTime,
      response: "به نظر داری فکر می‌کنی... اگه کمکی لازم داری بگو! 🤔",
      followUp: ["راهنمایی می‌خوای؟", "مثال ساده‌تر بیارم؟"],
    ),
    ConversationTrigger(
      condition: TriggerCondition.quickAnswer,
      response: "سریع جواب دادی! 🚀 مطمئنی درست فکر کردی؟",
      followUp: ["توضیحش رو می‌دی؟", "مطمئنی از جوابت؟"],
    ),
  ];

  static String generateContextualHint(String questionId, String difficulty) {
    Map<String, Map<String, String>> hints = {
      'q1': {
        'easy': 'یادت باشه مجموعه‌ها تکرار ندارن!',
        'medium': 'چک کن ببین کدوم گزینه خصوصیات مجموعه رو داره',
        'hard': 'دقت کن به تعریف دقیق مجموعه و شرایطش',
      },
      'q6': {
        'easy': 'از فرمول |A∪B| = |A| + |B| - |A∩B| استفاده کن',
        'medium': 'اول تعداد کل کسانی که حداقل یک زبان بلدن رو پیدا کن',
        'hard': 'مرحله به مرحله: کل - هیچ کدام = حداقل یکی',
      },
    };

    return hints[questionId]?[difficulty] ?? 'فکر کن و تلاش کن! 💪';
  }
}

class ConversationTrigger {
  final TriggerCondition condition;
  final String response;
  final List<String> followUp;

  const ConversationTrigger({
    required this.condition,
    required this.response,
    required this.followUp,
  });
}

enum TriggerCondition {
  lowScore,
  perfectScore,
  longTime,
  quickAnswer,
  repeatedMistake,
  newConcept,
}

class LearningAnalytics {
  static LearningReport generateReport(ProgressData progress) {
    return LearningReport(
      studentId: progress.lessonId,
      overallPerformance: _calculateOverallPerformance(progress),
      topicBreakdown: _analyzeTopicPerformance(progress),
      learningPattern: _identifyLearningPattern(progress),
      recommendations: _generateRecommendations(progress),
      strengths: progress.strengthAreas,
      improvements: progress.weaknessAreas,
      timeEfficiency: _calculateTimeEfficiency(progress),
      nextSteps: _suggestNextSteps(progress),
    );
  }

  static double _calculateOverallPerformance(ProgressData progress) {
    double completion = progress.completionPercentage;
    double quizAverage = progress.averageQuizScore;
    double timeBonus = progress.totalTimeSpent < 2700 ? 0.1 : 0;

    return (completion * 0.4 + quizAverage * 0.5 + timeBonus * 0.1).clamp(
      0.0,
      1.0,
    );
  }

  static Map<String, TopicAnalysis> _analyzeTopicPerformance(
    ProgressData progress,
  ) {
    return {
      'مجموعه‌ها': TopicAnalysis(
        masteryLevel: progress.topicMastery['مجموعه‌ها'] ?? 0,
        timeSpent: 15,
        difficultyConcepts: ['مجموعه توانی', 'عملیات مجموعه'],
        strengths: ['تعریف پایه', 'خصوصیات'],
      ),
      'توابع': TopicAnalysis(
        masteryLevel: progress.topicMastery['توابع'] ?? 0,
        timeSpent: 12,
        difficultyConcepts: ['تابع دوسویه', 'ترکیب توابع'],
        strengths: ['تعریف تابع', 'یک به یک'],
      ),
      'زبان و گرامر': TopicAnalysis(
        masteryLevel: progress.topicMastery['زبان و گرامر'] ?? 0,
        timeSpent: 18,
        difficultyConcepts: ['اشتقاق', 'طراحی گرامر'],
        strengths: ['مفاهیم پایه', 'تشخیص'],
      ),
    };
  }

  static LearningPattern _identifyLearningPattern(ProgressData progress) {
    if (progress.averageQuizScore > 85 && progress.totalTimeSpent < 2400) {
      return LearningPattern.quickLearner;
    } else if (progress.averageQuizScore > 75 &&
        progress.totalTimeSpent > 3000) {
      return LearningPattern.thoroughLearner;
    } else if (progress.completionPercentage > 0.9) {
      return LearningPattern.persistent;
    } else {
      return LearningPattern.needsSupport;
    }
  }

  static List<String> _generateRecommendations(ProgressData progress) {
    List<String> recommendations = [];

    if (progress.averageQuizScore < 60) {
      recommendations.add("مرور مفاهیم پایه‌ای پیشنهاد می‌شود");
    }

    if (progress.totalTimeSpent > 3600) {
      recommendations.add("تمرکز روی تکنیک‌های حل سریع‌تر");
    }

    if (progress.weaknessAreas.isNotEmpty) {
      recommendations.add(
        "تمرین بیشتر روی: ${progress.weaknessAreas.join(', ')}",
      );
    }

    return recommendations;
  }

  static double _calculateTimeEfficiency(ProgressData progress) {
    double idealTime = 2700;
    return (idealTime / progress.totalTimeSpent).clamp(0.0, 2.0);
  }

  static List<String> _suggestNextSteps(ProgressData progress) {
    if (progress.averageQuizScore >= 80) {
      return [
        "آماده برای درس بعدی: روابط و گراف‌ها",
        "حل مسائل پیشرفته‌تر مجموعه‌ها",
        "مطالعه کاربردهای عملی در برنامه‌نویسی",
      ];
    } else {
      return [
        "مرور دوباره مفاهیم این درس",
        "حل تمرین‌های اضافی",
        "مشورت با استاد برای موارد مبهم",
      ];
    }
  }
}

class LearningReport {
  final String studentId;
  final double overallPerformance;
  final Map<String, TopicAnalysis> topicBreakdown;
  final LearningPattern learningPattern;
  final List<String> recommendations;
  final List<String> strengths;
  final List<String> improvements;
  final double timeEfficiency;
  final List<String> nextSteps;
  final DateTime generatedAt;

  LearningReport({
    required this.studentId,
    required this.overallPerformance,
    required this.topicBreakdown,
    required this.learningPattern,
    required this.recommendations,
    required this.strengths,
    required this.improvements,
    required this.timeEfficiency,
    required this.nextSteps,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  String get performanceGrade {
    if (overallPerformance >= 0.9) return 'A';
    if (overallPerformance >= 0.8) return 'B';
    if (overallPerformance >= 0.7) return 'C';
    if (overallPerformance >= 0.6) return 'D';
    return 'F';
  }
}

class TopicAnalysis {
  final int masteryLevel;
  final int timeSpent;
  final List<String> difficultyConcepts;
  final List<String> strengths;

  TopicAnalysis({
    required this.masteryLevel,
    required this.timeSpent,
    required this.difficultyConcepts,
    required this.strengths,
  });
}

enum LearningPattern { quickLearner, thoroughLearner, persistent, needsSupport }

class SmartPracticeSystem {
  static List<QuizQuestion> generatePersonalizedQuiz(
    ProgressData progress,
    int questionCount,
  ) {
    List<QuizQuestion> allQuestions = MathContentData.quizQuestions;
    List<QuizQuestion> selectedQuestions = [];

    allQuestions.sort((a, b) {
      int scoreA = _calculateQuestionPriority(a, progress);
      int scoreB = _calculateQuestionPriority(b, progress);
      return scoreB.compareTo(scoreA);
    });

    return allQuestions.take(questionCount).toList();
  }

  static int _calculateQuestionPriority(
    QuizQuestion question,
    ProgressData progress,
  ) {
    int priority = 0;

    for (String topic in question.topics) {
      if (progress.weaknessAreas.contains(topic)) {
        priority += 10;
      }
    }

    if (progress.averageQuizScore < 60 && question.difficulty <= 2) {
      priority += 5;
    } else if (progress.averageQuizScore > 80 && question.difficulty >= 2) {
      priority += 5;
    }

    return priority;
  }

  static List<PracticeExercise> generateProgressiveExercises(String topic) {
    Map<String, List<PracticeExercise>> exerciseBank = {
      'مجموعه': [
        PracticeExercise(
          id: 'set_basic_1',
          topic: 'مجموعه',
          difficulty: 1,
          question: 'اگر A = {1, 2, 3} باشد، کدام از موارد زیر درست است؟',
          solution: 'بررسی هر گزینه بر اساس تعریف مجموعه',
          hints: ['مجموعه‌ها تکرار ندارند', 'ترتیب مهم نیست'],
        ),
        PracticeExercise(
          id: 'set_operations_1',
          topic: 'مجموعه',
          difficulty: 2,
          question: 'A = {1,2,3}, B = {2,3,4} باشد. A ∪ B و A ∩ B را بیابید.',
          solution: 'A ∪ B = {1,2,3,4}, A ∩ B = {2,3}',
          hints: ['اجتماع همه عناصر', 'اشتراک عناصر مشترک'],
        ),
      ],
      'تابع': [
        PracticeExercise(
          id: 'function_basic_1',
          topic: 'تابع',
          difficulty: 1,
          question: 'کدام رابطه یک تابع است؟',
          solution: 'بررسی شرط هر ورودی یک خروجی',
          hints: ['هر x فقط یک f(x) دارد'],
        ),
        PracticeExercise(
          id: 'function_type_1',
          topic: 'تابع',
          difficulty: 2,
          question: 'تابع f(x) = 2x یک به یک است؟',
          solution: 'بله، چون اگر f(x₁) = f(x₂) آنگاه x₁ = x₂',
          hints: ['اگر خروجی‌های مختلف، ورودی‌های مختلف'],
        ),
      ],
    };

    return exerciseBank[topic] ?? [];
  }

  static PracticeAssessment assessPracticePerformance(
    List<PracticeAttempt> attempts,
  ) {
    int totalAttempts = attempts.length;
    int correctAttempts = attempts.where((a) => a.isCorrect).length;
    double accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

    int totalTime = attempts.fold(0, (sum, attempt) => sum + attempt.timeSpent);
    double averageTime = totalAttempts > 0 ? totalTime / totalAttempts : 0.0;

    Map<String, int> errorPatterns = {};
    for (var attempt in attempts.where((a) => !a.isCorrect)) {
      errorPatterns[attempt.errorType] =
          (errorPatterns[attempt.errorType] ?? 0) + 1;
    }

    return PracticeAssessment(
      accuracy: accuracy,
      averageTime: averageTime,
      totalAttempts: totalAttempts,
      improvement: _calculateImprovement(attempts),
      errorPatterns: errorPatterns,
      recommendations: _generatePracticeRecommendations(
        accuracy,
        errorPatterns,
      ),
    );
  }

  static double _calculateImprovement(List<PracticeAttempt> attempts) {
    if (attempts.length < 2) return 0.0;

    int halfway = attempts.length ~/ 2;
    var firstHalf = attempts.take(halfway);
    var secondHalf = attempts.skip(halfway);

    double firstAccuracy =
        firstHalf.where((a) => a.isCorrect).length / firstHalf.length;
    double secondAccuracy =
        secondHalf.where((a) => a.isCorrect).length / secondHalf.length;

    return secondAccuracy - firstAccuracy;
  }

  static List<String> _generatePracticeRecommendations(
    double accuracy,
    Map<String, int> errorPatterns,
  ) {
    List<String> recommendations = [];

    if (accuracy < 0.6) {
      recommendations.add('مرور مفاهیم پایه پیشنهاد می‌شود');
      recommendations.add('تمرکز بر تمرین‌های ساده‌تر');
    } else if (accuracy > 0.85) {
      recommendations.add('آماده برای چالش‌های سخت‌تر');
      recommendations.add('تمرین سرعت حل مسائل');
    }

    String mostCommonError = errorPatterns.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    Map<String, String> errorAdvice = {
      'calculation': 'دقت بیشتر در محاسبات',
      'concept': 'مرور مفاهیم نظری',
      'method': 'تمرین روش‌های حل مختلف',
      'reading': 'دقت بیشتر در خواندن سؤال',
    };

    if (errorAdvice.containsKey(mostCommonError)) {
      recommendations.add(errorAdvice[mostCommonError]!);
    }

    return recommendations;
  }
}

class AdaptiveFeedbackSystem {
  static FeedbackResponse generateFeedback(
    QuizAttempt attempt,
    ProgressData progress,
  ) {
    FeedbackType feedbackType = _determineFeedbackType(attempt, progress);
    String message = _generateFeedbackMessage(attempt, feedbackType);
    List<String> suggestions = _generateSuggestions(attempt, progress);
    String encouragement = _generateEncouragement(attempt, progress);

    return FeedbackResponse(
      type: feedbackType,
      message: message,
      suggestions: suggestions,
      encouragement: encouragement,
      nextAction: _suggestNextAction(attempt, progress),
      relatedConcepts: _identifyRelatedConcepts(attempt.questionId),
    );
  }

  static FeedbackType _determineFeedbackType(
    QuizAttempt attempt,
    ProgressData progress,
  ) {
    if (attempt.isCorrect) {
      if (attempt.timeSpent < 30) return FeedbackType.excellentSpeed;
      if (progress.averageQuizScore > 85) return FeedbackType.consistent;
      return FeedbackType.correct;
    } else {
      if (attempt.attemptNumber > 2) return FeedbackType.needsHelp;
      if (progress.weaknessAreas.contains(attempt.topic))
        return FeedbackType.reviewNeeded;
      return FeedbackType.incorrect;
    }
  }

  static String _generateFeedbackMessage(
    QuizAttempt attempt,
    FeedbackType type,
  ) {
    Map<FeedbackType, List<String>> messages = {
      FeedbackType.correct: [
        'آفرین! جواب درست بود! �',
        'عالی! راه حل درستی انتخاب کردی!',
        'تبریک! مفهوم رو خوب متوجه شدی!',
      ],
      FeedbackType.excellentSpeed: [
        'فوق‌العاده! هم درست، هم سریع! 🚀',
        'واو! انگار واقعاً تسلط داری! ⚡',
        'سرعت و دقت عالی! 🏆',
      ],
      FeedbackType.incorrect: [
        'اشکال نداره! بیا دوباره فکر کنیم 🤔',
        'نزدیک بودی! یه بار دیگه امتحان کن',
        'هیچ مشکلی نیست، یادگیری فرآیندیه!',
      ],
      FeedbackType.needsHelp: [
        'بیا کمکت کنم! این قسمت رو با هم بررسی کنیم 🤝',
        'فکر کنم نیاز به توضیح بیشتر داری. مشکلی نیست!',
        'بیا قدم به قدم حلش کنیم 📚',
      ],
    };

    var messageList = messages[type] ?? ['ادامه بده! 💪'];
    return messageList[DateTime.now().millisecond % messageList.length];
  }

  static List<String> _generateSuggestions(
    QuizAttempt attempt,
    ProgressData progress,
  ) {
    List<String> suggestions = [];

    if (!attempt.isCorrect) {
      if (attempt.selectedAnswer != -1) {
        suggestions.add('دوباره گزینه‌ها رو بخون');
        suggestions.add('به کلمات کلیدی سؤال دقت کن');
      }

      Map<String, List<String>> topicSuggestions = {
        'مجموعه': [
          'یادت باشه مجموعه‌ها تکرار ندارن',
          'ترتیب عناصر مهم نیست',
          'مجموعه خالی زیرمجموعه همه مجموعه‌هاست',
        ],
        'تابع': [
          'هر ورودی فقط یک خروجی داره',
          'یک به یک یعنی ورودی‌های مختلف، خروجی‌های مختلف',
          'پوشا یعنی همه عناصر برد تصویر دارن',
        ],
        'گرامر': [
          'قوانین تولید رو دقیق اعمال کن',
          'از نماد شروع شروع کن',
          'مرحله به مرحله اشتقاق کن',
        ],
      };

      suggestions.addAll(topicSuggestions[attempt.topic] ?? []);
    } else {
      suggestions.add('حالا سراغ مسئله سخت‌تر برو!');
      if (attempt.timeSpent > 60) {
        suggestions.add('سعی کن سریع‌تر تشخیص بدی');
      }
    }

    return suggestions.take(2).toList();
  }

  static String _generateEncouragement(
    QuizAttempt attempt,
    ProgressData progress,
  ) {
    if (attempt.isCorrect) {
      if (progress.averageQuizScore > 90) {
        return 'داری عالی پیش میری! ادامه بده! 🌟';
      } else if (progress.averageQuizScore > 75) {
        return 'خیلی خوبه! داری بهتر میشی! 📈';
      } else {
        return 'آفرین! داری یاد می‌گیری! 💪';
      }
    } else {
      return 'نگران نباش! هر اشتباه یه درس جدیده! 🌱';
    }
  }

  static String _suggestNextAction(QuizAttempt attempt, ProgressData progress) {
    if (attempt.isCorrect) {
      if (attempt.timeSpent < 30 && progress.averageQuizScore > 80) {
        return 'برو سراغ سؤال چالشی بعدی';
      } else {
        return 'ادامه بده با سؤال بعدی';
      }
    } else {
      if (attempt.attemptNumber >= 2) {
        return 'بیا یه مثال ساده‌تر ببینیم';
      } else {
        return 'یه بار دیگه فکر کن و امتحان کن';
      }
    }
  }

  static List<String> _identifyRelatedConcepts(String questionId) {
    Map<String, List<String>> conceptMap = {
      'q1': ['خصوصیات مجموعه', 'تعریف مجموعه'],
      'q2': ['زیرمجموعه', 'عضویت'],
      'q3': ['مجموعه توانی', 'فرمول 2^n'],
      'q4': ['عملیات مجموعه', 'اجتماع'],
      'q5': ['انواع تابع', 'یک به یک و پوشا'],
      'q6': ['کاربرد عملی', 'فرمول شمول-استثنا'],
      'q7': ['گرامر', 'اشتقاق'],
    };

    return conceptMap[questionId] ?? [];
  }
}

class SmartSummarizationSystem {
  static LessonSummary generatePersonalizedSummary(
    ProgressData progress,
    List<String> completedSections,
  ) {
    Map<String, SectionSummary> sectionSummaries = {};
    List<String> keyTakeaways = [];
    List<String> areasForReview = [];
    List<String> masteredConcepts = [];

    for (String sectionId in completedSections) {
      SectionSummary summary = _summarizeSection(sectionId, progress);
      sectionSummaries[sectionId] = summary;

      if (summary.masteryLevel > 80) {
        masteredConcepts.addAll(summary.keyConcepts);
      } else if (summary.masteryLevel < 60) {
        areasForReview.addAll(summary.keyConcepts);
      }
    }

    keyTakeaways = _extractKeyTakeaways(progress, sectionSummaries);

    return LessonSummary(
      overallMastery: progress.averageQuizScore,
      sectionSummaries: sectionSummaries,
      keyTakeaways: keyTakeaways,
      masteredConcepts: masteredConcepts,
      areasForReview: areasForReview,
      studyTime: progress.totalTimeSpent,
      recommendations: _generateStudyRecommendations(progress),
      nextSteps: _planNextSteps(progress),
    );
  }

  static SectionSummary _summarizeSection(
    String sectionId,
    ProgressData progress,
  ) {
    Map<String, SectionData> sectionData = {
      'sets_intro': SectionData(
        title: 'مقدمات مجموعه‌ها',
        keyConcepts: ['تعریف مجموعه', 'عضویت', 'مجموعه خالی'],
        difficulty: 1,
        importanceLevel: 5,
      ),
      'set_properties': SectionData(
        title: 'خصوصیات مجموعه‌ها',
        keyConcepts: ['ترتیب', 'تکرار', 'برابری'],
        difficulty: 2,
        importanceLevel: 4,
      ),
      'set_operations': SectionData(
        title: 'عملیات روی مجموعه‌ها',
        keyConcepts: ['اجتماع', 'اشتراک', 'تفاضل', 'متمم'],
        difficulty: 3,
        importanceLevel: 5,
      ),
      'subsets_power': SectionData(
        title: 'زیرمجموعه و مجموعه توانی',
        keyConcepts: ['زیرمجموعه', 'مجموعه توانی', 'فرمول 2^n'],
        difficulty: 3,
        importanceLevel: 4,
      ),
      'functions': SectionData(
        title: 'مفهوم تابع',
        keyConcepts: ['تعریف تابع', 'یک به یک', 'پوشا', 'دوسویه'],
        difficulty: 4,
        importanceLevel: 5,
      ),
      'language_grammar': SectionData(
        title: 'زبان، گرامر و ماشین',
        keyConcepts: ['زبان رسمی', 'گرامر', 'اشتقاق'],
        difficulty: 4,
        importanceLevel: 3,
      ),
    };

    SectionData section =
        sectionData[sectionId] ??
        SectionData(
          title: 'نامشخص',
          keyConcepts: [],
          difficulty: 1,
          importanceLevel: 1,
        );

    double masteryLevel = _calculateSectionMastery(sectionId, progress);

    return SectionSummary(
      sectionId: sectionId,
      title: section.title,
      keyConcepts: section.keyConcepts,
      masteryLevel: masteryLevel,
      timeSpent: 15,
      difficulty: section.difficulty,
      importanceLevel: section.importanceLevel,
      summary: _generateSectionSummaryText(section, masteryLevel),
    );
  }

  static double _calculateSectionMastery(
    String sectionId,
    ProgressData progress,
  ) {
    bool completed = progress.sectionsCompleted[sectionId] ?? false;
    if (!completed) return 0.0;

    return progress.averageQuizScore;
  }

  static String _generateSectionSummaryText(
    SectionData section,
    double masteryLevel,
  ) {
    if (masteryLevel > 85) {
      return 'عالی! این بخش رو کامل تسلط داری. 🌟';
    } else if (masteryLevel > 70) {
      return 'خوبه! فقط یه کم تمرین بیشتر نیاز داری. 👍';
    } else if (masteryLevel > 50) {
      return 'متوسطه. بهتره دوباره مرور کنی. 📚';
    } else {
      return 'نیاز به مطالعه بیشتر داری. نگران نباش! 💪';
    }
  }

  static List<String> _extractKeyTakeaways(
    ProgressData progress,
    Map<String, SectionSummary> sections,
  ) {
    List<String> takeaways = [];

    sections.values.where((s) => s.masteryLevel > 80).forEach((section) {
      takeaways.add('✅ ${section.title}: مسلط شدی!');
    });

    if (progress.averageQuizScore > 75) {
      takeaways.add('🎯 پایه محکمی از مفاهیم ریاضی گسسته کسب کردی');
    }

    if (progress.completionPercentage > 0.9) {
      takeaways.add('📈 پشتکار عالی در تکمیل همه بخش‌ها');
    }

    return takeaways;
  }

  static List<String> _generateStudyRecommendations(ProgressData progress) {
    List<String> recommendations = [];

    if (progress.averageQuizScore < 60) {
      recommendations.add('🔄 مرور کامل مطالب ضروری است');
      recommendations.add('📖 مطالعه بیشتر منابع کمکی پیشنهاد می‌شود');
    } else if (progress.averageQuizScore < 75) {
      recommendations.add('📝 تمرین بیشتر روی مسائل');
      recommendations.add('🤝 گروه مطالعه با همکلاسی‌ها');
    } else {
      recommendations.add('🚀 آماده برای مباحث پیشرفته‌تر');
      recommendations.add('💡 تمرکز روی کاربردهای عملی');
    }

    return recommendations;
  }

  static List<String> _planNextSteps(ProgressData progress) {
    List<String> nextSteps = [];

    if (progress.completionPercentage >= 0.8 &&
        progress.averageQuizScore >= 70) {
      nextSteps.addAll([
        'آماده شدن برای درس بعدی: روابط و گراف‌ها',
        'حل تمرین‌های ترکیبی و کاربردی',
        'مطالعه کاربردهای عملی در برنامه‌نویسی',
      ]);
    } else {
      nextSteps.addAll([
        'تکمیل مرور بخش‌های ناقص',
        'تمرین بیشتر روی نقاط ضعف',
        'مشورت با استاد در جلسه بعد',
      ]);
    }

    return nextSteps;
  }
}

class VisualizationSystem {
  static ProgressVisualization generateProgressVisuals(ProgressData progress) {
    return ProgressVisualization(
      completionChart: _generateCompletionChart(progress),
      masteryRadar: _generateMasteryRadar(progress),
      timelineData: _generateTimeline(progress),
      performanceMetrics: _generatePerformanceMetrics(progress),
    );
  }

  static ChartData _generateCompletionChart(ProgressData progress) {
    List<DataPoint> points = [];

    progress.sectionsCompleted.forEach((section, completed) {
      points.add(
        DataPoint(
          label: _getSectionDisplayName(section),
          value: completed ? 100.0 : 0.0,
          color: completed ? '#4CAF50' : '#E0E0E0',
        ),
      );
    });

    return ChartData(
      title: 'پیشرفت بخش‌ها',
      type: ChartType.bar,
      dataPoints: points,
    );
  }

  static RadarChartData _generateMasteryRadar(ProgressData progress) {
    Map<String, double> topicScores = {
      'مجموعه‌ها': progress.topicMastery['مجموعه‌ها']?.toDouble() ?? 0.0,
      'توابع': progress.topicMastery['توابع']?.toDouble() ?? 0.0,
      'زبان و گرامر': progress.topicMastery['زبان و گرامر']?.toDouble() ?? 0.0,
      'حل مسئله': progress.averageQuizScore,
      'سرعت': _calculateSpeedScore(progress),
    };

    return RadarChartData(
      title: 'نقشه تسلط',
      categories: topicScores.keys.toList(),
      values: topicScores.values.toList(),
      maxValue: 100.0,
    );
  }

  static double _calculateSpeedScore(ProgressData progress) {
    double idealTime = 2700;
    double efficiency = idealTime / progress.totalTimeSpent;
    return (efficiency * 100).clamp(0.0, 100.0);
  }

  static List<TimelineEvent> _generateTimeline(ProgressData progress) {
    List<TimelineEvent> events = [];

    events.add(
      TimelineEvent(
        time: progress.startTime,
        title: 'شروع درس',
        description: 'آغاز یادگیری مفاهیم جدید',
        type: TimelineEventType.start,
      ),
    );

    int sectionIndex = 0;
    progress.sectionsCompleted.forEach((section, completed) {
      if (completed) {
        events.add(
          TimelineEvent(
            time: progress.startTime.add(Duration(minutes: sectionIndex * 15)),
            title: 'تکمیل ${_getSectionDisplayName(section)}',
            description: 'موفقیت در فراگیری این بخش',
            type: TimelineEventType.achievement,
          ),
        );
      }
      sectionIndex++;
    });

    if (progress.endTime != null) {
      events.add(
        TimelineEvent(
          time: progress.endTime!,
          title: 'اتمام درس',
          description: 'تکمیل موفقیت‌آمیز درس',
          type: TimelineEventType.completion,
        ),
      );
    }

    return events;
  }

  static List<MetricCard> _generatePerformanceMetrics(ProgressData progress) {
    return [
      MetricCard(
        title: 'درصد تکمیل',
        value: '${(progress.completionPercentage * 100).toInt()}%',
        icon: '📊',
        color: progress.completionPercentage > 0.8 ? '#4CAF50' : '#FFC107',
      ),
      MetricCard(
        title: 'میانگین نمرات',
        value: '${progress.averageQuizScore.toInt()}',
        icon: '🎯',
        color: progress.averageQuizScore > 75 ? '#4CAF50' : '#FF9800',
      ),
      MetricCard(
        title: 'زمان مطالعه',
        value: '${(progress.totalTimeSpent / 60).toInt()} دقیقه',
        icon: '⏱️',
        color: '#2196F3',
      ),
      MetricCard(
        title: 'سطح عملکرد',
        value: progress.performanceLevel,
        icon: '🏆',
        color: _getPerformanceColor(progress.performanceLevel),
      ),
    ];
  }

  static String _getSectionDisplayName(String sectionId) {
    Map<String, String> displayNames = {
      'sets_intro': 'مقدمات مجموعه‌ها',
      'set_properties': 'خصوصیات مجموعه‌ها',
      'set_operations': 'عملیات مجموعه‌ها',
      'subsets_power': 'زیرمجموعه و مجموعه توانی',
      'functions': 'توابع',
      'language_grammar': 'زبان و گرامر',
    };
    return displayNames[sectionId] ?? sectionId;
  }

  static String _getPerformanceColor(String level) {
    switch (level) {
      case 'عالی':
        return MathContentData.theme['successColor'] ?? '#4CAF50';
      case 'خوب':
        return MathContentData.theme['primaryColor'] ?? '#2196F3';
      case 'متوسط':
        return MathContentData.theme['warningColor'] ?? '#FF9800';
      case 'نیاز به بهبود':
        return MathContentData.theme['errorColor'] ?? '#F44336';
      default:
        return MathContentData.theme['textColor'] ?? '#333333';
    }
  }
}

class ProgressVisualization {
  final ChartData completionChart;
  final RadarChartData masteryRadar;
  final List<TimelineEvent> timelineData;
  final List<MetricCard> performanceMetrics;

  ProgressVisualization({
    required this.completionChart,
    required this.masteryRadar,
    required this.timelineData,
    required this.performanceMetrics,
  });
}

class ChartData {
  final String title;
  final ChartType type;
  final List<DataPoint> dataPoints;

  ChartData({
    required this.title,
    required this.type,
    required this.dataPoints,
  });
}

enum ChartType { bar, pie, line, radar }

class DataPoint {
  final String label;
  final double value;
  final String? color;

  DataPoint({required this.label, required this.value, this.color});
}

class RadarChartData {
  final String title;
  final List<String> categories;
  final List<double> values;
  final double maxValue;

  RadarChartData({
    required this.title,
    required this.categories,
    required this.values,
    this.maxValue = 100.0,
  });
}

class TimelineEvent {
  final DateTime time;
  final String title;
  final String description;
  final TimelineEventType type;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.type,
  });
}

enum TimelineEventType { start, completion, achievement, milestone, warning }

class MetricCard {
  final String title;
  final String value;
  final String icon;
  final String color;

  MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class PracticeExercise {
  final String id;
  final String topic;
  final int difficulty;
  final String question;
  final String solution;
  final List<String> hints;

  PracticeExercise({
    required this.id,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.solution,
    required this.hints,
  });
}

class PracticeAttempt {
  final String exerciseId;
  final bool isCorrect;
  final int timeSpent;
  final String errorType;

  PracticeAttempt({
    required this.exerciseId,
    required this.isCorrect,
    required this.timeSpent,
    required this.errorType,
  });
}

class PracticeAssessment {
  final double accuracy;
  final double averageTime;
  final int totalAttempts;
  final double improvement;
  final Map<String, int> errorPatterns;
  final List<String> recommendations;

  PracticeAssessment({
    required this.accuracy,
    required this.averageTime,
    required this.totalAttempts,
    required this.improvement,
    required this.errorPatterns,
    required this.recommendations,
  });
}

class QuizAttempt {
  final String questionId;
  final String topic;
  final bool isCorrect;
  final int selectedAnswer;
  final int timeSpent;
  final int attemptNumber;

  QuizAttempt({
    required this.questionId,
    required this.topic,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.timeSpent,
    required this.attemptNumber,
  });
}

class FeedbackResponse {
  final FeedbackType type;
  final String message;
  final List<String> suggestions;
  final String encouragement;
  final String nextAction;
  final List<String> relatedConcepts;

  FeedbackResponse({
    required this.type,
    required this.message,
    required this.suggestions,
    required this.encouragement,
    required this.nextAction,
    required this.relatedConcepts,
  });
}

enum FeedbackType {
  correct,
  incorrect,
  excellentSpeed,
  consistent,
  reviewNeeded,
  needsHelp,
}

class LessonSummary {
  final double overallMastery;
  final Map<String, SectionSummary> sectionSummaries;
  final List<String> keyTakeaways;
  final List<String> masteredConcepts;
  final List<String> areasForReview;
  final int studyTime;
  final List<String> recommendations;
  final List<String> nextSteps;

  LessonSummary({
    required this.overallMastery,
    required this.sectionSummaries,
    required this.keyTakeaways,
    required this.masteredConcepts,
    required this.areasForReview,
    required this.studyTime,
    required this.recommendations,
    required this.nextSteps,
  });
}

class SectionSummary {
  final String sectionId;
  final String title;
  final List<String> keyConcepts;
  final double masteryLevel;
  final int timeSpent;
  final int difficulty;
  final int importanceLevel;
  final String summary;

  SectionSummary({
    required this.sectionId,
    required this.title,
    required this.keyConcepts,
    required this.masteryLevel,
    required this.timeSpent,
    required this.difficulty,
    required this.importanceLevel,
    required this.summary,
  });
}

class SectionData {
  final String title;
  final List<String> keyConcepts;
  final int difficulty;
  final int importanceLevel;

  SectionData({
    required this.title,
    required this.keyConcepts,
    required this.difficulty,
    required this.importanceLevel,
  });
}
