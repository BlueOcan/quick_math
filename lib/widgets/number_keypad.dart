import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class NumberKeypad extends StatelessWidget {
  final String currentInput;
  final ValueChanged<String> onDigitTap;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final bool isDark;

  const NumberKeypad({
    super.key,
    required this.currentInput,
    required this.onDigitTap,
    required this.onDelete,
    required this.onSubmit,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      children: [
        // ── Input display ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentInput.isEmpty ? '—' : currentInput,
                style: AppTheme.mono(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: currentInput.isEmpty ? textMuted : textPrimary,
                  letterSpacing: 2,
                ),
              ),
              if (currentInput.isNotEmpty)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.backspace_rounded,
                    color: textSecondary,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Keys ──────────────────────────────────────────────
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map(
              (n) => KeypadButton(
                label: '$n',
                onTap: () => onDigitTap('$n'),
                isDark: isDark,
              ),
            ),
            KeypadButton(
              label: '−',
              onTap: () => onDigitTap('-'),
              textColor: textSecondary,
              isDark: isDark,
            ),
            KeypadButton(
              label: '0',
              onTap: () => onDigitTap('0'),
              isDark: isDark,
            ),
            KeypadButton(
              label: '✓',
              onTap: onSubmit,
              textColor: Colors.white,
              bgColor: AppTheme.accent,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}
