import 'package:flutter/material.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

//?  PermissionMiddleware (The Gatekeeper Evaluating Session State)
// It keeps track of the active runtime state—specifically the currently logged-in user (_currentUser).
// It needs to evaluate the rules in the registry against the logged-in user.
class PermissionMiddleware extends ChangeNotifier {
  PermissionMiddleware._();
  static final PermissionMiddleware instance = PermissionMiddleware._();

  UserIdentity? _currentUser;

  /// Set (or update) the active user identity.
  void setUser(UserIdentity user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Clear identity on logout.
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  UserIdentity? get currentUser => _currentUser;

  ///🧐  Checkpoint 1: The Navigation Sidebar (Silent Treatment)
  bool isPluginVisible(String moduleId) {
    final user = _currentUser;
    if (user == null) return false;
    // 1. Fetch the plugin descriptor from the registry catalog
    final plugin = PluginRegistry.instance.findById(moduleId);
    if (plugin == null) return false;

    // 2. Fetch the security policy declared on that plugin
    final policy = plugin.description.visibilityPolicy;
    if (policy == null) return true;

    // 3. Evaluate the policy against the current user identity
    return policy
        .evaluate(PermissionContext(user: user, moduleId: moduleId))
        .granted;
  }

  //🧐 Checkpoint 2: The Direct Route Attempt (The Access Gate)
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

//? Checkpoint 3: The PluginGate Widget (The Guard Post)
//If a user somehow sneaks through or the UI tries to build a protected widget, they hit the PluginGate guard post:.
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
