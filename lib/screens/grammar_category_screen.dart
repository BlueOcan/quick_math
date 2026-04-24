import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/word_question.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';
import 'word_game_screen.dart';

// ── Grammar Category Screen ───────────────────────────────────────────────────
class GrammarCategoryScreen extends StatelessWidget {
  const GrammarCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final isDark = themeNotifier.value == ThemeMode.dark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final ts =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
        final tm = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: tp),
              onPressed: () => Navigator.pop(context),
            ),
            title: VibeLogo(fontSize: 20, isDark: isDark),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('GRAMMAR',
                      style: AppTheme.geist(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tm,
                          letterSpacing: 2)),
                ),
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
                          color: tp)),
                  const SizedBox(height: 4),
                  Text('Tap a category to set difficulty & questions.',
                      style: AppTheme.geist(fontSize: 13, color: ts)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: WordCategory.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final cat = WordCategory.values[i];
                        return _WordCategoryCard(
                          category: cat,
                          isDark: isDark,
                          onTap: () => _showSheet(ctx, cat, isDark),
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

  void _showSheet(BuildContext ctx, WordCategory cat, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordSessionSheet(category: cat, isDark: isDark),
    );
  }
}

// ── Word Category Card ────────────────────────────────────────────────────────
class _WordCategoryCard extends StatefulWidget {
  final WordCategory category;
  final bool isDark;
  final VoidCallback onTap;

  const _WordCategoryCard(
      {required this.category, required this.isDark, required this.onTap});

  @override
  State<_WordCategoryCard> createState() => _WordCategoryCardState();
}

class _WordCategoryCardState extends State<_WordCategoryCard> {
  bool _pressed = false;

  static const _colors = {
    WordCategory.synonyms: Color(0xFF06B6D4),
    WordCategory.antonyms: Color(0xFF8B5CF6),
    WordCategory.spellCheck: Color(0xFF10B981),
  };

  static const _icons = {
    WordCategory.synonyms: Icons.compare_arrows_rounded,
    WordCategory.antonyms: Icons.swap_horiz_rounded,
    WordCategory.spellCheck: Icons.spellcheck_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final color = _colors[cat]!;
    final icon = _icons[cat]!;
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
              color: _pressed ? color.withValues(alpha: 0.4) : border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cat.label,
                  style: AppTheme.geist(
                      fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
              const SizedBox(height: 2),
              Text(cat.description,
                  style: AppTheme.geist(fontSize: 12, color: ts)),
            ],
          )),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 18),
          ),
        ]),
      ),
    );
  }
}

// ── Word Session Bottom Sheet ─────────────────────────────────────────────────
class _WordSessionSheet extends StatefulWidget {
  final WordCategory category;
  final bool isDark;

  const _WordSessionSheet({required this.category, required this.isDark});

  @override
  State<_WordSessionSheet> createState() => _WordSessionSheetState();
}

class _WordSessionSheetState extends State<_WordSessionSheet> {
  int _diff = 0; // 0=Easy 1=Medium 2=Hard
  int _qIdx = 0; // index into _qOpts
  final _qOpts = [10, 20, 30, 50];

  bool get _isDark => widget.isDark;
  Color get _bg => _isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color get _hi => _isDark ? AppTheme.surfaceHigh : AppTheme.lightSurfaceHigh;
  Color get _bd => _isDark ? AppTheme.border : AppTheme.lightBorder;
  Color get _tp => _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get _tm => _isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

  static const _catColors = {
    WordCategory.synonyms: Color(0xFF06B6D4),
    WordCategory.antonyms: Color(0xFF8B5CF6),
    WordCategory.spellCheck: Color(0xFF10B981),
  };

  static const _catIcons = {
    WordCategory.synonyms: Icons.compare_arrows_rounded,
    WordCategory.antonyms: Icons.swap_horiz_rounded,
    WordCategory.spellCheck: Icons.spellcheck_rounded,
  };

  static const _diffs = [
    (
      'Easy',
      'Common words',
      Icons.sentiment_satisfied_rounded,
      AppTheme.success
    ),
    ('Medium', 'Intermediate', Icons.sentiment_neutral_rounded, AppTheme.amber),
    (
      'Hard',
      'Advanced words',
      Icons.sentiment_very_dissatisfied_rounded,
      AppTheme.danger
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final color = _catColors[cat]!;
    final icon = _catIcons[cat]!;

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

          // Header
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.label,
                    style: AppTheme.geist(
                        fontSize: 20, fontWeight: FontWeight.w800, color: _tp)),
                Text(cat.description,
                    style: AppTheme.geist(fontSize: 12, color: _ts)),
              ],
            )),
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
            return Padding(
              padding: EdgeInsets.only(right: i < _qOpts.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _qIdx = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 60,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel ? color : _hi,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? color : _bd),
                  ),
                  child: Center(
                      child: Text('${_qOpts[i]}',
                          style: AppTheme.mono(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : _ts))),
                ),
              ),
            );
          })),

          const SizedBox(height: 28),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('Start ${cat.label}',
                  style: AppTheme.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
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

  void _startSession() {
    Navigator.pop(context);
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => WordGameScreen(
        category: widget.category,
        difficulty: _diff,
        totalQuestions: _qOpts[_qIdx],
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }
}
