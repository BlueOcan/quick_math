import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/logic_question.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';
import 'home_screen.dart';
import 'logic_game_screen.dart';
import '../services/ad_service.dart';

const _logicColors = {
  LogicCategory.numberSequence: Color(0xFF4A6BF3),
  LogicCategory.missingNumber: Color(0xFF8B5CF6),
  LogicCategory.oddOneOut: Color(0xFFEF4444),
};

class LogicResultScreen extends StatefulWidget {
  final int score;
  final int correct;
  final int total;
  final int bestStreak;
  final LogicCategory category;
  final int difficulty;
  final int totalQuestions;
  final List<bool> history;

  const LogicResultScreen({
    super.key,
    required this.score,
    required this.correct,
    required this.total,
    required this.bestStreak,
    required this.category,
    required this.difficulty,
    required this.totalQuestions,
    required this.history,
  });

  @override
  State<LogicResultScreen> createState() => _LogicResultScreenState();
}

class _LogicResultScreenState extends State<LogicResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _scoreCtrl;
  late Animation<int> _scoreAnim;

  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;

  Color get _color => _logicColors[widget.category]!;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));

    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _scoreAnim = IntTween(begin: 0, end: widget.score)
        .animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 80), () {
      _mainCtrl.forward();
      _scoreCtrl.forward();
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final isDark = themeNotifier.value == ThemeMode.dark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final border = isDark ? AppTheme.border : AppTheme.lightBorder;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
        final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

        final accuracy =
            widget.total == 0 ? 0.0 : widget.correct / widget.total;
        final grade = _getGrade(accuracy);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Shareable area ──────────────────────────
                    Expanded(
                      child: RepaintBoundary(
                        key: _shareKey,
                        child: Container(
                          color: bg,
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Category badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color:
                                                _color.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: _color.withValues(
                                                    alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(widget.category.emoji,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              const SizedBox(width: 5),
                                              Text(
                                                widget.category.label
                                                    .toUpperCase(),
                                                style: AppTheme.mono(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: _color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          grade.title,
                                          style: AppTheme.geist(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          grade.subtitle,
                                          style: AppTheme.geist(
                                              fontSize: 14,
                                              color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(grade.emoji,
                                      style: const TextStyle(fontSize: 52)),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Score card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: _color.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: _color.withValues(alpha: 0.22),
                                      width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'FINAL SCORE',
                                      style: AppTheme.geist(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: textMuted,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    AnimatedBuilder(
                                      animation: _scoreAnim,
                                      builder: (_, __) => Text(
                                        '${_scoreAnim.value}',
                                        style: AppTheme.mono(
                                          fontSize: 68,
                                          fontWeight: FontWeight.w700,
                                          color: _color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Best streak  ×  ${widget.bestStreak}',
                                      style: AppTheme.geist(
                                          fontSize: 13, color: textMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    // Coins badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.amber
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.amber
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFBBF24),
                                                  Color(0xFFF59E0B)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                                Icons.monetization_on_rounded,
                                                color: Colors.white,
                                                size: 12),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '+${widget.correct} coins earned',
                                            style: AppTheme.geist(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: StatChip(
                                      label: 'Correct',
                                      value: '${widget.correct}',
                                      valueColor: AppTheme.success,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatChip(
                                      label: 'Wrong',
                                      value: '${widget.total - widget.correct}',
                                      valueColor: AppTheme.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatChip(
                                      label: 'Accuracy',
                                      value:
                                          '${(accuracy * 100).toStringAsFixed(0)}%',
                                      valueColor: accuracy >= 0.8
                                          ? AppTheme.success
                                          : accuracy >= 0.5
                                              ? AppTheme.amber
                                              : AppTheme.danger,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Answer history label
                              Text(
                                'ANSWER HISTORY',
                                style: AppTheme.geist(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: textMuted,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Answer history grid
                              Expanded(child: _buildHistoryGrid(textMuted)),

                              // Watermark
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: VibeLogo(fontSize: 14, isDark: isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Buttons ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: _buildActions(border, textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryGrid(Color textMuted) {
    if (widget.history.isEmpty) {
      return Center(
        child: Text('No answers recorded.',
            style: AppTheme.geist(color: textMuted)),
      );
    }
    return SingleChildScrollView(
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: widget.history.asMap().entries.map((e) {
          final ok = e.value;
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ok
                  ? AppTheme.success.withValues(alpha: 0.18)
                  : AppTheme.danger.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ok
                    ? AppTheme.success.withValues(alpha: 0.35)
                    : AppTheme.danger.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.close_rounded,
              color: ok ? AppTheme.success : AppTheme.danger,
              size: 14,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(Color border, Color textSecondary) {
    return Column(
      children: [
        // Share button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSharing ? null : _shareResult,
            icon: _isSharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent),
                  )
                : Icon(Icons.share_rounded, size: 18, color: textSecondary),
            label: Text(
              _isSharing ? 'Preparing...' : 'Share Result',
              style: AppTheme.geist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _playAgain,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goHome,
                icon: Icon(Icons.home_rounded, size: 18, color: textSecondary),
                label: Text(
                  'Home',
                  style: AppTheme.geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textSecondary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareResult() async {
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mathvibe_logic_result.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Can you beat my mathVIBE Logic score? 🧠🔥',
        subject: 'My mathVIBE Logic Result',
      );
    } catch (_) {
      final accuracy =
          (widget.total == 0 ? 0.0 : widget.correct / widget.total) * 100;
      Share.share(
        '🧠 mathVIBE Logic · ${widget.category.label}\n'
        'Score: ${widget.score} | Streak: ${widget.bestStreak} | '
        'Accuracy: ${accuracy.toStringAsFixed(0)}%\n'
        'Can you beat me? Download mathVIBE 👇',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _playAgain() async {
    if (!mounted) return;

    if (!AdService.instance.isPro) {
      await AdService.instance.showRewardedAd(context);
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, anim, __) => LogicGameScreen(
        category: widget.category,
        difficulty: widget.difficulty,
        totalQuestions: widget.totalQuestions,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
      (_) => false,
    );
  }

  _Grade _getGrade(double acc) {
    if (acc >= 0.95) {
      return const _Grade('🔥', 'Perfect Run!', 'Absolute fire.');
    }
    if (acc >= 0.80) {
      return const _Grade('⚡', 'Sharp Mind', 'Really solid work.');
    }
    if (acc >= 0.60) {
      return const _Grade('💪', 'Getting There', 'Keep grinding.');
    }
    return const _Grade('🧠', 'Keep Practicing', 'Every rep counts.');
  }
}

class _Grade {
  final String emoji, title, subtitle;
  const _Grade(this.emoji, this.title, this.subtitle);
}
