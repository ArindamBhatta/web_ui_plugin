import 'package:web_ui_plugin/web_ui_plugin.dart';

///SectionRepo call by end user.
class SectionRepo<T extends DataModel> with FormRepoMixin<T> {
  /// Registry for SectionRepo instances, keyed by [CrossModuleSingletonKey].
  static final SingletonScopedRegistry<SectionRepo> _registry =
      SingletonScopedRegistry<SectionRepo>();

  final String moduleId;

  /// Name private constructor to create registry entry
  SectionRepo._internal({
    required this.moduleId,
    required FormServiceMixin<T> service,
  }) {
    initService(service);
  }

  //? Purpose
  //This is the low-level, decoupled constructor that manages the singleton instance registry.
  //? Why it's designed this way:
  // It is decoupled from any specific backend implementation. It requires you to explicitly pass a FormServiceMixin<T>. This is highly beneficial for:Testing: You can inject a mock service, an in-memory service, or a fake database.
  //Flexibility: It allows you to use repository implementations other than Firestore.
  factory SectionRepo({
    required String moduleId,
    required FormServiceMixin<T> service,
    bool supportsRealtime = true,
  }) {
    // Derive collection name from the service if it's a FirestoreService.
    final String collectionName =
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

  //? Purpose:
  //This is a high-level, developer-friendly factory designed to instantiate a repository directly from a plugin's metadata.
  //? Why it is needed
  /// Reduces Boilerplate: In your plugins like [PetOwnerPlugin], rather than manually unpacking the descriptor's fields to construct the database service:
  factory SectionRepo.fromDescriptor(DefaultPluginDescription<T> descriptor) {
    final PluginDataConnector<T> binding = descriptor.dataBinding;
    //call the factory constructor
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
