import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Resolved and active plugin entry, stored after successful registration.
class RegisteredPlugin<T extends DataModel> {
  final DefaultPluginDescription<T> description;
  final DateTime registeredAt;

  RegisteredPlugin(this.description) : registeredAt = DateTime.now();
}

//? PluginRegistry (The Catalog of Security Policies)
//It is the static registry that knows about every module/plugin registered in your app.
//It stores the declarative rules (e.g., visibilityPolicy: PersonaPermissionPolicy({'admin', 'operator'})).
//It does not know who is logged in. It is just a directory of metadata.
class PluginRegistry {
  PluginRegistry._();

  /// Singleton instance.
  static final PluginRegistry instance = PluginRegistry._();

  /// Internal list of registered plugins.
  final List<RegisteredPlugin> _plugins = [];

  /// Register a plugin. Throws if a plugin with the same [moduleId] is already registered (guards against double-registration on hot reload).
  Future<void> register<T extends DataModel>(
    DefaultPluginDescription<T> aggPlugin,
  ) async {
    final bool alreadyExists = _plugins.any(
      (plugin) => plugin.description.moduleId == aggPlugin.moduleId,
    );

    if (alreadyExists) return; // No Change idempotent

    /// Call the plugin's onRegister callback if it exists, allowing it to perform
    await aggPlugin.onRegister?.call();

    ///add the plugin to the registry after successful registration
    _plugins.add(RegisteredPlugin<T>(aggPlugin));
  }

  /// All registered plugins, sorted by [order].
  // Todo: order is decided by the end developer.
  List<RegisteredPlugin> get all {
    // Return a sorted copy of the plugins list to ensure consistent order without mutating the original list.
    final sorted = List<RegisteredPlugin>.from(_plugins);
    // Sort plugins by their specified order in the description, ensuring a consistent display order in the UI.
    sorted.sort((a, b) => a.description.order.compareTo(b.description.order));
    return sorted;
  }

  /// Find a plugin by moduleId. used in [PermissionMiddleware] for permission checks.
  RegisteredPlugin? findById(String moduleId) {
    return all.cast<RegisteredPlugin?>().firstWhere(
      (plugin) => plugin?.description.moduleId == moduleId,
      orElse: () => null,
    );
  }

  /// Reset for testing.
  void reset() => _plugins.clear();
}
