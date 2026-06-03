import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Scoped repository: replaces old SectionRepo with a registry keyed by
/// (moduleId + modelType + collection) instead of just (Type).
///
/// This prevents cross-module collisions when two plugins use the same model
/// type but different collections.
class SectionRepo<T extends DataModel> with FormRepoMixin<T> {
  static final SingletonScopedRegistry<SectionRepo> _registry =
      SingletonScopedRegistry<SectionRepo>();

  final String moduleId;

  //
  SectionRepo._internal({
    required this.moduleId,
    required FormServiceMixin<T> service,
  }) {
    initService(service);
  }

  /// Scoped factory: one repo per (moduleId, T, collectionName) triple.
  factory SectionRepo({
    required String moduleId,
    required FormServiceMixin<T> service,
    bool supportsRealtime = true,
  }) {
    // Derive collection name from the service if it's a FirestoreService.
    final collectionName =
        (service as dynamic).collectionName as String? ?? T.toString();

    final CrossModuleSingletonKey key = CrossModuleSingletonKey(
      moduleId: moduleId,
      modelType: T.toString(),
      collection: collectionName,
    );

    return _registry.getOrCreate(
          key,
          () => SectionRepo<T>._internal(moduleId: moduleId, service: service),
        )
        as SectionRepo<T>;
  }

  /// Convenience factory to build a repo directly from a [PluginDescriptor]. This ensures that feature flags (like supportsRealtime) are respected from a single source of truth.
  factory SectionRepo.fromDescriptor(DefaultPluginDescription<T> descriptor) {
    final PluginDataBinding<T> binding = descriptor.dataBinding;

    return SectionRepo<T>(
      moduleId: descriptor.moduleId,
      supportsRealtime: descriptor.features.supportsRealtime,
      service: FirestoreService<T>(
        moduleId: descriptor.moduleId,
        collectionName: binding.collectionName,
        fromJson: binding.fromJson,
        supportsRealtime: descriptor.features.supportsRealtime,
      ),
    );
  }

  /// Convenience lookup: find an item by its uid in the local cache.
  T? getById(String id) {
    try {
      return items.firstWhere((item) => item.uid == id);
    } catch (_) {
      return null;
    }
  }
}
