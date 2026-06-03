import 'package:flutter/material.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Middleware that enforces permissions at two levels:
/// 1. Plugin visibility  — is the plugin shown in the sidebar?
/// 2. Route access       — can the user navigate to the route?
class PermissionMiddleware {
  PermissionMiddleware._();
  static final PermissionMiddleware instance = PermissionMiddleware._();

  UserIdentity? _currentUser;

  /// Set (or update) the active user identity.
  /// Call this after login / on auth state changes.
  void setUser(UserIdentity user) => _currentUser = user;

  /// Clear identity on logout.
  void clearUser() => _currentUser = null;

  UserIdentity? get currentUser => _currentUser;

  /// Returns true if the plugin with [moduleId] should be visible in the sidebar.
  bool isPluginVisible(String moduleId) {
    final user = _currentUser;
    if (user == null) return false;

    final plugin = PluginRegistry.instance.findById(moduleId);
    if (plugin == null) return false;

    final policy = plugin.description.visibilityPolicy;
    if (policy == null) return true;

    return policy
        .evaluate(PermissionContext(user: user, moduleId: moduleId))
        .granted;
  }

  /// Returns true if the user can access [routePath] within [moduleId].
  bool canAccessRoute(String moduleId, String routePath) {
    final user = _currentUser;
    if (user == null) return false;

    /// we find plugin because we need to get access to route-level policies, if any. If plugin is not found, we return false for safety — you might want to return true here if you prefer a fail-open approach, but fail-closed is safer by default.
    final RegisteredPlugin<DataModel>? plugin = PluginRegistry.instance
        .findById(moduleId);

    if (plugin == null) return false;

    SingleRouteDescriptionAndPolicy? route;

    for (final r in plugin.description.routes) {
      if (r.path == routePath) {
        route = r;
        break;
      }
    }

    final policy = route?.accessPolicy ?? plugin.description.visibilityPolicy;
    if (policy == null) return true;

    return policy
        .evaluate(
          PermissionContext(
            user: user,
            moduleId: moduleId,
            routePath: routePath,
          ),
        )
        .granted;
  }
}

/// A widget that renders [child] only when the plugin is visible to the user.
/// Shows [fallback] (or nothing) otherwise.
class PluginGate extends StatelessWidget {
  final String moduleId;
  final Widget child;
  final Widget? fallback;

  const PluginGate({
    super.key,
    required this.moduleId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final visible = PermissionMiddleware.instance.isPluginVisible(moduleId);
    if (visible) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
