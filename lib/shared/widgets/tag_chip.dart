import 'package:flutter/material.dart';

/// Widget pour afficher un tag/chip
class TagChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSelected;
  final IconData? icon;

  const TagChip({
    Key? key,
    required this.text,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.isSelected = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : (backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : (textColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : (textColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
