import 'math_operation.dart';

// -1 means infinite (no question limit)
const int kInfiniteQuestions = -1;

class GameState {
  final int score;
  final int streak;
  final int bestStreak;
  final int questionIndex; // how many answered so far
  final int totalQuestions; // -1 = infinite
  final int correctAnswers;
  final List<bool> history;
  final bool isGameOver; // true when wrong answer in infinite/random mode

  const GameState({
    this.score = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.questionIndex = 0,
    this.totalQuestions = 20,
    this.correctAnswers = 0,
    this.history = const [],
    this.isGameOver = false,
  });

  GameState copyWith({
    int? score,
    int? streak,
    int? bestStreak,
    int? questionIndex,
    int? totalQuestions,
    int? correctAnswers,
    List<bool>? history,
    bool? isGameOver,
  }) {
    return GameState(
      score: score ?? this.score,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      questionIndex: questionIndex ?? this.questionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      history: history ?? this.history,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }

  double get accuracy =>
      questionIndex == 0 ? 0 : correctAnswers / questionIndex;

  /// Session ends when: fixed mode hits limit, OR game over flag set
  bool get isComplete {
    if (isGameOver) return true;
    if (totalQuestions == kInfiniteQuestions) return false;
    return questionIndex >= totalQuestions;
  }

  bool get isInfinite => totalQuestions == kInfiniteQuestions;
}

enum GameMode { random, training }

class GameSession {
  final GameMode mode;
  final MathOperation? trainingOp;
  final int totalQuestions; // -1 = infinite
  final int difficulty; // 0=easy 1=medium 2=hard

  const GameSession({
    required this.mode,
    this.trainingOp,
    this.totalQuestions = 20,
    this.difficulty = 1, // medium by default
  });

  bool get isInfinite => totalQuestions == kInfiniteQuestions;
}
