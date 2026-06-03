import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SnackBarCategory { warning, success, info, failure }

extension SnackBarCategoryExtension on SnackBarCategory {
  Color backgroundColor(BuildContext context) {
    return switch (this) {
      SnackBarCategory.failure => const Color(0xFFB00020),
      SnackBarCategory.warning => const Color(0xFFED6C02),
      SnackBarCategory.success => const Color(0xFF2E7D32),
      SnackBarCategory.info => const Color(0xFF0288D1),
    };
  }

  IconData get icon {
    return switch (this) {
      SnackBarCategory.failure => FontAwesomeIcons.triangleExclamation,
      SnackBarCategory.warning => FontAwesomeIcons.circleExclamation,
      SnackBarCategory.success => FontAwesomeIcons.circleCheck,
      SnackBarCategory.info => FontAwesomeIcons.circleInfo,
    };
  }

  Duration get duration {
    return switch (this) {
      SnackBarCategory.failure => const Duration(seconds: 5),
      SnackBarCategory.warning => const Duration(seconds: 4),
      SnackBarCategory.success => const Duration(seconds: 3),
      SnackBarCategory.info => const Duration(seconds: 4),
    };
  }
}

class CustomSnackBar {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context,
    String message, {
    SnackBarCategory category = SnackBarCategory.info,
    Color? backgroundColor,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      category: category,
      backgroundColor: backgroundColor,
      duration: duration ?? category.duration,
    );
  }

  static void showPersistent(
    BuildContext context,
    String message, {
    SnackBarCategory category = SnackBarCategory.info,
    Color? backgroundColor,
  }) {
    _show(
      context,
      message,
      category: category,
      backgroundColor: backgroundColor,
      duration: const Duration(days: 365),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required SnackBarCategory category,
    Color? backgroundColor,
    required Duration duration,
  }) {
    void showNow() {
      if (!context.mounted) return;

      final overlayState = Navigator.of(context, rootNavigator: true).overlay;
      if (overlayState == null) return;

      // Remove any existing overlay to prevent overlapping
      if (_currentOverlay?.mounted ?? false) {
        _currentOverlay?.remove();
      }
      _currentOverlay = null;

      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            bottom: 24.0,
            left: 24.0,
            right: 24.0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _CustomToastWidget(
                      message: message,
                      category: category,
                      backgroundColor: backgroundColor,
                      duration: duration,
                      onDismissed: () {
                        if (overlayEntry.mounted &&
                            _currentOverlay == overlayEntry) {
                          overlayEntry.remove();
                          _currentOverlay = null;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      _currentOverlay = overlayEntry;
      overlayState.insert(overlayEntry);
    }

    //check my exists  CustomSnackBar!
    final phase = SchedulerBinding.instance.schedulerPhase;

    final isBuildPhase =
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks;

    if (isBuildPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showNow();
      });
      return;
    }

    showNow();
  }
}

class _CustomToastWidget extends StatefulWidget {
  final String message;
  final SnackBarCategory category;
  final Color? backgroundColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CustomToastWidget({
    required this.message,
    required this.category,
    this.backgroundColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_CustomToastWidget> createState() => _CustomToastWidgetState();
}

class _CustomToastWidgetState extends State<_CustomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final Key _dismissKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: _dismissKey,
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismissed(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  widget.category.backgroundColor(context),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 12,
              children: [
                Icon(widget.category.icon, color: Colors.white, size: 20),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) {
                        if (mounted) widget.onDismissed();
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
