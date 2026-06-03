import 'dart:async';

import 'package:web_ui_plugin/src/core/form/service/form_service_mixin.dart';
import 'package:web_ui_plugin/src/core/contracts/data_model.dart';

//knows when and why to call CRUD, caches results, tracks IDs, emits streams.
mixin FormRepoMixin<T extends DataModel> {
  late final FormServiceMixin<T> service;

  final StreamController<(List<T>, String?)> _dataController =
      StreamController<(List<T>, String?)>.broadcast();

  //Expose the broadcast stream
  Stream<(List<T>, String?)> get dataStream => _dataController.stream;

  /// This should be set after creating the document in Firestore
  String? newlyAddedItemId;

  void emitData(List<T> data, {String? addedItemId}) {
    if (!_dataController.isClosed) {
      _dataController.add((data, addedItemId));
    }
  }

  final List<T> items = [];

  //----------- Call this once after you’ve created the service -------------
  void initService(FormServiceMixin<T> srv) {
    service = srv;
    // Listen to real-time updates from the service
    service.dataStream.listen((data) {
      items.clear();
      items.addAll(data);

      //checking if this newly created item exists in the local items list
      String? addedItemId = items.any((item) => item.uid == newlyAddedItemId)
          ? newlyAddedItemId
          : null;

      // if addedItemId is null it means the newly added item is not yet in the items list
      if (addedItemId != null) {
        newlyAddedItemId = null;
      }

      emitData(items, addedItemId: addedItemId); //addedItemId is null
    });
  }

  //Whenever you need to add a new record (e.g., user submits a form).
  Future<String> create(T item) async {
    final newItemId = await service.create(item);
    newlyAddedItemId = newItemId;
    return newItemId;
  }

  //To get all items, either from cache (items) or freshly fetched.
  //Avoids unnecessary backend calls unless you explicitly request a refresh
  Future<List<T>> readAll({bool forceFetch = false}) async {
    if (items.isNotEmpty && !forceFetch) {
      return items;
    }
    final fetched = await service.readAll();
    items.clear();
    items.addAll(fetched);
    return fetched;
  }

  //To update an existing record, when you already know its index in items.
  Future<T> update(int index, T updatedItem) async {
    final updated = await service.update(updatedItem);
    if (index < 0 || index >= items.length) {
      throw Exception('Item not found');
    }
    items[index] = updated;
    emitData(items); // Broadcast the optimistic update to the SectionCubit!
    return updated;
  }

  Future<T> delete(T item) async {
    final index = items.indexOf(item);
    if (index < 0 || index >= items.length) {
      throw Exception('Item not found');
    }
    final removed = await service.delete(item);
    items.removeAt(index);
    emitData(items); // Broadcast the removal to the SectionCubit!
    return removed;
  }

  void dispose() {
    service.dispose();
    _dataController.close();
  }
}
