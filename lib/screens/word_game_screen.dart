import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/word_question.dart';
import '../services/stats_service.dart';
import '../main.dart';
import 'word_result_screen.dart';
import '../services/ad_service.dart';

class WordGameScreen extends StatefulWidget {
  final WordCategory category;
  final int difficulty;
  final int totalQuestions;

  const WordGameScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.totalQuestions,
  });

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen>
    with TickerProviderStateMixin {
  // ── Questions ─────────────────────────────────────────────────
  List<WordQuestion> _questions = [];
  int _qIndex = 0;
  bool _loading = true;

  // ── Score ─────────────────────────────────────────────────────
  int _score = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  final List<bool> _history = []; // ── NEW: tracks each answer

  // ── Answer state ──────────────────────────────────────────────
  String? _selectedOption;
  bool _answered = false;

  // ── Timer ─────────────────────────────────────────────────────
  static const int _timerDuration = 30;
  int _secondsLeft = _timerDuration;
  Timer? _timer;
  bool _timerPaused = false;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // ── Colors ────────────────────────────────────────────────────
  static const _catColors = {
    WordCategory.synonyms: Color(0xFF06B6D4),
    WordCategory.antonyms: Color(0xFF8B5CF6),
    WordCategory.spellCheck: Color(0xFF10B981),
  };

  Color get _color => _catColors[widget.category]!;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _loadQuestions();
    AdService.instance.onAdWillShow = () => setState(() => _timerPaused = true);
    AdService.instance.onAdDidDismiss =
        () => setState(() => _timerPaused = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cardCtrl.dispose();
    AdService.instance.onAdWillShow = null;
    AdService.instance.onAdDidDismiss = null;
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final qs = await WordQuestionBank.getQuestions(
      category: widget.category,
      difficulty: widget.difficulty,
      count: widget.totalQuestions,
    );
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loading = false;
    });
    _startTimer();
    _cardCtrl.forward(from: 0);
  }

  // ── Timer ─────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _timerDuration;
    _timerPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _timerPaused) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _onAnswer(null); // timeout = wrong
      }
    });
  }

  // ── Answer ────────────────────────────────────────────────────
  void _onAnswer(String? chosen) {
    if (_answered) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();

    final q = _questions[_qIndex];
    final correct = chosen == q.correct;

    _history.add(correct); // ── NEW: record result

    setState(() {
      _selectedOption = chosen;
      _answered = true;
      if (correct) {
        _score++;
        _correct++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_qIndex + 1 >= _questions.length) {
        _goToResults();
      } else {
        setState(() {
          _qIndex++;
          _selectedOption = null;
          _answered = false;
        });
        _cardCtrl.forward(from: 0);
        _startTimer();
      }
    });
  }

  void _goToResults() async {
    await StatsService.instance.saveSession(
      score: _score,
      correctAnswers: _correct,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => WordResultScreen(
        score: _score,
        correct: _correct,
        total: _questions.length,
        bestStreak: _bestStreak,
        category: widget.category,
        difficulty: widget.difficulty,
        totalQuestions: widget.totalQuestions,
        history: _history, // ── NEW: pass history
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  // ── Quit ──────────────────────────────────────────────────────
  void _confirmQuit() {
    _timerPaused = true;
    final isDark = themeNotifier.value == ThemeMode.dark;
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final ts = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

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
                fontSize: 17, fontWeight: FontWeight.w700, color: tp)),
        content: Text('Your current progress will be lost.',
            style: AppTheme.geist(fontSize: 14, color: ts)),
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

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final isDark = themeNotifier.value == ThemeMode.dark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
        final border = isDark ? AppTheme.border : AppTheme.lightBorder;
        final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final ts =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
        final tm = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

        if (_loading) {
          return Scaffold(
            backgroundColor: bg,
            body: Center(child: CircularProgressIndicator(color: _color)),
          );
        }

        if (_questions.isEmpty) {
          return Scaffold(
            backgroundColor: bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: tm, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No questions available yet.\nFill the JSON data file.',
                    textAlign: TextAlign.center,
                    style: AppTheme.geist(fontSize: 14, color: ts),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back',
                        style: AppTheme.geist(
                            color: _color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }

        final q = _questions[_qIndex];
        final progress = (_qIndex / _questions.length).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(children: [
              // ── Top bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(children: [
                  GestureDetector(
                    onTap: _confirmQuit,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Icon(Icons.close_rounded, color: ts, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.category.label.toUpperCase(),
                            style: AppTheme.geist(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: tm,
                                letterSpacing: 2),
                          ),
                          Text('${_qIndex + 1}/${_questions.length}',
                              style: AppTheme.mono(fontSize: 9, color: tm)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: border,
                          valueColor: AlwaysStoppedAnimation<Color>(_color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 16),
                  _TimerRing(
                    progress: _secondsLeft / _timerDuration,
                    secondsLeft: _secondsLeft,
                    color: _color,
                  ),
                ]),
              ),

              // ── Stats row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _StatPill(
                      label: 'SCORE',
                      value: '$_score',
                      color: _color,
                      isDark: isDark),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: 'STREAK',
                      value: '🔥 $_streak',
                      color: _streak >= 3 ? AppTheme.amber : tp,
                      isDark: isDark),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: 'BEST',
                      value: '$_bestStreak',
                      color: ts,
                      isDark: isDark),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Question card ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: _color.withValues(alpha: 0.22), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: _color.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.category.label.toUpperCase(),
                            style: AppTheme.geist(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _color,
                                letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          q.question,
                          textAlign: TextAlign.center,
                          style: AppTheme.geist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: tp,
                              height: 1.3),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Options ────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: q.options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OptionButton(
                            label: opt,
                            index: idx,
                            correct: q.correct,
                            selected: _selectedOption,
                            answered: _answered,
                            color: _color,
                            isDark: isDark,
                            onTap: () => _onAnswer(opt),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ]),
          ),
        );
      },
    );
  }
}

