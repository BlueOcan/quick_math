import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';
import '../models/game_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/app_drawer.dart';
import '../services/stats_service.dart';
import '../main.dart';
import 'game_screen.dart';
import 'training_screen.dart';
import 'grammar_category_screen.dart';
import '../models/logic_question.dart';
import 'logic_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      // Replace with your real Banner Ad Unit ID from AdMob dashboard
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ← swap for real
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  bool get _isDark => themeNotifier.value == ThemeMode.dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        final isDark = _isDark;
        final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
        final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
        final border = isDark ? AppTheme.border : AppTheme.lightBorder;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bg,
          drawer: const AppDrawer(),

          // ── Sticky bottom banner ad ──────────────────────────────
          bottomNavigationBar: _bannerLoaded && _bannerAd != null
              ? SafeArea(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : const SizedBox.shrink(),

          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── FIXED HEADER ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: border),
                              ),
                              child: Icon(Icons.menu_rounded,
                                  color: textSecondary, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          VibeLogo(fontSize: 26, isDark: isDark),
                          const SizedBox(width: 10),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: _GamePill(
                                icon: Icons.emoji_events_rounded,
                                iconGradient: const [
                                  Color(0xFF4A6BF3),
                                  Color(0xFF7B5CF6),
                                ],
                                value:
                                    _formatNum(StatsService.instance.highScore),
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: _GamePill(
                                icon: Icons.monetization_on_rounded,
                                iconGradient: const [
                                  Color(0xFFFBBF24),
                                  Color(0xFFF59E0B),
                                ],
                                value: _formatNum(StatsService.instance.coins),
                                isDark: isDark,
                                isGold: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── SCROLLABLE CONTENT ────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),

                            // ── Arithmetic label ───────────────────────
                            Text(
                              'Arithmetic',
                              style: AppTheme.geist(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.textPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Row: Random + Training ─────────────────
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _PrimaryCard(
                                      icon: Icons.all_inclusive_rounded,
                                      title: 'Random',
                                      subtitle: 'All operations mixed',
                                      color: AppTheme.danger,
                                      isDark: isDark,
                                      onTap: _startRandom,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PrimaryCard(
                                      icon: Icons.track_changes_rounded,
                                      title: 'Training',
                                      subtitle: 'Pick a category',
                                      color: AppTheme.amber,
                                      isDark: isDark,
                                      onTap: _openTraining,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Grammar label ──────────────────────────
                            Text(
                              'Grammar',
                              style: AppTheme.geist(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.textPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Grammar card ───────────────────────────
                            _PrimaryCard(
                              icon: Icons.menu_book_rounded,
                              title: 'Grammar',
                              subtitle: 'Synonyms · Antonyms · Spell Check',
                              color: const Color(0xFF06B6D4),
                              isDark: isDark,
                              onTap: _openGrammar,
                              fullWidth: true,
                            ),

                            const SizedBox(height: 16),

                            // ── Logic label ────────────────────────────
                            Text(
                              'Logic',
                              style: AppTheme.geist(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.textPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Logic cards ────────────────────────────
                            Column(
                              children: LogicCategory.values.map((cat) {
                                final color = {
                                  LogicCategory.numberSequence:
                                      const Color(0xFF4A6BF3),
                                  LogicCategory.missingNumber:
                                      const Color(0xFF8B5CF6),
                                  LogicCategory.oddOneOut:
                                      const Color.fromARGB(255, 239, 136, 68),
                                }[cat]!;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LogicCategoryCard(
                                    category: cat,
                                    color: color,
                                    isDark: isDark,
                                    onTap: () => _openLogic(cat),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
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

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _startRandom() {
    Navigator.of(context)
        .push(_route(
          const GameScreen(
            session: GameSession(
              mode: GameMode.random,
              totalQuestions: kInfiniteQuestions,
            ),
          ),
        ))
        .then((_) => setState(() {}));
  }

  void _openTraining() {
    Navigator.of(context)
        .push(_route(const TrainingScreen()))
        .then((_) => setState(() {}));
  }

  void _openGrammar() {
    Navigator.of(context)
        .push(_route(const GrammarCategoryScreen()))
        .then((_) => setState(() {}));
  }

  void _openLogic(LogicCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogicSessionSheet(
        category: category,
        isDark: _isDark,
      ),
    );
  }

  PageRoute _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ── Game-style stat pill ──────────────────────────────────────────────────────
class _GamePill extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String value;
  final bool isDark;
  final bool isGold;

  const _GamePill({
    required this.icon,
    required this.iconGradient,
    required this.value,
    required this.isDark,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    const double h = 34;
    const double iconSize = h;
    const double iconInner = 16;
    const double fontSize = 15;
    const double radius = h / 2;

    final pillBg = isGold
        ? (isDark ? const Color(0xFF2A1F00) : const Color(0xFFFFF8E6))
        : (isDark ? const Color(0xFF0F1A3A) : const Color(0xFFEEF2FF));
    final pillBorder = isGold
        ? (isDark ? const Color(0xFF6B4A00) : const Color(0xFFFBBF24))
        : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF93C5FD));
    final textColor = isGold
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
        : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8));

    return Container(
      height: h,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: pillBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: iconInner),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTheme.mono(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary Card ──────────────────────────────────────────────────────────────
class _PrimaryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool fullWidth;

  const _PrimaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<_PrimaryCard> createState() => _PrimaryCardState();
}

class _PrimaryCardState extends State<_PrimaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: widget.isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.22), width: 1.5),
          ),
          child: widget.fullWidth
              // ── Full-width horizontal layout ──
              ? Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTheme.geist(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? AppTheme.textPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: AppTheme.geist(
                              fontSize: 11,
                              color: widget.isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: widget.color, size: 14),
                  ],
                )
              // ── Half-width vertical layout ──
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 20),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      style: AppTheme.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppTheme.textPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTheme.geist(
                        fontSize: 11,
                        color: widget.isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Logic Category Card ───────────────────────────────────────────────────────
class _LogicCategoryCard extends StatelessWidget {
  final LogicCategory category;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _LogicCategoryCard({
    required this.category,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = {
      LogicCategory.numberSequence: 'Number Sequence',
      LogicCategory.missingNumber: 'Missing Number',
      LogicCategory.oddOneOut: 'Odd One Out',
    }[category]!;

    final subtitle = {
      LogicCategory.numberSequence: 'Find the pattern',
      LogicCategory.missingNumber: 'Fill the blank',
      LogicCategory.oddOneOut: 'Spot the odd one',
    }[category]!;

    final icon = {
      LogicCategory.numberSequence: Icons.format_list_numbered,
      LogicCategory.missingNumber: Icons.help_outline,
      LogicCategory.oddOneOut: Icons.psychology,
    }[category]!;

    final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final ts = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.geist(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tp)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTheme.geist(fontSize: 11, color: ts)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Logic Session Bottom Sheet ────────────────────────────────────────────────
class _LogicSessionSheet extends StatefulWidget {
  final LogicCategory category;
  final bool isDark;

  const _LogicSessionSheet({
    required this.category,
    required this.isDark,
  });

  @override
  State<_LogicSessionSheet> createState() => _LogicSessionSheetState();
}

class _LogicSessionSheetState extends State<_LogicSessionSheet> {
  int _diff = 0;
  int _qIdx = 1; // default 20

  final _qOpts = const [10, 20, 30, 50];

  bool get _isDark => widget.isDark;
  Color get _bg => _isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color get _hi => _isDark ? AppTheme.surfaceHigh : AppTheme.lightSurfaceHigh;
  Color get _bd => _isDark ? AppTheme.border : AppTheme.lightBorder;
  Color get _tp => _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get _tm => _isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

  static const _diffs = [
    (
      'Easy',
      'Beginner level',
      Icons.sentiment_satisfied_rounded,
      AppTheme.success
    ),
    ('Medium', 'Intermediate', Icons.sentiment_neutral_rounded, AppTheme.amber),
    (
      'Hard',
      'Expert level',
      Icons.sentiment_very_dissatisfied_rounded,
      AppTheme.danger
    ),
  ];

  static const _catIcons = {
    LogicCategory.numberSequence: Icons.format_list_numbered,
    LogicCategory.missingNumber: Icons.help_outline,
    LogicCategory.oddOneOut: Icons.psychology,
  };

  static const _catColors = {
    LogicCategory.numberSequence: Color(0xFF4A6BF3),
    LogicCategory.missingNumber: Color(0xFF8B5CF6),
    LogicCategory.oddOneOut: Color(0xFFEF4444),
  };

  static const _catTitles = {
    LogicCategory.numberSequence: 'Number Sequence',
    LogicCategory.missingNumber: 'Missing Number',
    LogicCategory.oddOneOut: 'Odd One Out',
  };

  static const _catDescs = {
    LogicCategory.numberSequence: 'Find the pattern in the sequence',
    LogicCategory.missingNumber: 'Fill in the missing blank',
    LogicCategory.oddOneOut: 'Spot the one that does not belong',
  };

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final color = _catColors[cat]!;

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
                  color: _bd, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_catIcons[cat]!, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_catTitles[cat]!,
                      style: AppTheme.geist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _tp)),
                  Text(_catDescs[cat]!,
                      style: AppTheme.geist(fontSize: 12, color: _ts)),
                ],
              ),
            ),
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
                        Text(d.$2,
                            style: AppTheme.geist(fontSize: 10, color: _tm)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ),
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
                    width: 52,
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
                              color: sel ? Colors.white : _ts)),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (_, anim, __) => LogicGameScreen(
                    category: cat,
                    difficulty: _diff,
                    totalQuestions: _qOpts[_qIdx],
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 280),
                ));
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('Start ${_catTitles[cat]!}',
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
}
