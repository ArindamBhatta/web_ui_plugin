import 'dart:async';

/* absolutely zero mention of cloud_firestore in that code.
 It is pure Dart. It just says: "I don't care how you do it, but whatever backend you use must be able to create, read, update, delete, and provide a data stream." */
mixin FormServiceMixin<T> {
  /// Indicates if this service provides real-time automatic stream updates.
  bool get supportsRealtime => false;

  // Broadcast stream for real-time data updates
  final StreamController<List<T>> _dataController =
      StreamController<List<T>>.broadcast();

  // Expose the stream to the outside world
  Stream<List<T>> get dataStream => _dataController.stream;

  void emitData(List<T> data) {
    if (!_dataController.isClosed) {
      _dataController.add(data);
    }
  }

  //CRUD methods interface
  Future<String> create(T item);
  Future<List<T>> readAll();
  Future<T> update(T item);
  Future<T> delete(T item);

  void dispose() {
    _dataController.close();
  }
}
