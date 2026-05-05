import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/math_operation.dart';
import '../models/game_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/number_keypad.dart';
import '../main.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameSession session;
  const GameScreen({super.key, required this.session});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
  late MathQuestion _currentQuestion;
  late GameState _gameState;
  String _input = '';
  bool _showFeedback = false;
  bool _feedbackCorrect = false;
  String? _feedbackAnswer;

  // ── Timer ──────────────────────────────────────────────────────
  static const int _timerDuration = 30;
  int _secondsLeft = _timerDuration;
  Timer? _timer;
  bool _timerPaused = false;

  // ── Animations ─────────────────────────────────────────────────
  late AnimationController _questionCtrl;
  late Animation<double> _questionFade;
  late Animation<Offset> _questionSlide;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    QuestionGenerator.resetSession();
    _gameState = GameState(totalQuestions: widget.session.totalQuestions);

    _questionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _questionFade =
        CurvedAnimation(parent: _questionCtrl, curve: Curves.easeOut);
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionCtrl, curve: Curves.easeOut));

    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _feedbackAnim =
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.easeOut);

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Core ───────────────────────────────────────────────────────
  void _generateQuestion() {
    final op = widget.session.trainingOp;
    if (widget.session.mode == GameMode.training && op != null) {
      _currentQuestion =
          QuestionGenerator.generate(op, widget.session.difficulty);
    } else {
      _currentQuestion = QuestionGenerator.generateProgressive(
        _gameState.questionIndex,
      );
    }
    _questionCtrl.forward(from: 0);
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _timerDuration;
    _timerPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _timerPaused) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_showFeedback) _processAnswer(correct: false);
      }
    });
  }

  // ── Input ──────────────────────────────────────────────────────
  void _onDigit(String d) {
    if (_showFeedback) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (d == '-') {
        _input = _input.startsWith('-') ? _input.substring(1) : '-$_input';
      } else if (_input.length < 9) {
        _input += d;
      }
    });
  }

  void _onDelete() {
    if (_showFeedback || _input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onSubmit() {
    if (_showFeedback || _input.isEmpty) return;
    final parsed = double.tryParse(_input);
    if (parsed == null) return;
    final correct = (parsed - _currentQuestion.answer).abs() < 0.001;
    HapticFeedback.mediumImpact();
    _processAnswer(correct: correct);
  }

  // ── Answer processing ──────────────────────────────────────────
  void _processAnswer({required bool correct}) {
    _timer?.cancel();

    final newHistory = [..._gameState.history, correct];
    final newStreak = correct ? _gameState.streak + 1 : 0;
    final newBest =
        newStreak > _gameState.bestStreak ? newStreak : _gameState.bestStreak;
    final newScore = correct ? _gameState.score + 1 : _gameState.score;

    final bool gameOver = !correct &&
        (widget.session.mode == GameMode.random || widget.session.isInfinite);

    final newState = _gameState.copyWith(
      score: newScore,
      streak: newStreak,
      bestStreak: newBest,
      questionIndex: _gameState.questionIndex + 1,
      correctAnswers:
          correct ? _gameState.correctAnswers + 1 : _gameState.correctAnswers,
      history: newHistory,
      isGameOver: gameOver,
    );

    final answerStr = _currentQuestion.answer % 1 == 0
        ? _currentQuestion.answer.toInt().toString()
        : _currentQuestion.answer.toStringAsFixed(2);

    setState(() {
      _gameState = newState;
      _showFeedback = true;
      _feedbackCorrect = correct;
      _feedbackAnswer = answerStr;
    });

    _feedbackCtrl.forward(from: 0);

    final delay = gameOver
        ? const Duration(milliseconds: 1400)
        : const Duration(milliseconds: 800);

    Future.delayed(delay, () {
      if (!mounted) return;
      _feedbackCtrl.reverse();
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        if (_gameState.isComplete) {
          _goToResults();
        } else {
          setState(() {
            _showFeedback = false;
            _input = '';
          });
          _generateQuestion();
          _startTimer();
        }
      });
    });
  }

  void _goToResults() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => ResultScreen(
        gameState: _gameState,
        session: widget.session,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final op = _currentQuestion.operation;
        final isDark = themeNotifier.value == ThemeMode.dark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
        final border = isDark ? AppTheme.border : AppTheme.lightBorder;
        final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

        final double progress = (!widget.session.isInfinite &&
                widget.session.mode == GameMode.training)
            ? (_gameState.questionIndex / _gameState.totalQuestions)
                .clamp(0.0, 1.0)
            : 0.0;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(
                        op, progress, surface, border, textMuted, textPrimary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildStatsRow(textPrimary, textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildQuestionCard(op, surface, textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildHint(textMuted),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: NumberKeypad(
                            currentInput: _input,
                            onDigitTap: _onDigit,
                            onDelete: _onDelete,
                            onSubmit: _onSubmit,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showFeedback)
                  FadeTransition(
                    opacity: _feedbackAnim,
                    child: FeedbackOverlay(
                      isCorrect: _feedbackCorrect,
                      correctAnswer: _feedbackCorrect ? null : _feedbackAnswer,
                      isGameOver: _gameState.isGameOver,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top bar ────────────────────────────────────────────────────
  Widget _buildTopBar(MathOperation op, double progress, Color surface,
      Color border, Color textMuted, Color textPrimary) {
    final isInf =
        widget.session.isInfinite || widget.session.mode == GameMode.random;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmQuit,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Icon(Icons.close_rounded, color: textMuted, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.session.mode == GameMode.training
                          ? op.label.toUpperCase()
                          : 'RANDOM  ·  SURVIVE',
                      style: AppTheme.geist(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      isInf
                          ? '#${_gameState.questionIndex + 1}'
                          : '${_gameState.questionIndex + 1}/${_gameState.totalQuestions}',
                      style: AppTheme.mono(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isInf ? 1.0 : progress,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isInf ? op.color.withOpacity(0.25) : op.color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TimerRing(
            progress: _secondsLeft / _timerDuration,
            secondsLeft: _secondsLeft,
          ),
        ],
      ),
    );
  }

  // ── Stats row — FIXED: each chip wrapped in Expanded for equal width ───
  Widget _buildStatsRow(Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: StatChip(
            label: 'Score',
            value: '${_gameState.score}',
            valueColor: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            label: 'Streak',
            value: '🔥 ${_gameState.streak}',
            valueColor: _gameState.streak >= 3 ? AppTheme.amber : textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            label: 'Best',
            value: '${_gameState.bestStreak}',
            valueColor: textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Question card ──────────────────────────────────────────────
  Widget _buildQuestionCard(
      MathOperation op, Color surface, Color textPrimary) {
    return FadeTransition(
      opacity: _questionFade,
      child: SlideTransition(
        position: _questionSlide,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: op.color.withOpacity(0.22), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: op.color.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OperationBadge(icon: op.icon, color: op.color, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    op.label,
                    style: AppTheme.geist(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: op.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currentQuestion.questionText,
                    style: AppTheme.mono(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hint ───────────────────────────────────────────────────────
  Widget _buildHint(Color textMuted) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline_rounded, color: textMuted, size: 12),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _currentQuestion.hintText,
            style: AppTheme.geist(fontSize: 11, color: textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Quit dialog ────────────────────────────────────────────────
  void _confirmQuit() {
    _timerPaused = true;
    final isDark = themeNotifier.value == ThemeMode.dark;
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        title: Text('Quit Session?',
            style: AppTheme.geist(
                fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
        content: Text('Your current progress will be lost.',
            style: AppTheme.geist(fontSize: 14, color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _timerPaused = false);
            },
            child: Text('Continue',
                style: AppTheme.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Quit',
                style: AppTheme.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.danger)),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _timerPaused) setState(() => _timerPaused = false);
    });
  }
}
