import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_ui_plugin/src/core/form/cubit/form_cubit.dart';
import 'package:web_ui_plugin/src/core/form/repo/form_repo_mixin.dart';
import 'package:web_ui_plugin/src/core/widgets/package_enums.dart';

import 'package:web_ui_plugin/src/core/contracts/data_model.dart';

part 'section_state.dart';

class SectionCubit<T extends DataModel> extends Cubit<SectionState<T>> {
  // Tracks whether the currently active form has unsaved edits.
  static bool hasUnsavedFormChanges = false;

  // Reactive Flow: The repo manages the data connection to Firebase.
  // It provides a 'dataStream' that this Cubit listens to for real-time updates.
  final FormRepoMixin<T> repo;

  // Optional FormCubit link to coordinate UI loading/waiting states and deletion side-effects.
  final FormCubit<T>? formCubit;

  //3rd take optional functions to extract status and date from items for filtering
  final String? Function(T item)? statusKeyOf;

  //4th take optional function to extract date from item for date range filtering
  final DateTime? Function(T item)? dateOf;

  // Reactive Flow: The stream of data Form  the repository (originating from Firebase)
  late Stream<(List<T>, String?)> _repoStream;

  // Reactive Flow: The active subscription to the repository's stream.
  // Kept here so it can be cleanly cancelled when the cubit is closed.
  late StreamSubscription<(List<T>, String?)>? _repoSubscription;

  // Subscription to the linked FormCubit.
  StreamSubscription<FormViewState>? _formSubscription;

  // Expose selectedItem for external access if needed
  T? selectedItem;

  SectionCubit({
    required this.repo,
    this.formCubit,
    this.statusKeyOf,
    this.dateOf,

    // App States eg Pending, Completed
    Set<String> initialSelectedStatuses = const <String>{},
    String? initialSelectedItemId,
  }) : super(
         SectionState<T>(
           selectedStatuses: initialSelectedStatuses
               .map((e) => e.trim())
               .where((e) => e.isNotEmpty)
               .toSet(),
           addedItemId: initialSelectedItemId,
         ),
       ) {
    _listenToRepo();
    _listenToFormCubit();
  }

  // It subscribes to a Stream from the repo . Whenever the database or API updates, the Cubit automatically receives the new list, applies the current filters (search text, dates), and emits a new state
  void _listenToRepo() {
    _repoStream = repo.dataStream;

    _repoSubscription = _repoStream.listen((data) {
      final items = data.$1;
      final addedItemId = data.$2;

      // If an item was just added or we have an initial/pending selection, try to select it by ID
      T? selected;
      final String? targetId = addedItemId ?? state.addedItemId;
      if (targetId != null) {
        try {
          selected = items.cast<T?>().firstWhere(
            (item) => item?.uid == targetId,
            orElse: () => null,
          );
        } catch (_) {
          selected = null;
        }
      }

      final filtered = _applyFilters(
        items,
        searchText: state.searchText,
        selectedStatuses: state.selectedStatuses,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      final nextSelected = _resolveSelected(selected ?? state.selectedItem, filtered);

      final newState = state.copyWith(
        items: items,
        filteredItems: filtered,
        selectedItem: nextSelected,
        addedItemId: nextSelected != null ? null : (addedItemId ?? state.addedItemId),
      );
      selectedItem = nextSelected;

      emit(newState);
    });
  }

  List<T> _filterItemsBySearch(List<T> items, String searchText) {
    final normalized = searchText.trim().toLowerCase();
    if (normalized.isEmpty) return items;

    return items
        .where(
          (item) =>
              (item.title ?? '').toLowerCase().contains(normalized) ||
              (item.subTitle ?? '').toLowerCase().contains(normalized),
        )
        .toList();
  }

  bool _matchesStatusFilter(T item, Set<String> selectedStatuses) {
    if (selectedStatuses.isEmpty) return true;
    if (statusKeyOf == null) return true;
    final statusKey = statusKeyOf!(item);
    if (statusKey == null || statusKey.isEmpty) return false;
    return selectedStatuses.contains(statusKey);
  }

  bool _matchesDateRange(T item, DateTime? fromDate, DateTime? toDate) {
    if (fromDate == null && toDate == null) return true;
    if (dateOf == null) return true;

    final itemDate = dateOf!(item);
    if (itemDate == null) return false;

    final normalizedFrom = fromDate == null
        ? null
        : DateTime(fromDate.year, fromDate.month, fromDate.day);
    final normalizedTo = toDate == null
        ? null
        : DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);

    if (normalizedFrom != null && itemDate.isBefore(normalizedFrom)) {
      return false;
    }
    if (normalizedTo != null && itemDate.isAfter(normalizedTo)) {
      return false;
    }
    return true;
  }

