import 'package:flutter/material.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class SectionView extends StatelessWidget {
  final Widget child;
  final String sectionLabel;
  final IconData sectionIcon;
  final Color sectionColor;
  final List<Widget>? headerLeftActions;
  final List<Widget>? headerCenterActions;
  final List<Widget>? headerRightActions;
  final double headerLeftActionsInset;
  final List<Widget>? actions;

  const SectionView({
    super.key,
    required this.child,
    required this.sectionLabel,
    required this.sectionIcon,
    required this.sectionColor,
    this.headerLeftActions,
    this.headerCenterActions,
    this.headerRightActions,
    this.headerLeftActionsInset = 0,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //header portion of section
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          height: AppTheme.topBarHeight,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppTheme.sidePadding,
              right: AppTheme.sidePadding / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(sectionIcon, size: 24, color: sectionColor),
                SizedBox(width: AppTheme.sidePadding),
                Text(
                  sectionLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (headerLeftActions != null &&
                    headerLeftActions!.isNotEmpty) ...[
                  SizedBox(width: AppTheme.sidePadding),
                  Padding(
                    padding: EdgeInsets.only(left: headerLeftActionsInset),
                    child: Row(
                      spacing: AppTheme.sidePadding / 2,
                      children: headerLeftActions!,
                    ),
                  ),
                ],
                const Spacer(),
                if (headerCenterActions != null &&
                    headerCenterActions!.isNotEmpty) ...[
                  Row(
                    spacing: AppTheme.sidePadding / 2,
                    children: headerCenterActions!,
                  ),
                  const Spacer(),
                ],
                if (headerRightActions != null &&
                    headerRightActions!.isNotEmpty)
                  Row(
                    spacing: AppTheme.sidePadding / 2,
                    children: headerRightActions!,
                  )
                else if (actions != null)
                  Row(spacing: AppTheme.sidePadding, children: actions!),
              ],
            ),
          ),
        ),
        const Divider(thickness: 1, height: 1),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: child, //Pass the child eg(SubSectionView)
          ),
        ),
      ],
    );
  }
}
