import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// PDF Guru-style pill button.
/// - Soft lavender background (#EDE7F6)
/// - Purple text/icon (#6C5C8F)
/// - Pill shape, subtle shadow, no hard border
/// - [filled] = true → solid purple background with white text (action/confirm)
/// - [filled] = false (default) → lavender bg with purple text (select/pick)
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool fullWidth;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = false,
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    const purple = Color(0xFF6C5C8F);
    const lavender = Color(0xFFEDE7F6);

    final bg = filled ? purple : lavender;
    final fg = filled ? Colors.white : purple;
    final radius = r.scale(30);
    final vPad = r.hp(2).clamp(12.0, 20.0);

    Widget btn = Material(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      shadowColor: purple.withOpacity(0.18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.wp(4), vertical: vPad),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: r.scale(18),
                  height: r.scale(18),
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                SizedBox(width: r.wp(2)),
              ] else if (icon != null) ...[
                Icon(icon, color: fg, size: r.scale(20)),
                SizedBox(width: r.wp(2)),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: fg,
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