  List<T> _applyFilters(
    List<T> items, {
    required String searchText,
    required Set<String> selectedStatuses,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    final searched = _filterItemsBySearch(items, searchText);
    return searched
        .where((item) => _matchesStatusFilter(item, selectedStatuses))
        .where((item) => _matchesDateRange(item, fromDate, toDate))
        .toList();
  }

  T? _resolveSelected(T? candidate, List<T> filteredItems) {
    if (candidate == null) return null;
    try {
      return filteredItems.firstWhere((item) => item.uid == candidate.uid);
    } catch (_) {
      return null;
    }
  }

  void loadAll() async {
    emit(state.copyWith(status: SuccessStatus.waiting));
    try {
      final items = await repo.readAll(forceFetch: true);
      final filtered = _applyFilters(
        items,
        searchText: state.searchText,
        selectedStatuses: state.selectedStatuses,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      final candidateSelected = selectedItem ?? (state.addedItemId != null
          ? items.cast<T?>().firstWhere(
              (item) => item?.uid == state.addedItemId,
              orElse: () => null,
            )
          : null);
      final selected = _resolveSelected(candidateSelected, filtered);
      selectedItem = selected;
      emit(
        state.copyWith(
          status: SuccessStatus.success,
          items: items,
          filteredItems: filtered,
          selectedItem: selected,
          addedItemId: null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: SuccessStatus.error));
    }
  }

  void selectItemById(String? id) {
    if (id == null) {
      selectItem(null);
      return;
    }
    T? item;
    try {
      item = state.items.firstWhere((e) => e.uid == id);
    } catch (_) {
      try {
        item = repo.items.firstWhere((e) => e.uid == id);
      } catch (_) {
        item = null;
      }
    }

    if (item != null) {
      selectItem(item);
    } else {
      emit(state.copyWith(addedItemId: id));
    }
  }

  void search(String text) {
    final filtered = _applyFilters(
      state.items,
      searchText: text,
      selectedStatuses: state.selectedStatuses,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );
    final selected = _resolveSelected(selectedItem, filtered);
    selectedItem = selected;

    emit(
      state.copyWith(
        filteredItems: filtered,
        searchText: text,
        selectedItem: selected,
      ),
    );
  }

  void selectItem(T? item) {
    selectedItem = item;
    emit(state.copyWith(selectedItem: item));
  }

  void setStatusFilter(Set<String> statuses) {
    final normalizedStatuses = statuses.map((e) => e.trim()).toSet()
      ..removeWhere((e) => e.isEmpty);
    final filtered = _applyFilters(
      state.items,
      searchText: state.searchText,
      selectedStatuses: normalizedStatuses,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );
    final selected = _resolveSelected(selectedItem, filtered);
    selectedItem = selected;
    emit(
      state.copyWith(
        filteredItems: filtered,
        selectedStatuses: normalizedStatuses,
        selectedItem: selected,
      ),
    );
  }

  void setDateRange(DateTime? fromDate, DateTime? toDate) {
    DateTime? effectiveFrom = fromDate;
    DateTime? effectiveTo = toDate;

    if (effectiveFrom != null &&
        effectiveTo != null &&
        effectiveFrom.isAfter(effectiveTo)) {
      final temp = effectiveFrom;
      effectiveFrom = effectiveTo;
      effectiveTo = temp;
    }

    final filtered = _applyFilters(
      state.items,
      searchText: state.searchText,
      selectedStatuses: state.selectedStatuses,
      fromDate: effectiveFrom,
      toDate: effectiveTo,
    );
    final selected = _resolveSelected(selectedItem, filtered);
    selectedItem = selected;
    emit(
      state.copyWith(
        filteredItems: filtered,
        fromDate: effectiveFrom,
        toDate: effectiveTo,
        selectedItem: selected,
      ),
    );
  }

  void clearFilters() {
    final filtered = _applyFilters(
      state.items,
      searchText: '',
      selectedStatuses: const <String>{},
      fromDate: null,
      toDate: null,
    );
    emit(
      state.copyWith(
        filteredItems: filtered,
        searchText: '',
        selectedStatuses: const <String>{},
        fromDate: null,
        toDate: null,
        selectedItem: null,
      ),
    );
    selectedItem = null;
  }

  void clearSearch() {
    final filtered = _applyFilters(
      state.items,
      searchText: '',
      selectedStatuses: state.selectedStatuses,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );
    final selected = _resolveSelected(selectedItem, filtered);
    selectedItem = selected;
    emit(
      state.copyWith(
        filteredItems: filtered,
        searchText: '',
        selectedItem: selected,
      ),
    );
  }

  void _listenToFormCubit() {
    if (formCubit == null) return;
    _formSubscription = formCubit!.stream.listen((formState) {
      if (formState is FormInProgress) {
        emit(state.copyWith(status: SuccessStatus.waiting));
      } else if (formState is FormSuccess<T>) {
        if (formState.operation == FormOperation.delete) {
          if (state.selectedItem?.uid == formState.data.uid) {
            selectItem(null);
          }
        }
        emit(state.copyWith(status: SuccessStatus.success));
      } else if (formState is FormFailure) {
        emit(state.copyWith(status: SuccessStatus.success));
      } else if (formState is FormLoaded<T>) {
        emit(state.copyWith(status: SuccessStatus.success));
      } else if (formState is FromInitial) {
        emit(state.copyWith(status: SuccessStatus.success));
      }
    });
  }

  @override
  Future<void> close() {
    _repoSubscription?.cancel();
    _formSubscription?.cancel();
    return super.close();
  }
}
