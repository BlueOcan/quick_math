import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MathOperation {
  addition,
  subtraction,
  multiplication,
  division,
  squaring,
  nthRoot,
  percentage,
}

extension MathOperationExt on MathOperation {
  String get label {
    switch (this) {
      case MathOperation.addition:
        return 'Addition';
      case MathOperation.subtraction:
        return 'Subtraction';
      case MathOperation.multiplication:
        return 'Multiplication';
      case MathOperation.division:
        return 'Division';
      case MathOperation.squaring:
        return 'Squaring';
      case MathOperation.nthRoot:
        return 'nth Root';
      case MathOperation.percentage:
        return 'Percentage';
    }
  }

  String get symbol {
    switch (this) {
      case MathOperation.addition:
        return '+';
      case MathOperation.subtraction:
        return '−';
      case MathOperation.multiplication:
        return '×';
      case MathOperation.division:
        return '÷';
      case MathOperation.squaring:
        return 'x²';
      case MathOperation.nthRoot:
        return 'ⁿ√';
      case MathOperation.percentage:
        return '%';
    }
  }

  Color get color {
    switch (this) {
      case MathOperation.addition:
        return AppTheme.opAdd;
      case MathOperation.subtraction:
        return AppTheme.opSub;
      case MathOperation.multiplication:
        return AppTheme.opMul;
      case MathOperation.division:
        return AppTheme.opDiv;
      case MathOperation.squaring:
        return AppTheme.opSq;
      case MathOperation.nthRoot:
        return AppTheme.opRoot;
      case MathOperation.percentage:
        return AppTheme.opExp; // orange-red — distinct from others
    }
  }

  IconData get icon {
    switch (this) {
      case MathOperation.addition:
        return Icons.add_rounded;
      case MathOperation.subtraction:
        return Icons.remove_rounded;
      case MathOperation.multiplication:
        return Icons.close_rounded;
      case MathOperation.division:
        return Icons.more_horiz_rounded;
      case MathOperation.squaring:
        return Icons.superscript_rounded;
      case MathOperation.nthRoot:
        return Icons.calculate_rounded;
      case MathOperation.percentage:
        return Icons.percent_rounded;
    }
  }

  String get description {
    switch (this) {
      case MathOperation.addition:
        return '2-digit up to 4-digit sums';
      case MathOperation.subtraction:
        return '2-digit up to 4-digit';
      case MathOperation.multiplication:
        return '2-digit × 2-digit';
      case MathOperation.division:
        return 'Mental calculation quotients';
      case MathOperation.squaring:
        return 'Square numbers 11–40';
      case MathOperation.nthRoot:
        return 'Square & cube roots';
      case MathOperation.percentage:
        return 'a% of b & reverse problems';
    }
  }
}