// ── Option Button ─────────────────────────────────────────────────────────────
class _OptionButton extends StatelessWidget {
  final String label;
  final int index;
  final String correct;
  final String? selected;
  final bool answered;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.index,
    required this.correct,
    required this.selected,
    required this.answered,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    Color bgColor = surface;
    Color bdColor = border;
    Color textColor = tp;
    Color letterBg = color.withValues(alpha: 0.1);
    Color letterColor = color;
    IconData? trailingIcon;

    if (answered) {
      if (label == correct) {
        bgColor = AppTheme.success.withValues(alpha: 0.15);
        bdColor = AppTheme.success;
        textColor = AppTheme.success;
        letterBg = AppTheme.success.withValues(alpha: 0.2);
        letterColor = AppTheme.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (label == selected) {
        bgColor = AppTheme.danger.withValues(alpha: 0.15);
        bdColor = AppTheme.danger;
        textColor = AppTheme.danger;
        letterBg = AppTheme.danger.withValues(alpha: 0.2);
        letterColor = AppTheme.danger;
        trailingIcon = Icons.cancel_rounded;
      }
    }

    final letter = index < _letters.length ? _letters[index] : '•';

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                  child: Text(letter,
                      style: AppTheme.mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: letterColor))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTheme.geist(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 22),
          ]),
        ),
      ),
    );
  }
}

// ── Timer ring ────────────────────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final double progress;
  final int secondsLeft;
  final Color color;

  const _TimerRing(
      {required this.progress, required this.secondsLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    final ringColor = progress > 0.5
        ? color
        : progress > 0.25
            ? AppTheme.amber
            : AppTheme.danger;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text('$secondsLeft',
            style: AppTheme.mono(
                fontSize: 15, fontWeight: FontWeight.w700, color: ringColor)),
      ]),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;

  const _StatPill(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final tm = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTheme.geist(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: tm,
                letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTheme.mono(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]),
    ));
  }
}
