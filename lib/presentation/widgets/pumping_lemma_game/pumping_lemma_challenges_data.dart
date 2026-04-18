import 'challenge_difficulty.dart';
import 'pumping_lemma_challenge_model.dart';

final List<PumpingLemmaChallenge> pumpingLemmaChallenges = List.unmodifiable([
  // Level 1: Basic regular languages - Easy concepts
  PumpingLemmaChallenge(
    id: 1,
    level: 1,
    difficulty: ChallengeDifficulty.easy,
    language: 'L = {a^n | n ≥ 0}',
    description: 'Strings of only a\'s',
    isRegular: true,
    explanation:
        'This language is regular. It can be recognized by a simple automaton that accepts any number of a\'s.',
    detailedExplanation: [
      'This is a regular language because it follows a simple pattern.',
      'A finite automaton can accept this by having a single state that loops on "a".',
      'The pumping lemma condition is satisfied since we can always find strings that can be pumped.',
      'For any pumping length p, we can choose x = ε, y = a^k (1 ≤ k ≤ p), z = a^{n-k} for n ≥ k.',
      'Then xy^iz ∈ L for all i ≥ 0 because it\'s still just a\'s.',
    ],
    examples: ['ε', 'a', 'aa', 'aaa'],
    hints: [
      'Think about whether a finite state machine can recognize this pattern.',
    ],
  ),
  PumpingLemmaChallenge(
    id: 2,
    level: 1,
    difficulty: ChallengeDifficulty.easy,
    language: 'L = {a^n b^m | n, m ≥ 0}',
    description: 'Strings with a\'s followed by b\'s',
    isRegular: true,
    explanation:
        'This language is regular. It can be recognized by an automaton that accepts any number of a\'s followed by any number of b\'s.',
    detailedExplanation: [
      'This language is regular because the two parts (a\'s and b\'s) are independent.',
      'A finite automaton can track whether we\'ve seen any b\'s yet.',
      'Once a b is seen, only b\'s are accepted.',
      'The pumping lemma is satisfied because we can pump either the a\'s or b\'s independently.',
    ],
    examples: ['ε', 'a', 'b', 'ab', 'aab', 'abb'],
    hints: [
      'Consider if this can be recognized by counting states or a simple state machine.',
    ],
  ),

  // Level 2: Simple non-regular languages - Classic counterexamples
  PumpingLemmaChallenge(
    id: 3,
    level: 2,
    difficulty: ChallengeDifficulty.medium,
    language: 'L = {a^n b^n | n ≥ 0}',
    description: 'Strings with equal number of a\'s and b\'s',
    isRegular: false,
    explanation:
        'This language is not regular. For any pumping length p, the string a^p b^p can be pumped, but pumping the a\'s will break the balance.',
    detailedExplanation: [
      'This is a classic non-regular language.',
      'The pumping lemma says: for any p ≥ 1, there exists a string s = xyz where |xy| ≤ p, |y| ≥ 1, and xy^iz ∈ L for all i ≥ 0.',
      'For s = a^p b^p, we can choose x = a^{p-1}, y = a, z = b^p.',
      'Then xy^2z = a^{p+1} b^p, which has more a\'s than b\'s, so it\'s not in L.',
      'This shows that no finite automaton can recognize this language.',
    ],
    examples: ['ε', 'ab', 'aabb', 'aaabbb'],
    hints: [
      'Try applying the pumping lemma with p = 2. What happens when you pump?',
    ],
  ),
  PumpingLemmaChallenge(
    id: 4,
    level: 2,
    difficulty: ChallengeDifficulty.medium,
    language: 'L = {a^n b^n c^n | n ≥ 0}',
    description: 'Strings with equal number of a\'s, b\'s, and c\'s',
    isRegular: false,
    explanation:
        'This language is not regular. It requires counting three different symbols, which cannot be done with finite memory.',
    detailedExplanation: [
      'This language requires tracking three independent counters.',
      'No finite state machine can keep track of three separate counts simultaneously.',
      'Using the pumping lemma: choose a string with p a\'s, p b\'s, and p c\'s.',
      'Pumping the a\'s will break the balance between a\'s, b\'s, and c\'s.',
      'For s = a^p b^p c^p, choose x = a^{p-1}, y = a, z = b^p c^p.',
      'Then xy^2z = a^{p+1} b^p c^p ∉ L because  p+1 ≠ p ≠ p.',
    ],
    examples: ['ε', 'abc', 'aabbcc', 'aaabbbccc'],
    hints: ['Think about how many independent counters this would require.'],
  ),

  // Level 3: Advanced non-regular languages - Complex patterns
  PumpingLemmaChallenge(
    id: 5,
    level: 3,
    difficulty: ChallengeDifficulty.hard,
    language: 'L = {ww | w ∈ {a,b}*}',
    description: 'Strings that are concatenations of a word with itself',
    isRegular: false,
    explanation:
        'This language is not regular. It requires remembering the first half of the string to match the second half, which requires unbounded memory.',
    detailedExplanation: [
      'This language requires remembering the entire first half of the string.',
      'No matter how large the pumping length p is, we can choose w with length > p.',
      'For s = ww where |w| > p, the first half has length > p.',
      'The pumping lemma cannot find a suitable decomposition that preserves the property.',
      'This is the language of duplicated strings, not the language of palindromes; palindromes are strings equal to their reverse.',
    ],
    examples: ['aa', 'bb', 'abab', 'aabbaabb'],
    hints: [
      'What happens if you choose a very long string and try to apply the pumping lemma?',
    ],
  ),
  PumpingLemmaChallenge(
    id: 6,
    level: 3,
    difficulty: ChallengeDifficulty.hard,
    language: 'L = {a^{2n} | n ≥ 0}',
    description: 'Strings with even number of a\'s',
    isRegular: true,
    explanation:
        'This language is regular. It can be recognized by a finite automaton that tracks parity (even/odd number of a\'s).',
    detailedExplanation: [
      'This is actually a regular language!',
      'A 2-state automaton can track whether we\'ve seen an even or odd number of a\'s.',
      'Start in an "even" state, go to "odd" state on each "a", and back to "even" on the next "a".',
      'Accept only in the "even" state.',
      'The key insight is that we only need to track parity, not the exact count.',
    ],
    examples: ['ε', 'aa', 'aaaa', 'aaaaaa'],
    hints: ['Think about modulo 2 instead of exact counting.'],
  ),

  // Level 4: Context-free vs Regular - Advanced concepts
  PumpingLemmaChallenge(
    id: 7,
    level: 4,
    difficulty: ChallengeDifficulty.hard,
    language: 'L = {a^n b^n | n ≥ 0} ∪ {a^m | m ≥ 0}',
    description: 'Union of equal a\'s and b\'s with strings of only a\'s',
    isRegular: false,
    explanation:
        'This language is not regular, but that cannot be proved merely by pointing to a subset. A pumping-lemma or closure-property argument is required.',
    detailedExplanation: [
      'This language contains both a non-regular part (a^n b^n) and a regular part (a^m).',
      'The union of a non-regular language with a regular language may or may not be regular.',
      'Finding a non-regular subset is not enough to prove the whole language is non-regular.',
      'A valid proof can use the pumping lemma directly on strings a^p b^p from the mixed language.',
      'For s = a^p b^p, the same counterexample as before applies.',
    ],
    examples: ['ε', 'a', 'aa', 'ab', 'aabb', 'aaa'],
    hints: [
      'Consider what happens when you try to apply the pumping lemma to strings from the a^n b^n part.',
    ],
  ),
  PumpingLemmaChallenge(
    id: 8,
    level: 4,
    difficulty: ChallengeDifficulty.hard,
    language: 'L = {w | w = w^R} ∩ {a,b}^*',
    description: 'Palindromes over {a,b}',
    isRegular: false,
    explanation:
        'Palindromes are not regular because they require unbounded memory to verify symmetry.',
    detailedExplanation: [
      'Palindromes require checking that the string reads the same forwards and backwards.',
      'For long palindromes, you need to remember the first half to compare with the second half.',
      'Using the pumping lemma: for s = a^p b a^p, choose x = a^{p-1}, y = a, z = b a^p.',
      'Then xy^2z = a^{p+1} b a^p, which is not a palindrome.',
      'The middle b is no longer centered properly.',
    ],
    examples: ['ε', 'a', 'b', 'aa', 'aba', 'abba'],
    hints: [
      'Think about what happens to the center when you pump a long palindrome.',
    ],
  ),
]);
