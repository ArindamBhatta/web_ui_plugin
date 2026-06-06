import 'package:flutter/material.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// The sidebar and routes are never hard-coded here; they come from registered plugins.
class VetApplication extends StatelessWidget {
  final Widget child;

  const VetApplication({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              PluginLeftNavigation(
                title: 'Vet Application',
                width: 280,
                collapsedWidth: 56,
                initiallyCollapsed: false,
                showCollapseToggle: true,
                showHeader: true,
                footerBuilder: (context, collapsed) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: collapsed
                        ? Tooltip(
                            message: 'Sign Out',
                            child: IconButton(
                              icon: const Icon(Icons.logout, color: Colors.redAccent),
                              onPressed: () {
                                PermissionMiddleware.instance.clearUser();
                              },
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              PermissionMiddleware.instance.clearUser();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  );
                },
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
