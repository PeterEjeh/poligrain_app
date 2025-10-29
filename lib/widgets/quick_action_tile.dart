import 'package:flutter/material.dart';

/// Compact square quick-action tile used on the Home screen.
/// - iconWidget: custom icon widget (preferred) otherwise icon will be used
/// - label: short text, can include line breaks (e.g. 'Add\nProduct')
/// - onTap: tap handler
/// - size: optional fixed size; when null the tile uses responsive defaults
class QuickActionTile extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final double? size;
  final Color color;
  final Color iconColor;
  final Color labelColor;

  const QuickActionTile({
    Key? key,
    this.iconWidget,
    this.icon,
    required this.label,
    required this.onTap,
    this.size,
    this.color = const Color(0xFF0F7A3D), // default deep green
    this.iconColor = Colors.white,
    this.labelColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultSize = (screenWidth * 0.18).clamp(64.0, 96.0);
    final tileSize = size ?? defaultSize;
    final iconSize = (tileSize * 0.42).clamp(20.0, 36.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child:
                  iconWidget ??
                  (icon != null
                      ? Icon(icon, size: iconSize, color: iconColor)
                      : const SizedBox.shrink()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: tileSize,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (screenWidth * 0.028).clamp(10.0, 14.0),
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