class MathQuestion {
  final String questionText;
  final double answer;
  final MathOperation operation;
  final String hintText;
  const MathQuestion({
    required this.questionText,
    required this.answer,
    required this.operation,
    required this.hintText,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// QuestionGenerator
// ─────────────────────────────────────────────────────────────────────────────
class QuestionGenerator {
  static final Random _rng = Random();
  static int _rand(int min, int max) => min + _rng.nextInt(max - min + 1);

  // ── Session duplicate prevention ─────────────────────────────────────────
  static final Set<String> _seenQuestions = {};
  static const int _maxRetries = 20;

  static void resetSession() {
    _seenQuestions.clear();
    _opQueue.clear();
    _lastOpIndex = null;
  }

  static MathQuestion _unique(MathQuestion Function() builder) {
    for (int i = 0; i < _maxRetries; i++) {
      final q = builder();
      if (_seenQuestions.add(q.questionText)) return q;
    }
    return builder();
  }

  // ── Balanced rotation (Random/Survive mode) ───────────────────────────────
  // Pool size is now 7 to include percentage
  static final List<int> _opQueue = [];
  static int? _lastOpIndex;

  static int _nextBalancedOpIndex() {
    if (_opQueue.isEmpty) {
      final pool = List<int>.generate(7, (i) => i)..shuffle(_rng);
      if (_lastOpIndex != null && pool.first == _lastOpIndex) {
        final swapIdx = 1 + _rng.nextInt(6);
        final tmp = pool[0];
        pool[0] = pool[swapIdx];
        pool[swapIdx] = tmp;
      }
      _opQueue.addAll(pool);
    }
    final opIndex = _opQueue.removeAt(0);
    _lastOpIndex = opIndex;
    return opIndex;
  }

  // ── Training mode: difficulty-aware ──────────────────────────────────────
  static MathQuestion generate(MathOperation op, [int difficulty = 1]) {
    switch (op) {
      case MathOperation.addition:
        return _unique(() => _additionByDiff(difficulty));
      case MathOperation.subtraction:
        return _unique(() => _subtractionByDiff(difficulty));
      case MathOperation.multiplication:
        return _unique(() => _multiplicationByDiff(difficulty));
      case MathOperation.division:
        return _unique(() => _divisionByDiff(difficulty));
      case MathOperation.squaring:
        return _unique(() => _squaringByDiff(difficulty));
      case MathOperation.nthRoot:
        return _unique(() => _nthRootByDiff(difficulty));
      case MathOperation.percentage:
        return _unique(() => _percentageByDiff(difficulty));
    }
  }

  // ── Progressive / Survive mode ───────────────────────────────────────────
  // Now uses 7 operations (index 0–6), index 6 = percentage
  static MathQuestion generateProgressive(int questionIndex) {
    final int tier = questionIndex < 5
        ? 0
        : questionIndex < 15
            ? 1
            : questionIndex < 30
                ? 2
                : questionIndex < 50
                    ? 3
                    : questionIndex < 75
                        ? 4
                        : 5;
    final int opIndex = _nextBalancedOpIndex();
    switch (opIndex) {
      case 0:
        return _unique(_addition);
      case 1:
        return _unique(_subtraction);
      case 2:
        return _unique(
            () => _multiplicationByTier(_mulTierForDifficulty(tier)));
      case 3:
        return _unique(() => _divisionByTier(_divTierForDifficulty(tier)));
      case 4:
        return _unique(_squaring);
      case 5:
        return _unique(() => _nthRootByTier(_rootTierForDifficulty(tier)));
      default: // 6 = percentage
        return _unique(() => _percentageByTier(tier));
    }
  }

  // ── Tier mappers for progressive mode ────────────────────────────────────
  static int _mulTierForDifficulty(int t) {
    const m = [1, 1, 2, 2, 3, 4];
    return m[t.clamp(0, 5)];
  }

  static int _divTierForDifficulty(int t) {
    const m = [1, 1, 2, 2, 3, 4];
    return m[t.clamp(0, 5)];
  }

  static int _rootTierForDifficulty(int t) {
    const m = [1, 1, 2, 3, 3, 4];
    return m[t.clamp(0, 5)];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIFFICULTY-AWARE TRAINING GENERATORS
  // ─────────────────────────────────────────────────────────────────────────

  // ADDITION
  static MathQuestion _additionByDiff(int diff) {
    int a, b;
    String hint;
    switch (diff) {
      case 0:
        a = _rand(2, 9);
        b = _rand(2, 9);
        hint = 'Count up from the larger number';
        break;
      case 1:
        a = _rand(10, 99);
        b = _rand(10, 99);
        hint = 'Break into tens & units';
        break;
      default:
        a = _rand(100, 999);
        b = _rand(100, 999);
        hint = 'Column by column in your head';
        break;
    }
    return MathQuestion(
      questionText: '${a < b ? a : b} + ${a < b ? b : a} = ?',
      answer: (a + b).toDouble(),
      operation: MathOperation.addition,
      hintText: hint,
    );
  }

  // SUBTRACTION
  static MathQuestion _subtractionByDiff(int diff) {
    int a, b;
    String hint;
    switch (diff) {
      case 0:
        a = _rand(3, 9);
        b = _rand(1, a - 1);
        hint = 'Count down from $a';
        break;
      case 1:
        a = _rand(21, 99);
        b = _rand(10, a - 1);
        hint = 'Round up b, subtract, then adjust';
        break;
      default:
        a = _rand(200, 999);
        b = _rand(100, a - 1);
        hint = 'Column subtraction in your head';
        break;
    }
    return MathQuestion(
      questionText: '$a − $b = ?',
      answer: (a - b).toDouble(),
      operation: MathOperation.subtraction,
      hintText: hint,
    );
  }

  // MULTIPLICATION
  static MathQuestion _multiplicationByDiff(int diff) {
    int a, b;
    String hint;
    switch (diff) {
      case 0:
        a = _rand(2, 9);
        b = _rand(2, 9);
        hint = 'Times table recall';
        break;
      case 1:
        a = _rand(11, 99);
        b = _rand(2, 9);
        hint = 'Multiply tens, then units, add';
        break;
      default:
        a = _rand(11, 99);
        b = _rand(11, 99);
        hint = 'Split each into tens & units';
        break;
    }
    return MathQuestion(
      questionText: '$a × $b = ?',
      answer: (a * b).toDouble(),
      operation: MathOperation.multiplication,
      hintText: hint,
    );
  }

  // DIVISION
  static MathQuestion _divisionByDiff(int diff) {
    int divisor, result;
    String hint;
    switch (diff) {
      case 0:
        divisor = _rand(2, 9);
        result = _rand(2, 9);
        hint = 'Times table recall';
        break;
      case 1:
        divisor = _rand(2, 9);
        result = _rand(2, 20);
        hint = 'Think: ? × $divisor = dividend';
        break;
      default:
        divisor = _rand(2, 12);
        result = _rand(2, 50);
        hint = 'Break dividend into parts';
        break;
    }
    final dividend = divisor * result;
    return MathQuestion(
      questionText: '$dividend ÷ $divisor = ?',
      answer: result.toDouble(),
      operation: MathOperation.division,
      hintText: hint,
    );
  }

  // SQUARING
  static MathQuestion _squaringByDiff(int diff) {
    int a;
    switch (diff) {
      case 0:
        a = _rand(2, 9);
        break;
      case 1:
        a = _rand(10, 20);
        break;
      default:
        a = _rand(21, 40);
        break;
    }
    return MathQuestion(
      questionText: '$a² = ?',
      answer: (a * a).toDouble(),
      operation: MathOperation.squaring,
      hintText: '(a+b)² = a² + 2ab + b²',
    );
  }

  // NTH ROOT
  static MathQuestion _nthRootByDiff(int diff) {
    switch (diff) {
      case 0:
        {
          final r = _rand(2, 9);
          return MathQuestion(
            questionText: '√${r * r} = ?',
            answer: r.toDouble(),
            operation: MathOperation.nthRoot,
            hintText: 'Which number × itself = ${r * r}?',
          );
        }
      case 1:
        {
          final r = _rand(2, 15);
          return MathQuestion(
            questionText: '√${r * r} = ?',
            answer: r.toDouble(),
            operation: MathOperation.nthRoot,
            hintText: 'x² = ${r * r}, find x',
          );
        }
      default:
        {
          final cubes = [2, 3, 4, 5, 6, 7, 8];
          final r = cubes[_rng.nextInt(cubes.length)];
          final cube = r * r * r;
          return MathQuestion(
            questionText: '∛$cube = ?',
            answer: r.toDouble(),
            operation: MathOperation.nthRoot,
            hintText: 'x³ = $cube, find x',
          );
        }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERCENTAGE — Training (difficulty-aware)
  //
  // Question types:
  //   Type A: "X% of Y = ?"          → answer = X*Y/100  (whole number result)
  //   Type B: "Y × X / 100 = ?"      → same as above, written differently
  //   Type C (hard): "X is ?% of Y"  → answer = X/Y*100  (whole number %)
  //
  // All answers are guaranteed whole numbers to keep mental-math fair.
  //
  // Easy   (diff=0): simple % like 10, 20, 25, 50 of small numbers (≤50)
  // Medium (diff=1): % like 5,10,15,20,25,50,75 of 2-digit numbers
  // Hard   (diff=2): any multiple-of-5 % of 3-digit numbers, plus reverse type
  // ─────────────────────────────────────────────────────────────────────────
  static MathQuestion _percentageByDiff(int diff) {
    switch (diff) {
      case 0:
        return _percentageEasy();
      case 1:
        return _percentageMedium();
      default:
        return _percentageHard();
    }
  }

  static MathQuestion _percentageEasy() {
    // Use only 10%, 20%, 25%, 50% of multiples of 4 or 10 (≤50)
    // so result is always whole
    const percents = [10, 20, 25, 50];
    final pct = percents[_rng.nextInt(percents.length)];
    // Pick a number whose pct% is whole: multiples of (100/pct)
    final step = 100 ~/ pct;
    final count = _rand(1, 10); // e.g. step=4 for 25%, count 1-10 → 4-40
    final b = step * count;
    final answer = (pct * b) ~/ 100;
    return MathQuestion(
      questionText: '$pct% of $b = ?',
      answer: answer.toDouble(),
      operation: MathOperation.percentage,
      hintText: 'Divide $b by ${100 ~/ pct}',
    );
  }

  static MathQuestion _percentageMedium() {
    // Use 5,10,15,20,25,50,75 of 2-digit multiples ensuring whole answer
    const percents = [5, 10, 15, 20, 25, 50, 75];
    final pct = percents[_rng.nextInt(percents.length)];
    // step = lcm-friendly: for pct=15, need multiple of 20; for 75 multiple of 4
    // Simple approach: b = pct * k where k is 2–20, then answer = pct*b/100 = k*pct*pct/100
    // Better: b = (100/gcd(pct,100)) * k, k in range
    final g = _gcd(pct, 100);
    final step = 100 ~/ g; // smallest b giving whole answer
    final maxK = (99 ~/ step).clamp(1, 20);
    final k = _rand(1, maxK);
    final b = step * k;
    final answer = (pct * b) ~/ 100;
    final hintPct = pct <= 50
        ? 'Find ${pct ~/ _gcd(pct, 100)}/${100 ~/ _gcd(pct, 100)} of $b'
        : 'Use 50% then adjust';
    return MathQuestion(
      questionText: '$pct% of $b = ?',
      answer: answer.toDouble(),
      operation: MathOperation.percentage,
      hintText: hintPct,
    );
  }

  static MathQuestion _percentageHard() {
    // 50% chance: forward (a% of b) with 3-digit b
    // 50% chance: reverse ("X is ?% of Y")
    if (_rng.nextBool()) {
      // Forward with 3-digit number
      const percents = [5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 80];
      final pct = percents[_rng.nextInt(percents.length)];
      final g = _gcd(pct, 100);
      final step = 100 ~/ g;
      final maxK = (500 ~/ step).clamp(2, 30);
      final k = _rand(2, maxK);
      final b = step * k;
      final answer = (pct * b) ~/ 100;
      return MathQuestion(
        questionText: '$pct% of $b = ?',
        answer: answer.toDouble(),
        operation: MathOperation.percentage,
        hintText:
            'Break: ${pct ~/ 10 > 0 ? "${(pct ~/ 10) * 10}% + ${pct % 10}%" : "$pct%"} of $b',
      );
    } else {
      // Reverse: "X is ?% of Y" — pick whole-number %
      // Pick % first (multiple of 5, 5–95), then Y (2-digit multiple of 20)
      const percents = [5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 80];
      final pct = percents[_rng.nextInt(percents.length)];
      final g = _gcd(pct, 100);
      final step = 100 ~/ g;
      final k = _rand(1, 10);
      final b = step * k;
      final x = (pct * b) ~/ 100;
      return MathQuestion(
        questionText: '$x is ?% of $b',
        answer: pct.toDouble(),
        operation: MathOperation.percentage,
        hintText: '($x ÷ $b) × 100 = ?',
      );
    }
  }

  // Euclidean GCD helper
  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERCENTAGE — Progressive/Random mode tier
  // tier 0-1: easy style, tier 2-3: medium, tier 4-5: hard
  // ─────────────────────────────────────────────────────────────────────────
  static MathQuestion _percentageByTier(int tier) {
    if (tier <= 1) return _percentageEasy();
    if (tier <= 3) return _percentageMedium();
    return _percentageHard();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RANDOM/SURVIVE mode generators (unchanged)
  // ─────────────────────────────────────────────────────────────────────────
  static MathQuestion _addition() {
    int a, b;
    String hint;
    switch (_rng.nextInt(5)) {
      case 0:
        a = _rand(10, 99);
        b = _rand(10, 99);
        hint = 'Break into tens & units';
        break;
      case 1:
        a = _rand(10, 99);
        b = _rand(100, 999);
        hint = 'Add hundreds first, then tens & units';
        break;
      case 2:
        a = _rand(100, 999);
        b = _rand(100, 999);
        hint = 'Column by column in your head';
        break;
      case 3:
        a = _rand(100, 999);
        b = _rand(1000, 9999);
        hint = 'Round the 4-digit number, then adjust';
        break;
      default:
        a = _rand(1000, 9999);
        b = _rand(1000, 9999);
        hint = 'Split into pairs of digits';
        break;
    }
    if (a > b) {
      final t = a;
      a = b;
      b = t;
    }
    return MathQuestion(
        questionText: '$a + $b = ?',
        answer: (a + b).toDouble(),
        operation: MathOperation.addition,
        hintText: hint);
  }

  static MathQuestion _subtraction() {
    int a, b;
    String hint;
    switch (_rng.nextInt(5)) {
      case 0:
        a = _rand(21, 99);
        b = _rand(10, a - 1);
        hint = 'Round up b, subtract, then adjust';
        break;
      case 1:
        a = _rand(100, 999);
        b = _rand(10, 99);
        hint = 'Subtract tens then units';
        break;
      case 2:
        a = _rand(200, 999);
        b = _rand(100, a - 1);
        hint = 'Column subtraction in your head';
        break;
      case 3:
        a = _rand(1000, 9999);
        b = _rand(100, 999);
        hint = 'Round b to nearest 100, then adjust';
        break;
      default:
        a = _rand(2000, 9999);
        b = _rand(1000, a - 1);
        hint = 'Break into two 2-digit problems';
        break;
    }
    return MathQuestion(
        questionText: '$a − $b = ?',
        answer: (a - b).toDouble(),
        operation: MathOperation.subtraction,
        hintText: hint);
  }

  static MathQuestion _squaring() {
    final a = _rand(11, 40);
    return MathQuestion(
        questionText: '$a² = ?',
        answer: (a * a).toDouble(),
        operation: MathOperation.squaring,
        hintText: '(a+b)² = a² + 2ab + b²');
  }

  static MathQuestion _multiplicationByTier(int tier) {
    int a, b;
    String hint;
    switch (tier) {
      case 1:
        a = _rand(11, 19);
        b = _rand(11, 19);
        hint = 'Use (10+a)(10+b)=100+10(a+b)+ab';
        break;
      case 2:
        a = _rand(11, 25);
        b = _rand(11, 25);
        hint = 'Split: a×b=(a×20)+(a×(b−20))';
        break;
      case 3:
        a = _rand(11, 50);
        b = _rand(11, 50);
        hint = 'Round one number, then adjust';
        break;
      default:
        a = _rand(11, 99);
        b = _rand(11, 99);
        hint = 'Split each into tens & units';
        break;
    }
    return MathQuestion(
        questionText: '$a × $b = ?',
        answer: (a * b).toDouble(),
        operation: MathOperation.multiplication,
        hintText: hint);
  }

  static MathQuestion _divisionByTier(int tier) {
    int divisor, result;
    String hint;
    switch (tier) {
      case 1:
        divisor = _rand(2, 9);
        result = _rand(2, 10);
        hint = 'Times table recall';
        break;
      case 2:
        divisor = _rand(2, 9);
        result = _rand(2, 20);
        hint = 'Think: ? × $divisor = dividend';
        break;
      case 3:
        divisor = _rand(2, 12);
        result = _rand(2, 20);
        hint = 'Use factor pairs';
        break;
      default:
        divisor = _rand(2, 12);
        result = _rand(10, 50);
        hint = 'Break dividend into parts';
        break;
    }
    return MathQuestion(
        questionText: '${divisor * result} ÷ $divisor = ?',
        answer: result.toDouble(),
        operation: MathOperation.division,
        hintText: hint);
  }

  static MathQuestion _nthRootByTier(int tier) {
    switch (tier) {
      case 1:
        {
          final r = _rand(2, 15);
          return MathQuestion(
              questionText: '√${r * r} = ?',
              answer: r.toDouble(),
              operation: MathOperation.nthRoot,
              hintText: 'x² = ${r * r}, find x');
        }
      case 2:
        {
          final r = _rand(10, 20);
          return MathQuestion(
              questionText: '√${r * r} = ?',
              answer: r.toDouble(),
              operation: MathOperation.nthRoot,
              hintText: 'x² = ${r * r}, find x');
        }
      case 3:
        {
          final cubes = [2, 3, 4, 5, 6];
          final r = cubes[_rng.nextInt(5)];
          final c = r * r * r;
          return MathQuestion(
              questionText: '∛$c = ?',
              answer: r.toDouble(),
              operation: MathOperation.nthRoot,
              hintText: 'x³ = $c, find x');
        }
      default:
        {
          if (_rng.nextBool()) {
            final r = _rand(2, 20);
            return MathQuestion(
                questionText: '√${r * r} = ?',
                answer: r.toDouble(),
                operation: MathOperation.nthRoot,
                hintText: 'x² = ${r * r}');
          }
          final cubes = [2, 3, 4, 5, 6, 7, 8];
          final r = cubes[_rng.nextInt(7)];
          final c = r * r * r;
          return MathQuestion(
              questionText: '∛$c = ?',
              answer: r.toDouble(),
              operation: MathOperation.nthRoot,
              hintText: 'x³ = $c');
        }
    }
  }
}
