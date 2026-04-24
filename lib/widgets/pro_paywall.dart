import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/ad_service.dart';

/// Call this from anywhere:
/// ProPaywall.show(context);
class ProPaywall {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProPaywallSheet(),
    );
  }
}

class _ProPaywallSheet extends StatefulWidget {
  const _ProPaywallSheet();

  @override
  State<_ProPaywallSheet> createState() => _ProPaywallSheetState();
}

class _ProPaywallSheetState extends State<_ProPaywallSheet> {
  bool _loading = false;

  bool get _isDark => themeNotifier.value == ThemeMode.dark;
  Color get _bg => _isDark ? AppTheme.surface : AppTheme.lightSurface;
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
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: _border),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFF7B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),

              Text(
                'mathVIBE Pro',
                style: AppTheme.geist(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'One-time purchase. Yours forever.',
                style: AppTheme.geist(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 24),

              // Feature list
              _buildFeature(Icons.block_rounded, AppTheme.danger,
                  'No Ads — Ever', 'Clean, distraction-free sessions'),
              const SizedBox(height: 12),
              _buildFeature(Icons.timer_off_rounded, AppTheme.opSq, 'Zen Mode',
                  'Practice without the timer pressure'),
              const SizedBox(height: 12),
              _buildFeature(
                  Icons.favorite_rounded,
                  AppTheme.opSub,
                  'Support Development',
                  'Help keep mathVIBE free for everyone'),
              const SizedBox(height: 28),

              // Price tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\$2.99',
                      style: AppTheme.mono(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'one-time',
                      style: AppTheme.geist(fontSize: 13, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buy button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _buyPro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Unlock Pro — \$2.99',
                          style: AppTheme.geist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Restore
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  'Restore Purchase',
                  style: AppTheme.geist(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeature(
      IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.geist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.geist(fontSize: 11, color: _textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _buyPro() async {
    setState(() => _loading = true);
    await AdService.instance.buyPro();
    if (mounted) setState(() => _loading = false);
    if (AdService.instance.isPro && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    await AdService.instance.restorePurchases();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
    if (AdService.instance.isPro && mounted) {
      Navigator.pop(context);
    }
  }
}
