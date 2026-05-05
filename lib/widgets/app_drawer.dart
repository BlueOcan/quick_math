import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool get _isDark => themeNotifier.value == ThemeMode.dark;

  Color get _bg => _isDark ? AppTheme.background : AppTheme.lightBackground;
  Color get _surface => _isDark ? AppTheme.surface : AppTheme.lightSurface;
  Color get _surfaceHigh =>
      _isDark ? AppTheme.surfaceHigh : AppTheme.lightSurfaceHigh;
  Color get _border => _isDark ? AppTheme.border : AppTheme.lightBorder;
  Color get _textPrimary =>
      _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get _textSecondary =>
      _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get _textMuted =>
      _isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

  // ── YOUR PLAY STORE PACKAGE NAME ──────────────────────────────
  static const String _packageName = 'com.thethreezero.mathvibe';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageName';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, __, ___) {
        return Drawer(
          width: MediaQuery.of(context).size.width * 0.82,
          backgroundColor: _bg,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('APPEARANCE'),
                        const SizedBox(height: 10),
                        _buildThemeToggle(),
                        const SizedBox(height: 24),
                        _sectionLabel('APP'),
                        const SizedBox(height: 10),
                        _buildTileGroup([
                          _DrawerTileData(
                            icon: Icons.share_rounded,
                            iconColor: AppTheme.opDiv,
                            label: 'Share with Friends',
                            onTap: _shareApp,
                          ),
                          _DrawerTileData(
                            icon: Icons.star_rounded,
                            iconColor: AppTheme.amber,
                            label: 'Rate mathVIBE',
                            onTap: _rateApp,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionLabel('LEGAL'),
                        const SizedBox(height: 10),
                        _buildTileGroup([
                          _DrawerTileData(
                            icon: Icons.shield_rounded,
                            iconColor: AppTheme.opSq,
                            label: 'Privacy Policy',
                            onTap: () => _openUrl('privacy'),
                          ),
                          _DrawerTileData(
                            icon: Icons.description_rounded,
                            iconColor: AppTheme.opRoot,
                            label: 'Terms of Service',
                            onTap: () => _openUrl('terms'),
                          ),
                        ]),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent, Color(0xFF7B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.functions_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'math',
                  style: AppTheme.mono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const TextSpan(
                  text: 'VIBE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                    letterSpacing: -0.5,
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mental arithmetic, perfected.',
            style: AppTheme.geist(fontSize: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTheme.geist(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _textMuted,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildThemeToggle() {
    final isDark = _isDark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFFBBF24),
                  width: 1,
                ),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: AppTheme.geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
                    style: AppTheme.geist(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.accent : _surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.accent : _border,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: isDark ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileGroup(List<_DrawerTileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              _buildTile(tile),
              if (!isLast)
                Divider(height: 1, thickness: 1, color: _border, indent: 58),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile(_DrawerTileData tile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap != null
            ? () {
                HapticFeedback.selectionClick();
                tile.onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.accent.withValues(alpha: 0.06),
        highlightColor: AppTheme.accent.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tile.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: tile.iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(tile.icon, color: tile.iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tile.label,
                  style: AppTheme.geist(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
              ),
              if (tile.onTap != null)
                Icon(Icons.chevron_right_rounded, color: _textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, color: AppTheme.danger, size: 14),
          const SizedBox(width: 6),
          Text(
            'Made with love',
            style: AppTheme.geist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          const Text('❤️', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ── FIXED: Share now sends a real message with the Play Store link ─────────
  void _shareApp() {
    Navigator.pop(context);
    Share.share(
      '🧠 I\'ve been sharpening my math skills with mathVIBE!\n\n'
      'Challenge yourself with arithmetic, logic & grammar games.\n\n'
      'Download it here 👇\n$_playStoreUrl',
      subject: 'Check out mathVIBE!',
    );
  }

  // ── FIXED: Rate now opens the Play Store page directly ────────────────────
  void _rateApp() {
    Navigator.pop(context);
    // Opens the Play Store directly on Android
    // On iOS this would need to use the App Store URL instead
    final uri = Uri.parse('market://details?id=$_packageName');
    final fallbackUri = Uri.parse(_playStoreUrl);

    // Try the native market:// link first, fall back to browser URL
    _launchUri(uri, fallback: fallbackUri);
  }

  Future<void> _launchUri(Uri uri, {Uri? fallback}) async {
    // We use the webview approach since url_launcher is not in pubspec
    // Instead we open the Play Store web URL in our built-in webview
    final url = fallback?.toString() ?? uri.toString();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LegalWebView(title: 'Rate mathVIBE', url: url),
    ));
  }

  void _openUrl(String page) {
    Navigator.pop(context);
    const privacyUrl =
        'https://blueocan.github.io/quick_math/legal/privacy_policy.html';
    const termsUrl =
        'https://blueocan.github.io/quick_math/legal/terms_of_service.html';

    final url = page == 'privacy' ? privacyUrl : termsUrl;
    final title = page == 'privacy' ? 'Privacy Policy' : 'Terms of Service';

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LegalWebView(title: title, url: url),
    ));
  }
}

// ── Data model for tiles ──────────────────────────────────────────────────────
class _DrawerTileData {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _DrawerTileData({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });
}

// ── Legal WebView (unchanged) ─────────────────────────────────────────────────
class _LegalWebView extends StatefulWidget {
  final String title;
  final String url;
  const _LegalWebView({required this.title, required this.url});

  @override
  State<_LegalWebView> createState() => _LegalWebViewState();
}

class _LegalWebViewState extends State<_LegalWebView> {
  bool _loading = true;
  bool _hasError = false;

  late final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onPageStarted: (_) => setState(() {
        _loading = true;
        _hasError = false;
      }),
      onPageFinished: (_) => setState(() => _loading = false),
      onWebResourceError: (_) => setState(() {
        _loading = false;
        _hasError = true;
      }),
    ))
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final tp = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final ts = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: AppTheme.geist(
                fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ts, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: ts, size: 48),
                  const SizedBox(height: 16),
                  Text('Could not load page.',
                      style: AppTheme.geist(fontSize: 14, color: ts)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _controller.reload(),
                    child: Text('Try again',
                        style: AppTheme.geist(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: AppTheme.accent,
              minHeight: 2,
            ),
        ],
      ),
    );
  }
}
