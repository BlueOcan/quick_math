import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/ad_service.dart';
import 'pro_paywall.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _notificationsEnabled = true;

  bool get _isDark => themeNotifier.value == ThemeMode.dark;

  // ── Theme-aware helpers ───────────────────────────────────────
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
                // ── Header ──────────────────────────────────────
                _buildHeader(),

                // ── Content ─────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pro section
                        if (!AdService.instance.isPro) ...[
                          _sectionLabel('UPGRADE'),
                          const SizedBox(height: 10),
                          _buildProBanner(),
                          const SizedBox(height: 24),
                        ],

                        // Appearance section
                        _sectionLabel('APPEARANCE'),
                        const SizedBox(height: 10),
                        _buildThemeToggle(),

                        const SizedBox(height: 24),

                        // App section
                        _sectionLabel('APP'),
                        const SizedBox(height: 10),
                        _buildTileGroup([
                          _DrawerTileData(
                            icon: Icons.notifications_rounded,
                            iconColor: AppTheme.accent,
                            label: 'Notifications',
                            trailing: _buildSwitch(_notificationsEnabled, (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _notificationsEnabled = v);
                            }),
                          ),
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

                        // Legal section
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

                // ── Footer ──────────────────────────────────────
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────
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
          // Logo mark
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
                  color: AppTheme.accent.withOpacity(0.35),
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

  // ── Section Label ─────────────────────────────────────────────
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

  // ── Theme Toggle ──────────────────────────────────────────────
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
            // Icon with gradient bg
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
            // Animated pill toggle
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
                            color: Colors.black.withOpacity(0.2),
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

  // ── Tile Group ────────────────────────────────────────────────
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
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _border,
                  indent: 58,
                ),
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
        splashColor: AppTheme.accent.withOpacity(0.06),
        highlightColor: AppTheme.accent.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tile.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tile.iconColor.withOpacity(0.2)),
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
              tile.trailing ??
                  (tile.onTap != null
                      ? Icon(Icons.chevron_right_rounded,
                          color: _textMuted, size: 18)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Switch ────────────────────────────────────────────────────
  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
        activeTrackColor: AppTheme.accent.withOpacity(0.3),
        inactiveThumbColor: _textMuted,
        inactiveTrackColor: _surfaceHigh,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ── Pro Banner ────────────────────────────────────────────────
  Widget _buildProBanner() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        ProPaywall.show(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withOpacity(0.15),
              const Color(0xFF7B5CF6).withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF7B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: AppTheme.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    'No ads · Zen Mode · \$2.99 once',
                    style: AppTheme.geist(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.accent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 1)),
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
          Text(
            '❤️',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────
  void _shareApp() {
    Navigator.pop(context);
    // TODO: integrate share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share coming soon!',
          style: AppTheme.geist(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _rateApp() {
    Navigator.pop(context);
    // TODO: integrate in_app_review package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rating coming soon!',
          style: AppTheme.geist(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openUrl(String page) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${page == 'privacy' ? 'Privacy Policy' : 'Terms of Service'} coming soon!',
          style: AppTheme.geist(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Data model for tiles ──────────────────────────────────────────────────────
class _DrawerTileData {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DrawerTileData({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
    this.trailing,
  });
}
