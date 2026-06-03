import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

typedef ModelFromJson<T> = T Function(Map<String, dynamic>);

/// Firebase Firestore implementation of [FormServiceMixin].
///
/// Key change from old SectionService:
/// - Instances are keyed by [CrossModuleSingletonKey] (moduleId + modelType + collection)
///   instead of the old global "collection-Type" string, preventing
///   cross-module singleton collisions.
class FirestoreService<T extends DataModel> with FormServiceMixin<T> {
  static final SingletonScopedRegistry<FirestoreService> _registry =
      SingletonScopedRegistry<FirestoreService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName;
  final ModelFromJson<T> _fromJson;
  final String moduleId;
  final bool supportsRealtime;

  /// Exposed so ScopedRepo can derive the registry key without reflection.
  String get collectionName => _collectionName;

  FirestoreService._internal({
    required this.moduleId,
    required String collectionName,
    required ModelFromJson<T> fromJson,
    this.supportsRealtime = true,
  }) : _collectionName = collectionName,
       _fromJson = fromJson {
    if (supportsRealtime) {
      _firestore.collection(_collectionName).snapshots().listen((
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final items = snapshot.docs
            .map((doc) => _fromJson(doc.data()))
            .toList();
        emitData(items);
      });
    } else {
      // If realtime is disabled, we do a one-time fetch to populate the initial state
      readAll().then((items) => emitData(items));
    }
  }

  /// Scoped factory: one instance per (moduleId, T, collectionName) triple.
  factory FirestoreService({
    required String moduleId,
    required String collectionName,
    required ModelFromJson<T> fromJson,
    bool supportsRealtime = true,
  }) {
    final key = CrossModuleSingletonKey(
      moduleId: moduleId,
      modelType: T.toString(),
      collection: collectionName,
    );

    return _registry.getOrCreate(
          key,
          () => FirestoreService<T>._internal(
            moduleId: moduleId,
            collectionName: collectionName,
            fromJson: fromJson,
            supportsRealtime: supportsRealtime,
          ),
        )
        as FirestoreService<T>;
  }

  @override
  Future<String> create(T newItem) async {
    try {
      final data = newItem.toJson();
      final id = Uuid().v4();
      data['id'] = id;
      await _firestore.collection(_collectionName).doc(id).set(data);
      return id;
    } catch (error) {
      throw Exception('Failed to create item: $error');
    }
  }

  @override
  Future<List<T>> readAll() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs.map((doc) => _fromJson(doc.data())).toList();
    } catch (error) {
      throw Exception('Failed to read items: $error');
    }
  }

  @override
  Future<T> update(T updateItem) async {
    try {
      final id = (updateItem as dynamic).id as String?;
      if (id == null || id.isEmpty) {
        throw Exception("Item id can't be null for Update");
      }
      final query = await _firestore
          .collection(_collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isEmpty) throw Exception('No item found with id $id');
      await _firestore
          .collection(_collectionName)
          .doc(query.docs.first.id)
          .update(updateItem.toJson());
      return updateItem;
    } catch (error) {
      throw Exception('Failed to update item: $error');
    }
  }

  @override
  Future<T> delete(T item) async {
    try {
      final id = (item as dynamic).id as String?;
      if (id == null || id.isEmpty) {
        throw Exception("Item id can't be null for Delete");
      }
      final query = await _firestore
          .collection(_collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isEmpty) throw Exception('No item found with id $id');
      await _firestore
          .collection(_collectionName)
          .doc(query.docs.first.id)
          .delete();
      return item;
    } catch (error) {
      throw Exception('Failed to delete item: $error');
    }
  }
}
