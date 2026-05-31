import 'package:flutter/material.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class CustomDialogBox extends StatelessWidget {
  final String title;
  final String? subtitle; // Todo implement subtitle in dialog
  final double? width;
  final double? height;
  final IconData? icon;
  final Widget child;

  const CustomDialogBox({
    super.key,
    required this.title,
    this.subtitle,
    this.width,
    this.height,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      title: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.sidePadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(4),
            bottom: Radius.circular(0),
          ),
        ),
        child: Center(
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      content: SizedBox(
        height: height ?? 400,
        width: width ?? 600,
        child: Builder(
          builder: (context) {
            return child;
          },
        ),
      ),
    );
  }
}
