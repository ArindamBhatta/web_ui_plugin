import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_ui_plugins/src/core/form/repo/form_repo_mixin.dart';
import 'package:web_ui_plugins/src/core/widgets/package_enums.dart';

import 'package:web_ui_plugins/src/core/contracts/data_model.dart';

part 'section_state.dart';

class SectionCubit<T extends DataModel> extends Cubit<SectionState<T>> {
  // Tracks whether the currently active form has unsaved edits.
  static bool hasUnsavedFormChanges = false;

  //1st take repo instance
  final FormRepoMixin<T> repo;

  //3rd take optional functions to extract status and date from items for filtering
  final String? Function(T item)? statusKeyOf;

  //4th take optional function to extract date from item for date range filtering
  final DateTime? Function(T item)? dateOf;

  // Internal stream and subscription to listen to repo changes
  late Stream<(List<T>, String?)> _repoStream;

  // Keep track of the currently selected item to try to maintain selection across updates
  late StreamSubscription<(List<T>, String?)>? _repoSubscription;

  // Expose selectedItem for external access if needed
  T? selectedItem;

  SectionCubit({
    required this.repo,
    this.statusKeyOf,
    this.dateOf,

    // App States eg Pending, Completed
    Set<String> initialSelectedStatuses = const <String>{},

    //? The Requirement: A Cubit must have an initial state the moment it is created. It cannot exist in a "null" state. By calling super(...), we are passing the initial state to the underlying Bloc library.
  }) : super(
         SectionState<T>(
           selectedStatuses: initialSelectedStatuses
               .map((e) => e.trim())
               .where((e) => e.isNotEmpty)
               .toSet(),
         ),
       ) {
    _listenToRepo();
  }

  // It subscribes to a Stream from the repo . Whenever the database or API updates, the Cubit automatically receives the new list, applies the current filters (search text, dates), and emits a new state
  void _listenToRepo() {
    _repoStream = repo.dataStream;

    _repoSubscription = _repoStream.listen((data) {
      final items = data.$1;
      final addedItemId = data.$2;

      // If an item was just added, try to select it by addedItemId
      T? selected;
      String? newAddedItemId = addedItemId ?? state.addedItemId;

      try {
        selected = items.cast<T?>().firstWhere(
          (item) => item?.uid == newAddedItemId,
          orElse: () => null,
        );
        selectedItem = selected;
      } catch (_) {
        selected = null;
      }

      final filtered = _applyFilters(
        items,
        searchText: state.searchText,
        selectedStatuses: state.selectedStatuses,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      final nextSelected = _resolveSelected(selected ?? selectedItem, filtered);

      final newState = state.copyWith(
        items: items,
        filteredItems: filtered,
        selectedItem: nextSelected,
        addedItemId: addedItemId, // update addedItemId in state
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
      final selected = _resolveSelected(selectedItem, filtered);
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

  @override
  Future<void> close() {
    _repoSubscription?.cancel();
    return super.close();
  }
}
