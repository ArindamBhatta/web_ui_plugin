import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

/// Represents a column in the [CustomTabularView].
///
/// It allows developers to specify the column's [label], how to retrieve the
/// cell value via [valueMapper], custom sorting logic using [sortValueMapper],
/// and optional custom rendering via [customCellBuilder].
class TabularColumn<T> {
  final String label;
  final String Function(T item) valueMapper;
  final dynamic Function(T item)? sortValueMapper;
  final Widget Function(T item, BuildContext context)? customCellBuilder;

  const TabularColumn({
    required this.label,
    required this.valueMapper,
    this.sortValueMapper,
    this.customCellBuilder,
  });
}

/// A highly reusable, dynamic tabular view for any data model implementing [DataModel].
///
/// It encapsulates searching, automatic sorting, rendering a premium [DataTable],
/// showing/triggering modal Add/Edit forms (using [detailBuilder]), and handling deletion.
///
/// The developer only needs to specify the list of columns ([TabularColumn]),
/// a [repo] & [formCubit], and standard builders.
class CustomTabularView<T extends DataModel> extends StatefulWidget {
  final FormRepoMixin<T> repo;
  final FormCubit<T> formCubit;
  final String subSectionTitle;
  final List<TabularColumn<T>> columns;
  final Widget Function(T item, BuildContext context) detailBuilder;
  final T Function() createEmptyModel;
  final List<T> Function(List<T> items) filterFunction;
  final bool editable;
  final ValueChanged<T>? onRowTap;
  final List<Stream>? additionalStreams;

  const CustomTabularView({
    super.key,
    required this.repo,
    required this.formCubit,
    required this.subSectionTitle,
    required this.columns,
    required this.detailBuilder,
    required this.createEmptyModel,
    required this.filterFunction,
    this.editable = true,
    this.onRowTap,
    this.additionalStreams,
  });

  @override
  State<CustomTabularView<T>> createState() => _CustomTabularViewState<T>();
}

