import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';

// ── Tactile Keypad Button ─────────────────────────────────────────────────────
class KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? bgColor;
  final IconData? icon;
  final bool isDark;

  const KeypadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.textColor,
    this.bgColor,
    this.icon,
    this.isDark = true,
  });

  @override
  State<KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<KeypadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.bgColor ??
        (widget.isDark ? AppTheme.surface : AppTheme.lightSurface);
    final fg = widget.textColor ??
        (widget.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.035),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: widget.icon != null
              ? Icon(widget.icon, color: fg, size: 22)
              : Center(
                  child: Text(
                    widget.label,
                    style: AppTheme.mono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.geist(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.mono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Operation Badge ───────────────────────────────────────────────────────────
class OperationBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const OperationBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

// ── Timer Ring ────────────────────────────────────────────────────────────────
class TimerRing extends StatelessWidget {
  final double progress;
  final int secondsLeft;

  const TimerRing({
    super.key,
    required this.progress,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final Color ringColor = progress > 0.5
        ? AppTheme.accent
        : progress > 0.25
            ? AppTheme.amber
            : AppTheme.danger;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          Text(
            '$secondsLeft',
            style: AppTheme.mono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vibe Logo ─────────────────────────────────────────────────────────────────
class VibeLogo extends StatelessWidget {
  final double fontSize;
  final bool isDark;
  const VibeLogo({super.key, this.fontSize = 22, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'math',
            style: AppTheme.mono(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'VIBE',
            style: AppTheme.mono(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer Feedback Overlay ───────────────────────────────────────────────────
class FeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final String? correctAnswer;
  final bool isGameOver;

  const FeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswer,
    this.isGameOver = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final color = isCorrect ? AppTheme.success : AppTheme.danger;
    return Container(
      color: color.withValues(alpha: 0.10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 80,
            ),
            if (!isCorrect && correctAnswer != null) ...[
              const SizedBox(height: 14),
              Text(
                'Answer: $correctAnswer',
                style: AppTheme.mono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
            if (isGameOver) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'GAME OVER',
                  style: AppTheme.mono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
