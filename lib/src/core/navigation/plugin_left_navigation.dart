import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class _RightTooltip extends StatefulWidget {
  final String message;
  final bool enabled;
  final Widget child;

  const _RightTooltip({
    required this.message,
    required this.enabled,
    required this.child,
  });

  @override
  State<_RightTooltip> createState() => _RightTooltipState();
}

class _RightTooltipState extends State<_RightTooltip> {
  OverlayEntry? _entry;

  void _show(Offset position) {
    if (!widget.enabled || widget.message.isEmpty) {
      return;
    }
    _remove();
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx + 14,
        top: position.dy - 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _show(event.position),
      onExit: (_) => _remove(),
      child: widget.child,
    );
  }
}

class PluginLeftNavigation extends StatefulWidget {
  final String? title;
  final double width;
  final double collapsedWidth;
  final bool initiallyCollapsed;
  final bool showCollapseToggle;
  final bool showHeader;
  final bool warnOnUnsavedChanges;
  final VoidCallback? onItemTap;
  final Widget Function(BuildContext context, bool collapsed)? footerBuilder;
  final ValueChanged<bool>? onCollapseChanged;

  const PluginLeftNavigation({
    super.key,
    this.title,
    this.width = 240,
    this.collapsedWidth = 56,
    this.initiallyCollapsed = false,
    this.showCollapseToggle = true,
    this.showHeader = true,
    this.warnOnUnsavedChanges = true,
    this.onItemTap,
    this.footerBuilder,
    this.onCollapseChanged,
  });

  @override
  State<PluginLeftNavigation> createState() => _PluginLeftNavigationState();
}

class _PluginLeftNavigationState extends State<PluginLeftNavigation> {
  static const Duration _animDuration = Duration(milliseconds: 260);
  static const Curve _animCurve = Curves.easeInOutCubic;

  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  void _toggleCollapse() {
    setState(() {
      _collapsed = !_collapsed;
    });
    widget.onCollapseChanged?.call(_collapsed);
  }

  Widget _buildHeader(BuildContext context) {
    final toggleButton = Tooltip(
      message: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: IconButton(
        onPressed: _toggleCollapse,
        icon: Transform.rotate(
          angle: math.pi,
          child: Icon(
            Icons.view_sidebar_outlined,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryFixed.withAlpha(_collapsed ? 255 : 128),
            size: 22,
          ),
        ),
      ),
    );

    return SizedBox(
      height: AppTheme.topBarHeight,
      child: Container(
        color: Theme.of(context).colorScheme.primaryFixedDim,
        child: _collapsed
            ? Center(child: toggleButton)
            : Row(
                children: [
                  if ((widget.title ?? '').trim().isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          widget.title!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  toggleButton,
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = PluginRegistry.instance.all.where((plugin) {
      return PermissionMiddleware.instance.isPluginVisible(
        plugin.description.moduleId,
      );
    }).toList();

    /// Gets the current path from GoRouterState to determine which nav item is active.
    final String currentPath = GoRouterState.of(context).uri.path;

    /// Determines the width of the navigation based on whether it's collapsed or not.
    final double navWidth = _collapsed ? widget.collapsedWidth : widget.width;

    return AnimatedContainer(
      duration: _animDuration,
      curve: _animCurve,
      width: navWidth,
      color: Theme.of(context).colorScheme.primaryFixed,
      child: Column(
        children: [
          if (widget.showHeader && widget.showCollapseToggle)
            _buildHeader(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showLabels = !_collapsed && constraints.maxWidth >= 180;
                const itemHeight = 34.0;
                const separatorHeight = 16.0;

                double? selectedTop;
                var runningTop = 0.0;
                for (var index = 0; index < items.length; index++) {
                  final description = items[index].description;

                  /// Checks if the current path matches any of the plugin's routes to determine if this item is selected.
                  final isSelected = _matchesRoute(
                    currentPath,
                    description.routes,
                  );

                  if (isSelected) {
                    selectedTop = runningTop;
                    break;
                  }

                  runningTop += itemHeight;
                  if (index < items.length - 1) {
                    runningTop += separatorHeight;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  children: [
                    Stack(
                      children: [
                        if (selectedTop != null)
                          AnimatedPositioned(
                            duration: _animDuration,
                            curve: _animCurve,
                            left: 0,
                            right: 0,
                            top: selectedTop,
                            child: IgnorePointer(
                              child: Container(
                                height: itemHeight,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              var index = 0;
                              index < items.length;
                              index++
                            ) ...[
                              _buildNavItem(
                                context,
                                currentPath: currentPath,
                                description: items[index].description,
                                showLabels: showLabels,
                                itemHeight: itemHeight,
                              ),
                              if (index < items.length - 1)
                                Divider(
                                  color: Theme.of(context).colorScheme.outline,
                                  thickness: 0.5,
                                  height: separatorHeight,
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.footerBuilder != null)
            widget.footerBuilder!(context, _collapsed),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String currentPath,
    required DefaultPluginDescription description,
    required bool showLabels,
    required double itemHeight,
  }) {
    final primaryRoute = description.routes.firstOrNull;
    if (primaryRoute == null) {
      return const SizedBox.shrink();
    }

    final isSelected = _matchesRoute(currentPath, description.routes);

    return SizedBox(
      height: itemHeight,
      child: _RightTooltip(
        message: description.title,
        enabled: !showLabels,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            onTap: () {
              if (widget.warnOnUnsavedChanges &&
                  currentPath != primaryRoute.path &&
                  SectionCubit.hasUnsavedFormChanges) {
                CustomSnackBar.show(
                  context,
                  'You lost some unsaved changes by navigating out of this page.',
                  category: SnackBarCategory.warning,
                );
                SectionCubit.hasUnsavedFormChanges = false;
              }

              context.go(primaryRoute.path);
              widget.onItemTap?.call();
            },
            child: Padding(
              padding: showLabels
                  ? const EdgeInsets.symmetric(horizontal: 20)
                  : const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: showLabels
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(description.icon, color: description.color, size: 20),
                  if (showLabels) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: _animDuration,
                        curve: _animCurve,
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ) ??
                            TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                        child: Text(
                          description.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Checks if [currentPath] matches any of the plugin's routes (exact or as a parent).
  bool _matchesRoute(
    String currentPath,
    List<SingleRouteDescriptionAndPolicy> routes,
  ) {
    for (final route in routes) {
      final path = route.path;
      if (currentPath == path) {
        return true;
      }
      if (path != '/' && currentPath.startsWith('$path/')) {
        return true;
      }
    }
    return false;
  }
}
