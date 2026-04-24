import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/math_operation.dart';
import '../models/game_state.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';
import 'game_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final isDark = themeNotifier.value == ThemeMode.dark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
        final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: VibeLogo(fontSize: 20, isDark: isDark),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                    child: Text('TRAINING',
                        style: AppTheme.geist(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 2))),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('Select Category',
                      style: AppTheme.geist(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Tap a category to set difficulty & questions.',
                      style:
                          AppTheme.geist(fontSize: 13, color: textSecondary)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: MathOperation.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final op = MathOperation.values[i];
                        return _TrainingCard(
                          operation: op,
                          isDark: isDark,
                          onTap: () => _showSheet(context, op, isDark),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSheet(BuildContext ctx, MathOperation op, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionSheet(operation: op, isDark: isDark),
    );
  }
}

// ── Session Bottom Sheet ──────────────────────────────────────────────────────
class _SessionSheet extends StatefulWidget {
  final MathOperation operation;
  final bool isDark;
  const _SessionSheet({required this.operation, required this.isDark});
  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  int _diff = 0; // 0=Easy 1=Medium 2=Hard
  int _qIdx = 0; // index into _qOpts, default 10
  final _qOpts = [10, 20, 30, 50, kInfiniteQuestions];

  bool get _isDark => widget.isDark;
  Color get _bg => _isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color get _hi => _isDark ? AppTheme.surfaceHigh : AppTheme.lightSurfaceHigh;
  Color get _bd => _isDark ? AppTheme.border : AppTheme.lightBorder;
  Color get _tp => _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get _tm => _isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

  static const _diffs = [
    ('Easy', '1-digit', Icons.sentiment_satisfied_rounded, AppTheme.success),
    ('Medium', '2-digit', Icons.sentiment_neutral_rounded, AppTheme.amber),
    (
      'Hard',
      '3-digit',
      Icons.sentiment_very_dissatisfied_rounded,
      AppTheme.danger
    ),
  ];

  String _ql(int q) => q == kInfiniteQuestions ? '∞' : '$q';

  @override
  Widget build(BuildContext context) {
    final op = widget.operation;
    final isInf = _qOpts[_qIdx] == kInfiniteQuestions;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: _bd),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _bd, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Op header
          Row(children: [
            OperationBadge(icon: op.icon, color: op.color, size: 44),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(op.label,
                      style: AppTheme.geist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _tp)),
                  Text(op.description,
                      style: AppTheme.geist(fontSize: 12, color: _ts)),
                ])),
          ]),
          const SizedBox(height: 24),

          // Difficulty
          Text('DIFFICULTY',
              style: AppTheme.geist(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _tm,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
              children: List.generate(3, (i) {
            final d = _diffs[i];
            final sel = _diff == i;
            return Expanded(
                child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _diff = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? d.$4.withValues(alpha: 0.12) : _hi,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: sel ? d.$4 : _bd, width: sel ? 1.5 : 1),
                  ),
                  child: Column(children: [
                    Icon(d.$3, color: sel ? d.$4 : _tm, size: 22),
                    const SizedBox(height: 6),
                    Text(d.$1,
                        style: AppTheme.geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? d.$4 : _tp)),
                    Text(d.$2, style: AppTheme.geist(fontSize: 10, color: _tm)),
                  ]),
                ),
              ),
            ));
          })),
          const SizedBox(height: 24),

          // Questions
          Text('QUESTIONS',
              style: AppTheme.geist(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _tm,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
              children: List.generate(_qOpts.length, (i) {
            final sel = _qIdx == i;
            final inf = _qOpts[i] == kInfiniteQuestions;
            return Padding(
              padding: EdgeInsets.only(right: i < _qOpts.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _qIdx = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel ? (inf ? AppTheme.amber : op.color) : _hi,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? (inf ? AppTheme.amber : op.color) : _bd),
                  ),
                  child: Center(
                      child: Text(_ql(_qOpts[i]),
                          style: AppTheme.mono(
                              fontSize: inf ? 20 : 15,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : _ts))),
                ),
              ),
            );
          })),

          if (isInf) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.amber, size: 13),
              const SizedBox(width: 5),
              Text('1 wrong answer ends the session',
                  style: AppTheme.geist(fontSize: 11, color: AppTheme.amber)),
            ]),
          ],
          const SizedBox(height: 28),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (_, anim, __) => GameScreen(
                    session: GameSession(
                      mode: GameMode.training,
                      trainingOp: op,
                      totalQuestions: _qOpts[_qIdx],
                      difficulty: _diff,
                    ),
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 280),
                ));
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('Start ${op.label}',
                  style: AppTheme.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: op.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Training Card ─────────────────────────────────────────────────────────────
class _TrainingCard extends StatefulWidget {
  final MathOperation operation;
  final bool isDark;
  final VoidCallback onTap;
  const _TrainingCard(
      {required this.operation, required this.isDark, required this.onTap});
  @override
  State<_TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<_TrainingCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final op = widget.operation;
    final surface = widget.isDark ? AppTheme.surface : AppTheme.lightSurface;
    final surfHi =
        widget.isDark ? AppTheme.surfaceHigh : AppTheme.lightSurfaceHigh;
    final border = widget.isDark ? AppTheme.border : AppTheme.lightBorder;
    final tp = widget.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final ts =
        widget.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pressed ? surfHi : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _pressed ? op.color.withValues(alpha: 0.4) : border),
        ),
        child: Row(children: [
          OperationBadge(icon: op.icon, color: op.color, size: 44),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(op.label,
                    style: AppTheme.geist(
                        fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
                const SizedBox(height: 2),
                Text(op.description,
                    style: AppTheme.geist(fontSize: 12, color: ts)),
              ])),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: op.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_arrow_rounded, color: op.color, size: 18),
          ),
        ]),
      ),
    );
  }
}
