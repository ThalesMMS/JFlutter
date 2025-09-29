import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nfa.dart';
import '../providers/nfa_provider.dart';
import '../utils/constants.dart';

class ExamplesScreen extends StatefulWidget {
  const ExamplesScreen({super.key});

  @override
  State<ExamplesScreen> createState() => _ExamplesScreenState();
}

class _ExamplesScreenState extends State<ExamplesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'همه';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // دسته‌بندی مثال‌ها
  static const List<String> _categories = [
    'همه',
    'مبتدی',
    'متوسط',
    'پیشرفته',
    'کلاسیک'
  ];

  static final List<Map<String, dynamic>> _examples = [
    // مثال‌های مبتدی
    {
      'title': 'شروع با حرف a',
      'description': 'اتوماتایی که رشته‌های شروع‌شده با حرف a را قبول می‌کند',
      'category': 'مبتدی',
      'difficulty': 1,
      'complexity': 'ساده',
      'stateCount': 3,
      'icon': Icons.play_arrow,
      'color': Colors.green,
      'nfaJson': {
        'name': 'شروع با a',
        'states': ['q0', 'q1', 'q2'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q1'],
        'transitions': {
          'q0': {
            'a': ['q1'],
            'b': ['q2']
          },
          'q1': {
            'a': ['q1'],
            'b': ['q1']
          },
          'q2': {},
        }
      }
    },
    {
      'title': 'پایان با حرف b',
      'description': 'اتوماتایی که رشته‌های پایان‌یافته با حرف b را می‌پذیرد',
      'category': 'مبتدی',
      'difficulty': 1,
      'complexity': 'ساده',
      'stateCount': 2,
      'icon': Icons.stop,
      'color': Colors.blue,
      'nfaJson': {
        'name': 'پایان با b',
        'states': ['q0', 'q1'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q1'],
        'transitions': {
          'q0': {
            'a': ['q0'],
            'b': ['q0', 'q1']
          },
          'q1': {
            'a': ['q0']
          },
        }
      }
    },

    // مثال‌های متوسط
    {
      'title': 'شامل زیررشته "ab"',
      'description': 'اتوماتایی غیرقطعی برای تشخیص رشته‌های حاوی "ab"',
      'category': 'متوسط',
      'difficulty': 2,
      'complexity': 'متوسط',
      'stateCount': 3,
      'icon': Icons.search,
      'color': Colors.orange,
      'nfaJson': {
        'name': 'شامل "ab"',
        'states': ['q0', 'q1', 'q2'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q2'],
        'transitions': {
          'q0': {
            'a': ['q0', 'q1'],
            'b': ['q0']
          },
          'q1': {
            'b': ['q2']
          },
          'q2': {
            'a': ['q2'],
            'b': ['q2']
          },
        }
      }
    },
    {
      'title': 'تعداد زوج صفر',
      'description':
          'اتوماتا برای شمارش زوج/فرد تعداد ارقام صفر در رشته باینری',
      'category': 'متوسط',
      'difficulty': 2,
      'complexity': 'متوسط',
      'stateCount': 2,
      'icon': Icons.calculate,
      'color': Colors.purple,
      'nfaJson': {
        'name': 'تعداد زوج 0ها',
        'states': ['q0', 'q1'],
        'alphabet': ['0', '1'],
        'startState': 'q0',
        'finalStates': ['q0'],
        'transitions': {
          'q0': {
            '0': ['q1'],
            '1': ['q0']
          },
          'q1': {
            '0': ['q0'],
            '1': ['q1']
          },
        }
      }
    },

    // مثال‌های پیشرفته
    {
      'title': 'عبارت منظم (a|b)*abb',
      'description': 'اتوماتای پیچیده برای الگوی پایان با "abb" در حروف a و b',
      'category': 'پیشرفته',
      'difficulty': 3,
      'complexity': 'پیچیده',
      'stateCount': 4,
      'icon': Icons.pattern,
      'color': Colors.red,
      'nfaJson': {
        'name': 'الگوی (a|b)*abb',
        'states': ['q0', 'q1', 'q2', 'q3'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q3'],
        'transitions': {
          'q0': {
            'a': ['q0', 'q1'],
            'b': ['q0']
          },
          'q1': {
            'b': ['q2']
          },
          'q2': {
            'b': ['q3']
          },
          'q3': {},
        }
      }
    },
    {
      'title': 'تشخیص پالیندروم',
      'description':
          'اتوماتای غیرقطعی برای تشخیص پالیندروم‌های فرد در حروف {a,b}',
      'category': 'پیشرفته',
      'difficulty': 4,
      'complexity': 'بسیار پیچیده',
      'stateCount': 5,
      'icon': Icons.sync,
      'color': Colors.deepPurple,
      'nfaJson': {
        'name': 'پالیندروم فرد',
        'states': ['q0', 'q1', 'q2', 'q3', 'q4'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q0', 'q2', 'q4'],
        'transitions': {
          'q0': {
            'a': ['q1', 'q0'],
            'b': ['q3', 'q0'],
            'ε': ['q2']
          },
          'q1': {
            'a': ['q0'],
            'ε': ['q2']
          },
          'q2': {},
          'q3': {
            'b': ['q0'],
            'ε': ['q4']
          },
          'q4': {},
        }
      }
    },

    // مثال‌های کلاسیک
    {
      'title': 'ماشین وندینگ',
      'description':
          'شبیه‌سازی ماشین فروش با سکه‌های 5 و 10 تومانی (محصول 15 تومان)',
      'category': 'کلاسیک',
      'difficulty': 3,
      'complexity': 'کاربردی',
      'stateCount': 4,
      'icon': Icons.local_drink,
      'color': Colors.teal,
      'nfaJson': {
        'name': 'ماشین وندینگ',
        'states': ['q0', 'q5', 'q10', 'q15'],
        'alphabet': ['5T', '10T'],
        'startState': 'q0',
        'finalStates': ['q15'],
        'transitions': {
          'q0': {
            '5T': ['q5'],
            '10T': ['q10']
          },
          'q5': {
            '5T': ['q10'],
            '10T': ['q15']
          },
          'q10': {
            '5T': ['q15'],
            '10T': ['q15']
          },
          'q15': {},
        }
      }
    },
    {
      'title': 'کلمات با طول مضرب 3',
      'description': 'اتوماتای چرخشی برای پذیرش کلمات با طول مضرب بر 3',
      'category': 'کلاسیک',
      'difficulty': 2,
      'complexity': 'آموزشی',
      'stateCount': 3,
      'icon': Icons.rotate_right,
      'color': Colors.brown,
      'nfaJson': {
        'name': 'طول مضرب 3',
        'states': ['q0', 'q1', 'q2'],
        'alphabet': ['a', 'b'],
        'startState': 'q0',
        'finalStates': ['q0'],
        'transitions': {
          'q0': {
            'a': ['q1'],
            'b': ['q1']
          },
          'q1': {
            'a': ['q2'],
            'b': ['q2']
          },
          'q2': {
            'a': ['q0'],
            'b': ['q0']
          },
        }
      }
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredExamples {
    return _examples.where((example) {
      final matchesCategory = _selectedCategory == 'همه' ||
          example['category'] == _selectedCategory;
      final matchesSearch =
          example['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              example['description']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDifficultyStars(int difficulty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Icon(
          index < difficulty ? Icons.star : Icons.star_border,
          size: 16,
          color: _getDifficultyColor(difficulty),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          hintText: 'جستجو در مثال‌ها...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildExampleCard(Map<String, dynamic> example, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3 + (index * 0.1)),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0),
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 8,
            shadowColor: (example['color'] as Color).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _loadExample(example),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (example['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            example['icon'] as IconData,
                            color: example['color'] as Color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                example['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildDifficultyStars(example['difficulty']),
                                  const SizedBox(width: 8),
                                  Text(
                                    example['complexity'],
                                    style: TextStyle(
                                      color: _getDifficultyColor(
                                          example['difficulty']),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      example['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_tree,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${example['stateCount']} حالت',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (example['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            example['category'],
                            style: TextStyle(
                              color: example['color'] as Color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadExample(Map<String, dynamic> example) {
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                example['icon'] as IconData,
                color: example['color'] as Color,
              ),
              const SizedBox(width: 8),
              Text(
                'بارگذاری مثال',
                style: TextStyle(
                  color: example['color'] as Color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                example['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                example['description'],
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('سطح سختی: '),
                  _buildDifficultyStars(example['difficulty']),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                final nfa = NFA.fromJson(example['nfaJson']);
                nfaProvider.loadNfa(nfa);
                Navigator.of(context).pop();
                Navigator.pushNamed(context, AppRoutes.input);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: example['color'] as Color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('بارگذاری'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExamples = _filteredExamples;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مجموعه مثال‌های اتوماتا'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          const SizedBox(height: 8),
          Expanded(
            child: filteredExamples.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'هیچ مثالی یافت نشد',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لطفاً جستجو یا دسته‌بندی را تغییر دهید',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredExamples.length,
                    itemBuilder: (context, index) {
                      return _buildExampleCard(filteredExamples[index], index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // نمایش راهنمای استفاده
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('راهنمای استفاده'),
                ],
              ),
              content: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔍 جستجو: برای یافتن مثال مورد نظر از نوار جستجو استفاده کنید',
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🏷️ دسته‌بندی: مثال‌ها را بر اساس سطح سختی فیلتر کنید',
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '⭐ ستاره‌ها: نشان‌دهنده سطح پیچیدگی مثال هستند',
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '📱 انتخاب: روی هر مثال کلیک کنید تا بارگذاری شود',
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('متوجه شدم'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.help_outline),
        label: const Text('راهنما'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
