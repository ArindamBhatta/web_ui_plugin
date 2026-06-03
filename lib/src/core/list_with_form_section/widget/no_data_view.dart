import 'package:flutter/material.dart';

class NoDataView extends StatelessWidget {
  const NoDataView({
    super.key,
    this.title = 'No Data Available',
    this.subtitle = 'Please check back later.',
    this.icon = Icons.info_outline,
    this.iconColor = Colors.grey,
    this.iconSize = 100.0,
    this.iconAlpha = 0.5,
    this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final double iconAlpha;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: iconAlpha,
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
