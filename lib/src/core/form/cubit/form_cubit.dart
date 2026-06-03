import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_ui_plugin/src/core/form/repo/form_repo_mixin.dart';
import 'package:web_ui_plugin/src/core/contracts/data_model.dart';

part 'form_state.dart';

class FormCubit<T extends DataModel> extends Cubit<FormViewState> {
  final FormRepoMixin<T> repo;
  FormCubit({required this.repo}) : super(FromInitial());

  // Create
  Future<String> createItem(T item) async {
    emit(FormInProgress(operation: FormOperation.create));

    try {
      final newItemId = await repo.create(item);
      debugPrint('Created item with ID: $newItemId');

      if (newItemId.isEmpty) {
        throw Exception("Failed to create item");
      }

      emit(FormSuccess<T>(data: item, operation: FormOperation.create));
      return newItemId;
    } catch (error) {
      emit(FormFailure(error: error.toString()));
      debugPrint('Error creating item: $error');
      rethrow;
    }
  }

  //Read
  Future<void> readItems() async {
    emit(FormInProgress(operation: FormOperation.read));
    try {
      final items = await repo.readAll();
      emit(FormLoaded<T>(items: items));
    } catch (error) {
      emit(FormFailure(error: error.toString()));
    }
  }

  // UPDATE
  Future<void> updateItem(int index, T updatedItem) async {
    emit(FormInProgress(operation: FormOperation.update));
    try {
      final updated = await repo.update(index, updatedItem);
      emit(FormSuccess<T>(data: updated, operation: FormOperation.update));
    } catch (e) {
      emit(FormFailure(error: e.toString()));
    }
  }

  // DELETE
  Future<void> deleteItem(T item) async {
    emit(FormInProgress(operation: FormOperation.delete));
    try {
      final removed = await repo.delete(item);
      emit(FormSuccess<T>(data: removed, operation: FormOperation.delete));
    } catch (e) {
      emit(FormFailure(error: e.toString()));
    }
  }
}
