part of 'section_cubit.dart';

class SectionState<T extends DataModel> extends Equatable {
  static const Object _unset = Object();
  final SuccessStatus? status;
  final List<T> items;
  final List<T> filteredItems;
  final T? selectedItem;
  final String searchText;
  final Set<String> selectedStatuses;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? addedItemId;
  final DateTime? lastUpdated;

  const SectionState({
    this.status,
    this.items = const [],
    this.filteredItems = const [],
    this.selectedItem,
    this.searchText = '',
    this.selectedStatuses = const <String>{},
    this.fromDate,
    this.toDate,
    this.addedItemId,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    status,
    items,
    filteredItems,
    selectedItem,
    searchText,
    selectedStatuses,
    fromDate,
    toDate,
    addedItemId,
    lastUpdated,
  ];

  SectionState<T> copyWith({
    SuccessStatus? status,
    List<T>? items,
    List<T>? filteredItems,
    Object? selectedItem = _unset,
    String? searchText,
    Set<String>? selectedStatuses,
    Object? fromDate = _unset,
    Object? toDate = _unset,
    Object? addedItemId = _unset,
    DateTime? lastUpdated,
  }) {
    return SectionState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedItem: identical(selectedItem, _unset)
          ? this.selectedItem
          : selectedItem as T?,
      searchText: searchText ?? this.searchText,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      fromDate: identical(fromDate, _unset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _unset) ? this.toDate : toDate as DateTime?,
      addedItemId: identical(addedItemId, _unset)
          ? this.addedItemId
          : addedItemId as String?,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
