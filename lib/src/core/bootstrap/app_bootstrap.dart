import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Setup and configuration for the app shell, including Firebase initialization and plugin registration.
class BootstrapConfig {
  final Future<void> Function() initializeFirebase;

  /// Default permission policy when a plugin doesn't declare its own.
  final PermissionPolicyAgreement defaultPermissionPolicy;

  /// Optional upload capability implementation.
  final UploadCapability? uploadCapability;

  const BootstrapConfig({
    required this.initializeFirebase,
    this.defaultPermissionPolicy = const OpenDefaultDevelopmentPolicy(),
    this.uploadCapability,
  });
}

/// Main bootstrap class. The app shell calls [initialize] at startup, then [buildRouterApp] to get the configured MaterialApp with routing and state management.
class AppBootstrap {
  AppBootstrap._();

  static const String forbiddenPath = '/forbidden';
  static const String noPluginsPath = '/no-plugins';

  ///step 1:  Internal cache to ensure Cubits link to the correct Repositories during bootstrap.
  // static final Map<String, SectionRepo> _repoCache = {};

  ///initialize firebase private property can't access outside.
  static BootstrapConfig? _config;

  /// Expose the config for internal use by plugins and services.
  static BootstrapConfig get config {
    if (_config == null) {
      throw StateError(
        'AppBootstrap not initialized. Call AppBootstrap.initialize() first.',
      );
    }
    return _config!;
  }

  /// make singleton and enforce initialization before access to config.
  static bool _instance = false;

  /// Step 1: UI call Initialize Firebase package config.
  static Future<void> initialize({required BootstrapConfig config}) async {
    if (_instance) return;
    _config = config;
    await config.initializeFirebase();
    _instance = true;
  }

  /// Step 2: Register all plugins. [doctorsPlugin] and [technicianPlugin] are registered in [VetApplicationBootstrap.run].
  static Future<void> registerPlugins(
    List<DefaultPluginDescription> plugins,
  ) async {
    for (final plugin in plugins) {
      await PluginRegistry.instance.register(plugin);
    }
  }

  /// Step 3: Build the app with GoRouter and BlocProviders based on registered plugins. The [shellBuilder] wraps every page, allowing for a consistent layout (like a sidebar) across all plugin routes.
  static Widget buildRouterApp({
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    String? title,
    String? initialLocation,
    // optional custom forbidden page builder, otherwise a default one is used.
    WidgetBuilder? forbiddenBuilder,
    // optional custom no plugins page builder, otherwise a default one is used.
    WidgetBuilder? noPluginsBuilder,
    // optional custom login page builder, otherwise a default one is used.
    WidgetBuilder? loginBuilder,
    required Widget Function(BuildContext context, Widget child) shellBuilder,
  }) {
    final router = createRouter(
      shellBuilder: shellBuilder,
      initialLocation: initialLocation,
      forbiddenBuilder: forbiddenBuilder,
      noPluginsBuilder: noPluginsBuilder,
      loginBuilder: loginBuilder,
    );
    return MaterialApp.router(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  static GoRouter createRouter({
    required Widget Function(BuildContext context, Widget child) shellBuilder,
    String? initialLocation,
    String? title,
    String? message,
    WidgetBuilder? forbiddenBuilder,
    WidgetBuilder? noPluginsBuilder,
    WidgetBuilder? loginBuilder,
  }) {
    ///
    final List<RouteBase> pluginRoutes = _buildPluginRoutes();

    return GoRouter(
      initialLocation: initialLocation ?? '/',
      refreshListenable: PermissionMiddleware.instance,
      redirect: (context, state) {
        final isLoggedIn = PermissionMiddleware.instance.currentUser != null;
        final isAuthRoute = state.uri.path == '/login';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }
        if (isLoggedIn && isAuthRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, __) => _defaultRouterLocation()),

        GoRoute(
          path: '/login',
          builder: (context, state) {
            return loginBuilder?.call(context) ??
                LoginSignUpPage(
                  style: LoginSignUpStyle.animated,
                  onLogin: (username, password) async {
                    await Future.delayed(const Duration(milliseconds: 800));
                    if (username.isEmpty || password.isEmpty) {
                      throw Exception('Username and Password cannot be empty.');
                    }
                    return UserIdentity(
                      userId: 'mock-user-id',
                      role: const UserRole(id: 'admin', name: 'Admin'),
                      email: username,
                    );
                  },
                  onSignUp: (username, password) async {
                    if (username.isEmpty || password.isEmpty) {
                      throw Exception('Username and Password cannot be empty.');
                    }
                    return UserIdentity(
                      userId: 'mock-user-id',
                      role: const UserRole(id: 'admin', name: 'Admin'),
                      email: username,
                    );
                  },
                );
          },
        ),

        ///Forbidden Route
        GoRoute(
          path: forbiddenPath,
          builder: (context, _) =>
              forbiddenBuilder?.call(context) ??
              _PluginStatusErrorUiView(
                title: title ?? 'Default Title Access denied',
                message:
                    message ??
                    'Default Message Your current persona cannot open this plugin route.',
              ),
        ),

        /// No Plugins Route - shown when no registered plugins are visible to the user.
        GoRoute(
          path: noPluginsPath,
          builder: (context, _) =>
              noPluginsBuilder?.call(context) ??
              _PluginStatusErrorUiView(
                title: title ?? 'No plugins available',
                message:
                    message ??
                    'No registered plugin is visible to the active persona.',
              ),
        ),

        /// Shell route that wraps all plugin routes, providing a common layout (like a sidebar) across the app. The shellBuilder is provided by the UI and can be customized to include navigation, headers, etc.
        ShellRoute(
          builder: (context, _, child) =>
              shellBuilder(context, child), //main UI Placeholder() cover whole
          routes: pluginRoutes,
        ),
      ],
    );
  }

  ///
  static List<RouteBase> _buildPluginRoutes() {
    final routes = <RouteBase>[];

    for (final plugin in PluginRegistry.instance.all) {
      final description = plugin.description;
      for (var index = 0; index < description.routes.length; index++) {
        final route = description.routes[index];
        routes.add(
          GoRoute(
            path: route.path,
            redirect: (_, state) {
              final canAccess = PermissionMiddleware.instance.canAccessRoute(
                description.moduleId,
                route.path,
              );
              if (canAccess) {
                return null;
              }

              if (state.uri.path == forbiddenPath) {
                return null;
              }
              return forbiddenPath;
            },
            builder: route.builder,
          ),
        );
      }
    }

    return routes;
  }

  /// If the user navigates to the root path '/', this function finds the first route from the registered plugins that the user has access to and redirects them there. If no accessible routes are found, it redirects to a default "no plugins available" page.
  static String _defaultRouterLocation() {
    for (final plugin in PluginRegistry.instance.all) {
      // Check plugin visibility first to skip unnecessary route access checks for plugins that aren't visible at all.
      if (!PermissionMiddleware.instance.isPluginVisible(
        plugin.description.moduleId,
      )) {
        continue;
      }

      for (final route in plugin.description.routes) {
        if (PermissionMiddleware.instance.canAccessRoute(
          plugin.description.moduleId,
          route.path,
        )) {
          return route.path;
        }
      }
    }

    return noPluginsPath;
  }

  /// Reset for testing.
  static void reset() {
    _instance = false;
    _config = null;
    PluginRegistry.instance.reset();
  }
}

class _PluginStatusErrorUiView extends StatelessWidget {
  final String title;
  final String message;

  const _PluginStatusErrorUiView({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
