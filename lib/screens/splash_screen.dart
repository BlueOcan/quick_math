import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo scale + fade ──────────────────────────────────────────
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  // ── Text fade in ───────────────────────────────────────────────
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // ── Tagline fade ───────────────────────────────────────────────
  late AnimationController _tagCtrl;
  late Animation<double> _tagFade;

  // ── Exit slide up ──────────────────────────────────────────────
  late AnimationController _exitCtrl;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Force light status bar on splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Logo: scale from 0.6 → 1.0 + fade in
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    // Text: slide up + fade in, starts 300ms after logo
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Tagline: fade in, starts 500ms after logo
    _tagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _tagFade = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut);

    // Exit: fade out the whole splash
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1 — Logo pop in
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    // 2 — Text slides up
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();

    // 3 — Tagline fades in
    await Future.delayed(const Duration(milliseconds: 200));
    _tagCtrl.forward();

    // 4 — Hold
    await Future.delayed(const Duration(milliseconds: 900));

    // 5 — Fade out and navigate
    await _exitCtrl.forward();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash is always light background regardless of theme
    const bg = AppTheme.lightBackground;
    const tp = AppTheme.lightTextPrimary;
    const ts = AppTheme.lightTextSecondary;

    return AnimatedBuilder(
      animation: _exitFade,
      builder: (_, child) => Opacity(opacity: _exitFade.value, child: child),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Logo mark ─────────────────────────────────
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF7B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit
                              .cover, // or BoxFit.contain if logo gets cut
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── mathVIBE wordmark ──────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'math',
                            style: AppTheme.mono(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: tp,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'VIBE',
                            style: AppTheme.mono(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Tagline ────────────────────────────────────
                FadeTransition(
                  opacity: _tagFade,
                  child: Text(
                    'Mental arithmetic, perfected.',
                    style: AppTheme.geist(
                      fontSize: 14,
                      color: ts,
                    ),
                  ),
                ),

                const Spacer(flex: 2),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
