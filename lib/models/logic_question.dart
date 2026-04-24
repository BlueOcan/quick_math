import 'dart:math';

// ── Enums ─────────────────────────────────────────────────────────────────────
enum LogicCategory { numberSequence, missingNumber, oddOneOut }

extension LogicCategoryExt on LogicCategory {
  String get label {
    switch (this) {
      case LogicCategory.numberSequence:
        return 'Number Sequence';
      case LogicCategory.missingNumber:
        return 'Missing Number';
      case LogicCategory.oddOneOut:
        return 'Odd One Out';
    }
  }

  String get description {
    switch (this) {
      case LogicCategory.numberSequence:
        return 'Find the next number in the pattern';
      case LogicCategory.missingNumber:
        return 'Find the missing number in the box';
      case LogicCategory.oddOneOut:
        return 'Find which one does not belong';
    }
  }

  String get emoji {
    switch (this) {
      case LogicCategory.numberSequence:
        return '🔢';
      case LogicCategory.missingNumber:
        return '❓';
      case LogicCategory.oddOneOut:
        return '🔍';
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class LogicQuestion {
  final String questionText;
  final String correct;
  final List<String> options;
  final String hintText;
  final LogicCategory category;
  final String difficulty;

  const LogicQuestion({
    required this.questionText,
    required this.correct,
    required this.options,
    required this.hintText,
    required this.category,
    required this.difficulty,
  });
}

// ── Generator ─────────────────────────────────────────────────────────────────
class LogicQuestionGenerator {
  static final Random _rng = Random();
  static int _rand(int min, int max) => min + _rng.nextInt(max - min + 1);

  static final Set<String> _seen = {};
  static void resetSession() => _seen.clear();

  static LogicQuestion _unique(LogicQuestion Function() builder) {
    for (int i = 0; i < 30; i++) {
      final q = builder();
      if (_seen.add(q.questionText)) return q;
    }
    return builder();
  }

  static LogicQuestion generate({
    required LogicCategory category,
    required int difficulty,
  }) {
    switch (category) {
      case LogicCategory.numberSequence:
        return _unique(() => _sequence(difficulty));
      case LogicCategory.missingNumber:
        return _unique(() => _missing(difficulty));
      case LogicCategory.oddOneOut:
        return _unique(() => _oddOne(difficulty));
    }
  }

  // ── NUMBER SEQUENCE ───────────────────────────────────────────
  static LogicQuestion _sequence(int diff) {
    if (diff == 0) return _sequenceEasy();
    if (diff == 1) return _sequenceMedium();
    return _sequenceHard();
  }

  static LogicQuestion _sequenceEasy() {
    final type = _rng.nextInt(10);
    List<int> seq;
    String hint;

    switch (type) {
      case 0:
        final step = _rand(2, 5);
        final start = _rand(1, 10);
        seq = List.generate(5, (i) => start + i * step);
        hint = 'Add $step each time';
        break;
      case 1:
        final step = _rand(2, 4);
        final start = _rand(20, 40);
        seq = List.generate(5, (i) => start - i * step);
        hint = 'Subtract $step each time';
        break;
      case 2:
        final start = _rand(1, 4);
        seq = List.generate(5, (i) => start * pow(2, i).toInt());
        hint = 'Multiply by 2 each time';
        break;
      case 3:
        final start = _rand(1, 3);
        seq = List.generate(5, (i) => start * pow(3, i).toInt());
        hint = 'Multiply by 3 each time';
        break;
      case 4:
        final start = _rand(1, 4) * 32;
        seq = List.generate(5, (i) => start ~/ pow(2, i).toInt());
        hint = 'Divide by 2 each time';
        break;
      case 5:
        final offset = _rand(1, 5);
        seq = List.generate(5, (i) => pow(i + offset, 2).toInt());
        hint = 'Square numbers: n²';
        break;
      case 6:
        seq = [1, 8, 27, 64, 125];
        hint = 'Cube numbers: n³';
        break;
      case 7:
        final start = _rand(1, 10) * 2;
        seq = List.generate(5, (i) => start + i * 2);
        hint = 'Even numbers';
        break;
      case 8:
        final start = _rand(0, 10) * 2 + 1;
        seq = List.generate(5, (i) => start + i * 2);
        hint = 'Odd numbers';
        break;
      default:
        seq = [1, 2, 4, 7, 11];
        hint = 'Steps increase: +1,+2,+3,+4…';
        break;
    }

    final answer = seq.last;
    final display = seq.sublist(0, 4);
    return _buildQ('${display.join(', ')}, ?', answer, hint,
        LogicCategory.numberSequence, 'easy');
  }

  static LogicQuestion _sequenceMedium() {
    final type = _rng.nextInt(10);
    List<int> seq;
    String hint;

    switch (type) {
      case 0:
        seq = [20, 19, 17, 14, 10];
        hint = 'Steps: −1,−2,−3,−4…';
        break;
      case 1:
        final s = _rand(1, 5);
        seq = List.generate(5, (i) {
          int v = s;
          for (int j = 0; j < i; j++) {
            v = v * 2 + 1;
          }
          return v;
        });
        hint = '×2 then +1 each step';
        break;
      case 2:
        final s = _rand(1, 3);
        seq = List.generate(5, (i) {
          int v = s;
          for (int j = 0; j < i; j++) {
            v = v * 3 - 2;
          }
          return v;
        });
        hint = '×3 then −2 each step';
        break;
      case 3:
        final s = _rand(2, 6);
        seq = [s];
        for (int i = 0; i < 4; i++) {
          seq.add(i % 2 == 0 ? seq.last * 2 : seq.last + 3);
        }
        hint = 'Alternating: ×2, +3, ×2, +3…';
        break;
      case 4:
        final off = _rand(1, 4);
        seq = List.generate(5, (i) => pow(i + off, 2).toInt() + 1);
        hint = 'n² + 1';
        break;
      case 5:
        final a = _rand(1, 5), b = _rand(1, 5);
        seq = [a, b];
        for (int i = 0; i < 3; i++) {
          seq.add(seq[seq.length - 1] + seq[seq.length - 2]);
        }
        hint = 'Each = sum of previous two';
        break;
      case 6:
        seq = [2, 3, 5, 7, 11];
        hint = 'Prime numbers';
        break;
      case 7:
        seq = [1, 3, 7, 13, 21];
        hint = 'Gaps: +2,+4,+6,+8…';
        break;
      case 8:
        final s2 = _rand(2, 5);
        seq = List.generate(5, (i) {
          int v = s2;
          for (int j = 0; j < i; j++) {
            v = v * 2 - 1;
          }
          return v;
        });
        hint = '×2 −1 each step';
        break;
      default:
        final c = _rand(2, 5);
        final off2 = _rand(2, 5);
        seq = List.generate(5, (i) => pow(i + off2, 2).toInt() - c);
        hint = 'n² − $c';
        break;
    }

    final answer = seq.last;
    final display = seq.sublist(0, 4);
    return _buildQ('${display.join(', ')}, ?', answer, hint,
        LogicCategory.numberSequence, 'medium');
  }

  static LogicQuestion _sequenceHard() {
    final type = _rng.nextInt(8);
    List<int> seq;
    String hint;

    switch (type) {
      case 0:
        seq = [2, 5, 3, 7, 4, 9, 5];
        hint = 'Two alternating series mixed';
        break;
      case 1:
        seq = [1, 2, 6, 24, 120];
        hint = 'Factorial: 1!,2!,3!,4!,5!…';
        break;
      case 2:
        final s = _rand(1, 3);
        seq = [s];
        for (int i = 1; i <= 4; i++) {
          seq.add(seq.last * i);
        }
        hint = 'Multiply by increasing numbers';
        break;
      case 3:
        seq = [1, 2, 6, 15, 31];
        hint = 'Add 1²,2²,3²,4²…';
        break;
      case 4:
        seq = [1, 2, 10, 37, 101];
        hint = 'Add 1³,2³,3³,4³…';
        break;
      case 5:
        seq = [10, 11, 2, 13, 4];
        hint = 'Next = digit sum of previous';
        break;
      case 6:
        seq = [2, 0, 5, 3, 10, 8, 17];
        hint = 'Alternating n²+1, n²−1';
        break;
      default:
        final s = _rand(2, 5);
        seq = [s];
        for (int i = 0; i < 6; i++) {
          if (i % 3 == 0) {
            seq.add(seq.last * 2);
          } else if (i % 3 == 1) {
            seq.add(seq.last + 3);
          } else {
            seq.add(seq.last - 1);
          }
        }
        hint = 'Cycle: ×2, +3, −1 repeating';
        break;
    }

    final answer = seq.last;
    final display = seq.sublist(0, seq.length - 1);
    return _buildQ('${display.join(', ')}, ?', answer, hint,
        LogicCategory.numberSequence, 'hard');
  }

  // ── MISSING NUMBER ────────────────────────────────────────────
  static LogicQuestion _missing(int diff) {
    if (diff == 0) return _missingEasy();
    if (diff == 1) return _missingMedium();
    return _missingHard();
  }

  static LogicQuestion _missingEasy() {
    final type = _rng.nextInt(4);
    int a, b, answer;
    String q, hint;

    switch (type) {
      case 0:
        b = _rand(2, 9);
        answer = _rand(2, 9);
        a = answer + b;
        q = '? + $b = $a';
        hint = 'Subtract $b from $a';
        break;
      case 1:
        b = _rand(2, 9);
        answer = _rand(2, 9);
        a = answer * b;
        q = '? × $b = $a';
        hint = 'Divide $a by $b';
        break;
      case 2:
        answer = _rand(2, 9);
        b = _rand(1, answer - 1);
        a = answer - b;
        q = '? − $b = $a';
        hint = 'Add $a and $b';
        break;
      default:
        b = _rand(2, 9);
        answer = _rand(2, 9);
        a = answer + b;
        q = '$a − ? = $b';
        hint = 'Subtract $b from $a';
        answer = a - b;
        break;
    }
    return _buildQ(q, answer, hint, LogicCategory.missingNumber, 'easy');
  }

  static LogicQuestion _missingMedium() {
    final type = _rng.nextInt(4);
    int a, b, answer;
    String q, hint;

    switch (type) {
      case 0:
        b = _rand(3, 15);
        answer = _rand(3, 15);
        a = answer * b;
        q = '? × $b = $a';
        hint = '$a ÷ $b = ?';
        break;
      case 1:
        answer = _rand(2, 10);
        a = answer * answer;
        q = '√$a = ?';
        hint = 'Which number squared = $a?';
        answer = (sqrt(a)).toInt();
        break;
      case 2:
        b = _rand(2, 12);
        answer = _rand(2, 20);
        a = answer * b;
        q = '$a ÷ ? = $answer';
        hint = '$a ÷ $answer = ?';
        answer = b;
        break;
      default:
        answer = _rand(2, 8);
        a = answer * answer * answer;
        q = '∛$a = ?';
        hint = 'Which number cubed = $a?';
        break;
    }
    return _buildQ(q, answer, hint, LogicCategory.missingNumber, 'medium');
  }

  static LogicQuestion _missingHard() {
    final type = _rng.nextInt(3);
    int answer;
    String q, hint;

    switch (type) {
      case 0:
        final b = _rand(2, 12);
        answer = _rand(2, 15);
        final a = answer * b + _rand(1, 5);
        q = '($a − ?) ÷ $b = $answer';
        hint = 'Work backwards: $answer×$b = ${answer * b}';
        answer = a - answer * b; // ← fixed: removed unused 'r' variable
        break;
      case 1:
        answer = _rand(3, 12);
        final sq = answer * answer;
        q = '?² + 3 = ${sq + 3}';
        hint = 'Find the base: subtract then square root';
        answer = (sqrt(sq)).toInt();
        break;
      default:
        final base = _rand(2, 8);
        answer = base * base + base;
        q = 'n² + n = $answer, find n';
        hint = 'Try small values of n';
        answer = base;
        break;
    }
    return _buildQ(q, answer, hint, LogicCategory.missingNumber, 'hard');
  }

  // ── ODD ONE OUT ───────────────────────────────────────────────
  static LogicQuestion _oddOne(int diff) {
    if (diff == 0) return _oddEasy();
    if (diff == 1) return _oddMedium();
    return _oddHard();
  }

  static LogicQuestion _oddEasy() {
    final type = _rng.nextInt(5);
    List<int> options;
    int odd;
    String hint;

    switch (type) {
      case 0:
        final evens = _uniqueInts(3, 2, 40, mustBeEven: true);
        odd = _rand(1, 19) * 2 + 1;
        options = [...evens, odd]..shuffle(_rng);
        hint = 'One is odd, others are even';
        break;
      case 1:
        final odds = _uniqueInts(3, 1, 40, mustBeOdd: true);
        odd = _rand(1, 20) * 2;
        options = [...odds, odd]..shuffle(_rng);
        hint = 'One is even, others are odd';
        break;
      case 2:
        final mult3 = _uniqueMultiples(3, 3, 1, 15);
        do {
          odd = _rand(2, 45);
        } while (odd % 3 == 0);
        options = [...mult3, odd]..shuffle(_rng);
        hint = 'One is not a multiple of 3';
        break;
      case 3:
        final mult5 = _uniqueMultiples(3, 5, 1, 10);
        do {
          odd = _rand(2, 50);
        } while (odd % 5 == 0);
        options = [...mult5, odd]..shuffle(_rng);
        hint = 'One is not a multiple of 5';
        break;
      default:
        final mult2 = _uniqueMultiples(3, 2, 1, 20);
        odd = _rand(1, 20) * 2 + 1;
        options = [...mult2, odd]..shuffle(_rng);
        hint = 'One is not a multiple of 2';
        break;
    }

    final nums = options.map((e) => e.toString()).toList();
    return LogicQuestion(
      questionText: 'Odd one out: ${nums.join(', ')}',
      correct: odd.toString(),
      options: nums,
      hintText: hint,
      category: LogicCategory.oddOneOut,
      difficulty: 'easy',
    );
  }

  static LogicQuestion _oddMedium() {
    final type = _rng.nextInt(5);
    List<int> options;
    int odd;
    String hint;

    switch (type) {
      case 0:
        final squares = [4, 9, 16, 25, 36, 49, 64, 81, 100];
        final picked = (List.from(squares)..shuffle(_rng)).take(3).toList();
        do {
          odd = _rand(2, 100);
        } while (squares.contains(odd));
        options = [...picked, odd]..shuffle(_rng);
        hint = 'One is not a perfect square';
        break;
      case 1:
        final cubes = [8, 27, 64, 125];
        final picked2 = (List.from(cubes)..shuffle(_rng)).take(3).toList();
        do {
          odd = _rand(2, 130);
        } while (cubes.contains(odd));
        options = [...picked2, odd]..shuffle(_rng);
        hint = 'One is not a perfect cube';
        break;
      case 2:
        final primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
        final picked3 = (List.from(primes)..shuffle(_rng)).take(3).toList();
        do {
          odd = _rand(4, 40);
        } while (_isPrime(odd));
        options = [...picked3, odd]..shuffle(_rng);
        hint = 'One is not a prime number';
        break;
      case 3:
        final fibs = [1, 2, 3, 5, 8, 13, 21, 34, 55];
        final picked4 = (List.from(fibs)..shuffle(_rng)).take(3).toList();
        do {
          odd = _rand(2, 60);
        } while (fibs.contains(odd));
        options = [...picked4, odd]..shuffle(_rng);
        hint = 'One is not a Fibonacci number';
        break;
      default:
        final step = _rand(2, 8);
        final start = _rand(2, 10);
        final correct3 = List.generate(3, (i) => start + i * step);
        odd = correct3.last + step + _rand(1, 5);
        options = [...correct3, odd]..shuffle(_rng);
        hint = 'One breaks the arithmetic progression';
        break;
    }

    final nums = options.map((e) => e.toString()).toList();
    return LogicQuestion(
      questionText: 'Odd one out: ${nums.join(', ')}',
      correct: odd.toString(),
      options: nums,
      hintText: hint,
      category: LogicCategory.oddOneOut,
      difficulty: 'medium',
    );
  }

  static LogicQuestion _oddHard() {
    final type = _rng.nextInt(4);
    List<int> options;
    int odd;
    String hint;

    switch (type) {
      case 0:
        final seq = [2, 5, 4, 7, 6, 9, 8];
        odd = seq[_rand(2, 6)] + _rand(1, 3);
        options = [seq[0], seq[1], seq[2], odd]..shuffle(_rng);
        hint = 'One breaks the alternating +3,−1 pattern';
        break;
      case 1:
        final both = _uniqueMultiples(3, 6, 1, 15);
        do {
          odd = _rand(2, 90);
        } while (odd % 6 == 0);
        options = [...both, odd]..shuffle(_rng);
        hint = 'One is not divisible by both 2 and 3';
        break;
      case 2:
        const ds9 = [18, 27, 36, 45, 54, 63, 72, 81, 90];
        final picked = (List.from(ds9)..shuffle(_rng)).take(3).toList();
        do {
          odd = _rand(10, 99);
        } while (_digitSum(odd) == 9);
        options = [...picked, odd]..shuffle(_rng);
        hint = 'One has a different digit sum';
        break;
      default:
        final ratio = _rand(2, 3);
        final start = _rand(1, 4);
        final correct3 = List.generate(3, (i) => start * pow(ratio, i).toInt());
        odd = correct3.last * ratio + _rand(1, 4);
        options = [...correct3, odd]..shuffle(_rng);
        hint = 'One breaks the geometric progression';
        break;
    }

    final nums = options.map((e) => e.toString()).toList();
    return LogicQuestion(
      questionText: 'Odd one out: ${nums.join(', ')}',
      correct: odd.toString(),
      options: nums,
      hintText: hint,
      category: LogicCategory.oddOneOut,
      difficulty: 'hard',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  static LogicQuestion _buildQ(
      String q, int answer, String hint, LogicCategory cat, String diff) {
    final correct = answer.toString();
    final wrongs = <int>{};
    int attempts = 0;
    while (wrongs.length < 3 && attempts < 50) {
      attempts++;
      final delta = _rand(1, max(3, (answer.abs() * 0.3).ceil()));
      final w = _rng.nextBool() ? answer + delta : answer - delta;
      if (w != answer && w >= 0) wrongs.add(w);
    }
    while (wrongs.length < 3) {
      wrongs.add(answer + wrongs.length + 1);
    }
    final opts = [correct, ...wrongs.map((e) => e.toString())]..shuffle(_rng);
    return LogicQuestion(
      questionText: q,
      correct: correct,
      options: opts,
      hintText: hint,
      category: cat,
      difficulty: diff,
    );
  }

  static List<int> _uniqueInts(int count, int min, int max,
      {bool mustBeEven = false, bool mustBeOdd = false}) {
    final result = <int>{};
    int attempts = 0;
    while (result.length < count && attempts < 100) {
      attempts++;
      final v = _rand(min, max);
      if (mustBeEven && v % 2 != 0) continue;
      if (mustBeOdd && v % 2 == 0) continue;
      result.add(v);
    }
    return result.toList();
  }

  static List<int> _uniqueMultiples(int count, int factor, int minK, int maxK) {
    final result = <int>{};
    int attempts = 0;
    while (result.length < count && attempts < 100) {
      attempts++;
      result.add(factor * _rand(minK, maxK));
    }
    return result.toList();
  }

  static bool _isPrime(int n) {
    if (n < 2) return false;
    for (int i = 2; i <= sqrt(n).toInt(); i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  static int _digitSum(int n) {
    int s = 0;
    while (n > 0) {
      s += n % 10;
      n ~/= 10;
    }
    return s;
  }
}