class _CustomTabularViewState<T extends DataModel>
    extends State<CustomTabularView<T>> {
  int? _sortColumnIndex = 0;
  bool _sortAscending = true;

  SectionCubit<T>? cubit;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final List<StreamSubscription> _additionalSubscriptions = [];

  @override
  void initState() {
    super.initState();
    cubit = SectionCubit<T>(repo: widget.repo, formCubit: widget.formCubit);
    cubit?.loadAll();

    if (widget.additionalStreams != null) {
      for (final stream in widget.additionalStreams!) {
        _additionalSubscriptions.add(
          stream.listen((_) {
            if (mounted) setState(() {});
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    for (final sub in _additionalSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _showAddDialog(T data) {
    String dialogTitle =
        '${data.uid.isNotEmpty ? "Edit" : "Add New"} ${widget.subSectionTitle}';
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        return BlocProvider.value(
          value: widget.formCubit,
          child: Builder(
            builder: (dialogContentCtx) {
              final detail = widget.detailBuilder(data, dialogContentCtx);
              final dialogChild = detail is FormPageView
                  ? FormPageView(
                      key: detail.key,
                      formCubit: detail.formCubit,
                      dataModel: detail.dataModel,
                      fields: detail.fields,
                      rebuildDataModel: detail.rebuildDataModel,
                      actionButtons: detail.actionButtons,
                      primaryButtonText: detail.primaryButtonText,
                      cancelButtonText: detail.cancelButtonText,
                      snackBarEntityName: detail.snackBarEntityName,
                      onSaveSuccess: () {
                        detail.onSaveSuccess?.call();
                        Navigator.of(ctx).pop();
                      },
                      onCancel: () {
                        if (detail.onCancel != null) {
                          detail.onCancel!.call();
                        } else {
                          Navigator.of(ctx).pop();
                        }
                      },
                    )
                  : detail;

              return CustomDialogBox(
                title: dialogTitle,
                width: 600,
                height: 450,
                child: dialogChild,
              );
            },
          ),
        );
      },
    ).then((_) {
      cubit?.clearSearch();
      _searchController.clear();
      cubit?.loadAll();
    });
  }

  void _showDeleteConfirmDialog(T item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CustomDialogBox(
          title: 'Confirm Deletion',
          width: 400,
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Are you sure you want to delete this ${widget.subSectionTitle.toLowerCase()} item?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Cancel',
                      buttonType: ButtonType.tertiary,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Delete',
                      buttonType: ButtonType.primary,
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await widget.formCubit.deleteItem(item);
                          if (mounted) {
                            CustomSnackBar.show(
                              context,
                              'Item deleted successfully.',
                              category: SnackBarCategory.success,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackBar.show(
                              context,
                              'Failed to delete item: $e',
                              category: SnackBarCategory.failure,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      cubit?.loadAll();
    });
  }

  List<DataColumn> getColumns() {
    final list = widget.columns.map<DataColumn>((col) {
      return DataColumn(
        label: Text(
          col.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortAscending = ascending;
          });
        },
      );
    }).toList();

    if (widget.editable) {
      list.add(
        DataColumn(
          label: Text(
            'Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    return list;
  }

  List<DataRow> getRows(List<T> sortedItems) {
    return sortedItems.asMap().entries.map<DataRow>((entry) {
      final index = entry.key;
      final item = entry.value;

      final cells = widget.columns.map<DataCell>((col) {
        final child = col.customCellBuilder != null
            ? col.customCellBuilder!(item, context)
            : Text(col.valueMapper(item));
        return DataCell(
          child,
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
        );
      }).toList();

      if (widget.editable) {
        cells.add(
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _showAddDialog(item),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _showDeleteConfirmDialog(item),
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),
        );
      }

      final isEven = index % 2 == 0;
      final baseColor = isEven
          ? Colors.transparent
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.015);

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05);
          }
          return baseColor;
        }),
        cells: cells,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit!,
      child: BlocBuilder<SectionCubit<T>, SectionState<T>>(
        builder: (context, state) {
          if (state.status == SuccessStatus.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state.status == SuccessStatus.error) {
            return Center(
              child: Text(
                'Error loading ${widget.subSectionTitle}. Please try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          final List<T> filteredItems = widget.filterFunction(
            state.filteredItems,
          );

          // Apply client-side sorting
          final sortedItems = List<T>.from(filteredItems);
          if (_sortColumnIndex != null &&
              _sortColumnIndex! < widget.columns.length) {
            final col = widget.columns[_sortColumnIndex!];
            sortedItems.sort((left, right) {
              final leftMapper = col.sortValueMapper ?? col.valueMapper;
              final rightMapper = col.sortValueMapper ?? col.valueMapper;
              final leftVal = leftMapper(left);
              final rightVal = rightMapper(right);

              int result;
              if (leftVal is Comparable && rightVal is Comparable) {
                result = leftVal.compareTo(rightVal);
              } else {
                result = leftVal.toString().compareTo(rightVal.toString());
              }
              return _sortAscending ? result : -result;
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: sortedItems.isNotEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScrollController,
                                child: Scrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    controller: _verticalScrollController,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerTheme: DividerThemeData(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth:
                                              constraints.maxWidth -
                                              2, // Account for border width
                                        ),
                                        child: DataTable(
                                          columnSpacing: 32,
                                          horizontalMargin: 24,
                                          headingRowColor:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((Set<WidgetState> states) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.05);
                                              }),
                                          headingTextStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontSize: 14,
                                          ),
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _sortAscending,
                                          columns: getColumns(),
                                          rows: getRows(sortedItems),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : NoDataView(
                            title: 'No ${widget.subSectionTitle} Found',
                            subtitle: state.items.isEmpty
                                ? 'Start adding ${widget.subSectionTitle.toLowerCase()}.'
                                : 'No matching ${widget.subSectionTitle.toLowerCase()} found.',
                            icon: Icons.search_outlined,
                            iconColor: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppTheme.sidePadding),
                    child: Row(
                      children: [
                        if (state.items.isNotEmpty)
                          Expanded(
                            child: CustomizableSearchBar(
                              controller: _searchController,
                              onChanged: (value) {
                                cubit!.search(value);
                              },
                            ),
                          ),
                        if (state.items.isNotEmpty && widget.editable)
                          const SizedBox(width: 12),
                        if (widget.editable)
                          CustomButton(
                            text: 'Add ${widget.subSectionTitle}',
                            buttonType: ButtonType.secondary,
                            height: AppTheme.formButtonHeight - 6,
                            icon: Icons.add,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                            onPressed: () {
                              _showAddDialog(widget.createEmptyModel());
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
