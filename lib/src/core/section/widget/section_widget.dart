import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

// Cubit for Section UI state

// Section widget
class SectionWidget<T extends DataModel> extends StatefulWidget {
  final String sectionLabel;
  final IconData sectionIcon;
  final Color sectionColor;
  final String sectionTitle;
  final FormRepoMixin<T> repo;
  final FormCubit<T> formCubit;
  final Widget Function(T item, BuildContext context) initialTabDetailBuilder;
  // Optional functions to extract status
  final String? Function(T item)? statusKeyOf;
  final DateTime? Function(T item)? dateOf;

  final List<Widget> Function(BuildContext context, T item)? headerLeftWidgets;
  final List<Widget> Function(BuildContext context, T item)? headerRightWidgets;
  final List<CustomButton> Function(BuildContext context, T item)?
  footerActionButtons;

  final List<String> Function(T item)?
  filterExtraTabs; //use filterExtraTabs: (TT) => ["XYZ"]
  final List<Widget Function(String itemId)> Function(T item)?
  extraTabViewsBuilder; //use extraTabViewsBuilder: (TT) => [(itemId) => PlaceHolder()]

  final T Function() createEmptyModel;
  final DataModel Function(Map<String, dynamic> data) rebuildDataModel;
  final String? initialSelectedItemId;
  final bool showAddButton;
  final Set<String> initialSelectedStatuses;
  final String firstTabLabel;
  final SectionLayoutMode defaultLayoutMode;

  const SectionWidget({
    super.key,
    required this.sectionLabel,
    required this.sectionIcon,
    required this.sectionColor,
    required this.repo,
    required this.formCubit,
    required this.sectionTitle,
    required this.initialTabDetailBuilder,
    this.statusKeyOf,
    this.dateOf,
    this.headerLeftWidgets,
    this.headerRightWidgets,
    this.footerActionButtons,
    required this.createEmptyModel,
    required this.rebuildDataModel,
    this.filterExtraTabs,
    this.extraTabViewsBuilder,
    this.initialSelectedItemId,
    this.showAddButton = true,
    this.initialSelectedStatuses = const <String>{},
    this.firstTabLabel = 'Details',
    this.defaultLayoutMode = SectionLayoutMode.list,
  });

  @override
  State<SectionWidget<T>> createState() => _SectionState<T>();
}

class _SectionState<T extends DataModel> extends State<SectionWidget<T>> {
  late final SectionCubit<T> cubit;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _leftPaneKey = GlobalKey();
  double _headerLeftActionsInset = 0;
  bool _mobileViewingDetail = false;
  late SectionLayoutMode _layoutMode;

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.defaultLayoutMode;
    if (widget.initialSelectedItemId != null) {
      _mobileViewingDetail = true;
    }
    cubit = SectionCubit<T>(
      repo: widget.repo,
      formCubit: widget.formCubit,
      statusKeyOf: widget.statusKeyOf,
      dateOf: widget.dateOf,
      initialSelectedStatuses: widget.initialSelectedStatuses,
      initialSelectedItemId: widget.initialSelectedItemId,
    );
    cubit.loadAll();
  }

  @override
  void didUpdateWidget(covariant SectionWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedItemId != widget.initialSelectedItemId) {
      cubit.selectItemById(widget.initialSelectedItemId);
      if (widget.initialSelectedItemId != null) {
        setState(() => _mobileViewingDetail = true);
      } else {
        setState(() => _mobileViewingDetail = false);
      }
    }
  }

  String _getBasePath(BuildContext context) {
    try {
      final state = GoRouterState.of(context);
      final segments = state.uri.pathSegments;
      if (segments.isEmpty) return '/';
      return '/${segments.first}';
    } catch (e, stack) {
      debugPrint('Error in _getBasePath: $e\n$stack');
      return '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _titleAnchorWidth(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500);
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.sectionLabel.toUpperCase(),
        style: titleStyle,
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    return 24 + AppTheme.sidePadding + textPainter.width + AppTheme.sidePadding;
  }

  void _scheduleHeaderInsetMeasurement(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _leftPaneKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox) return;

      final leftPaneWidth = renderObject.size.width;
      final desiredInset = (leftPaneWidth - _titleAnchorWidth(context)).clamp(
        0.0,
        double.infinity,
      );

      if ((desiredInset - _headerLeftActionsInset).abs() > 0.5) {
        setState(() {
          _headerLeftActionsInset = desiredInset;
        });
      }
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final emptyModel = widget.createEmptyModel();
        final initialDetail = widget.initialTabDetailBuilder(
          emptyModel,
          context,
        );
        final initialFormPage = initialDetail is FormPageView
            ? initialDetail
            : null;

        return BlocProvider.value(
          value: widget.formCubit,
          child: CustomDialogBox(
            title: 'Add New ${widget.sectionTitle}',
            width: 600,
            height: 450,
            child: FormPageView(
              key: ValueKey('new_${widget.sectionTitle}'),
              formCubit: widget.formCubit,
              dataModel: emptyModel,
              fields: initialFormPage?.fields ?? [],
              rebuildDataModel: widget.rebuildDataModel,
              primaryButtonText: initialFormPage?.primaryButtonText ?? "Add",
              snackBarEntityName:
                  initialFormPage?.snackBarEntityName ??
                  (widget.sectionTitle.endsWith('s')
                      ? widget.sectionTitle.substring(
                          0,
                          widget.sectionTitle.length - 1,
                        )
                      : widget.sectionTitle),
              onSaveSuccess: () {
                Navigator.of(ctx).pop();
              },
              onCancel: () {
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    ).then((_) {
      cubit.clearSearch();
      _searchController.clear();
      cubit.loadAll();
    });
  }

  void _mobileGoBackToList() {
    setState(() => _mobileViewingDetail = false);
  }

  Widget _buildMobileDetailView(BuildContext context, T selected) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _mobileGoBackToList();
      },
      child: Column(
        children: [
          Container(
            height: AppTheme.topBarHeight,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: EdgeInsets.only(right: AppTheme.sidePadding / 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _mobileGoBackToList,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Text(
                      selected.title ?? widget.sectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 1, height: 1),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SubSectionView(
                dataModel: selected,
                footerActionButtons:
                    widget.footerActionButtons?.call(context, selected) ??
                    const [],
                tabs: [
                  Tab(text: widget.firstTabLabel),
                  ...(widget.filterExtraTabs?.call(selected) ??
                          const <String>[])
                      .map((tabTitle) => Tab(text: tabTitle)),
                ],
                tabViews: [
                  widget.initialTabDetailBuilder(selected, context),
                  ...(widget.extraTabViewsBuilder?.call(selected) ??
                          const <Widget Function(String itemId)>[])
                      .map((builder) => builder(selected.uid)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<SectionCubit<T>, SectionState<T>>(
        listener: (context, state) {
          final selectedUid = state.selectedItem?.uid;
          final basePath = _getBasePath(context);
          if (basePath.isNotEmpty) {
            if (selectedUid == null && state.addedItemId != null) {
              return;
            }
            final GoRouterState routerState = GoRouterState.of(context);
            final currentPath = routerState.uri.path;
            final expectedPath = selectedUid != null ? '$basePath/$selectedUid' : basePath;
            if (currentPath != expectedPath) {
              context.go(expectedPath);
            }
          }
          final bool isMobile = MediaQuery.of(context).size.width < 900;
          if (state.selectedItem == null && _mobileViewingDetail) {
            setState(() => _mobileViewingDetail = false);
          } else if (state.selectedItem != null && isMobile && !_mobileViewingDetail) {
            setState(() => _mobileViewingDetail = true);
          }
        },
        builder: (context, state) {
          final bool isWaiting = state.status == SuccessStatus.waiting;
          final bool hasItems = state.items.isNotEmpty;

          if (state.status == SuccessStatus.error) {
            return Center(
              child: Text(
                'Error loading ${widget.sectionTitle}. Please try again.',

                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          // On mobile: show the detail view as a full-screen replacement
          if (isMobile && _mobileViewingDetail && state.selectedItem != null) {
            return _buildMobileDetailView(context, state.selectedItem!);
          }

          final headerAnchorItem =
              state.selectedItem ??
              (state.filteredItems.isNotEmpty
                  ? state.filteredItems.first
                  : (state.items.isNotEmpty ? state.items.first : null));
          final headerLeftItems =
              headerAnchorItem != null && widget.headerLeftWidgets != null
              ? widget.headerLeftWidgets!.call(context, headerAnchorItem)
              : const <Widget>[];
          final headerRightItems =
              headerAnchorItem != null && widget.headerRightWidgets != null
              ? widget.headerRightWidgets!.call(context, headerAnchorItem)
              : const <Widget>[];
          final List<Widget> leftSectionActions = <Widget>[...headerLeftItems];
          final List<Widget> rightSectionActions = <Widget>[
            ...headerRightItems,
            if (widget.showAddButton)
              CustomButton(
                text: 'Add ${widget.sectionTitle}',
                buttonType: ButtonType.secondary,
                height: AppTheme.formButtonHeight - 6,
                icon: Icons.add,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                onPressed: _showAddDialog,
              ),
          ];

          if (!isMobile && hasItems && leftSectionActions.isNotEmpty) {
            _scheduleHeaderInsetMeasurement(context);
          }

          // Shared list pane used in both mobile and desktop layouts
          final Widget listPane = Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomizableSearchBar(
                      controller: _searchController,
                      onChanged: (value) {
                        cubit.search(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _layoutMode == SectionLayoutMode.list
                        ? 'Switch to Grid View'
                        : 'Switch to List View',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _layoutMode = _layoutMode == SectionLayoutMode.list
                              ? SectionLayoutMode.grid
                              : SectionLayoutMode.list;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: AppTheme.formFieldHeight - 8,
                        height: AppTheme.formFieldHeight - 8,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          _layoutMode == SectionLayoutMode.list
                              ? Icons.grid_view_rounded
                              : Icons.list_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: state.filteredItems.isNotEmpty
                    ? (_layoutMode == SectionLayoutMode.list
                          ? CustomListView(
                              data: state.filteredItems,
                              selectedItem: state.selectedItem,
                              onItemTap: (item) {
                                final tappedItem = item as T;
                                final selectedUid = state.selectedItem?.uid;

                                if (selectedUid != tappedItem.uid) {
                                  if (SectionCubit.hasUnsavedFormChanges) {
                                    CustomSnackBar.show(
                                      context,
                                      'You have unsaved changes. Changes were discarded when switching item.',
                                      category: SnackBarCategory.warning,
                                    );
                                    SectionCubit.hasUnsavedFormChanges = false;
                                  }
                                  cubit.selectItem(tappedItem);
                                }

                                if (isMobile) {
                                  setState(() => _mobileViewingDetail = true);
                                }
                              },
                            )
                          : PluginGridView(
                              data: state.filteredItems,
                              selectedItem: state.selectedItem,
                              sectionColor: widget.sectionColor,
                              sectionIcon: widget.sectionIcon,
                              statusKeyOf: widget.statusKeyOf != null
                                  ? (item) => widget.statusKeyOf!(item as T)
                                  : null,
                              onItemTap: (item) {
                                final tappedItem = item as T;
                                final selectedUid = state.selectedItem?.uid;

                                if (selectedUid != tappedItem.uid) {
                                  if (SectionCubit.hasUnsavedFormChanges) {
                                    CustomSnackBar.show(
                                      context,
                                      'You have unsaved changes. Changes were discarded when switching item.',
                                      category: SnackBarCategory.warning,
                                    );
                                    SectionCubit.hasUnsavedFormChanges = false;
                                  }
                                  cubit.selectItem(tappedItem);
                                }

                                if (isMobile) {
                                  setState(() => _mobileViewingDetail = true);
                                }
                              },
                            ))
                    : NoDataView(
                        title: 'No ${widget.sectionTitle} Found',
                        subtitle:
                            'No matching ${widget.sectionTitle.toLowerCase()} found.',
                        icon: Icons.search_outlined,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ],
          );

          final Widget sectionBody;

          if (!hasItems) {
            sectionBody = isWaiting
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : NoDataView(
                    title: 'No ${widget.sectionTitle} Information',
                    subtitle:
                        'Start adding ${widget.sectionTitle.toLowerCase()}.',
                    icon: Icons.search_outlined,
                    iconColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                  );
          } else if (isMobile) {
            // Mobile: list fills the full width
            sectionBody = Stack(
              children: [
                AbsorbPointer(absorbing: isWaiting, child: listPane),
                if (isWaiting)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.45),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            // Desktop: side-by-side list and detail panes
            sectionBody = Stack(
              children: [
                AbsorbPointer(
                  absorbing: isWaiting,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(key: _leftPaneKey, child: listPane),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 3,
                        child: Builder(
                          builder: (context) {
                            final selected = state.selectedItem;

                            return selected != null
                                ? SubSectionView(
                                    dataModel: selected,
                                    footerActionButtons:
                                        widget.footerActionButtons?.call(
                                          context,
                                          selected,
                                        ) ??
                                        const [],
                                    tabs: [
                                      Tab(text: widget.firstTabLabel),
                                      ...(widget.filterExtraTabs?.call(
                                                selected,
                                              ) ??
                                              const <String>[])
                                          .map(
                                            (tabTitle) => Tab(text: tabTitle),
                                          ),
                                    ],
                                    tabViews: [
                                      widget.initialTabDetailBuilder(
                                        selected,
                                        context,
                                      ),
                                      ...(widget.extraTabViewsBuilder?.call(
                                                selected,
                                              ) ??
                                              const <Widget Function(String)>[])
                                          .map(
                                            (builder) => builder(selected.uid),
                                          ),
                                    ],
                                  )
                                : NoDataView(
                                    title:
                                        'No ${widget.sectionTitle} Information',
                                    subtitle:
                                        'Please select ${widget.sectionTitle.toLowerCase()} to view details.',
                                    icon: widget.sectionIcon,
                                    iconColor: widget.sectionColor,
                                  );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (isWaiting)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.45),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return SectionView(
            sectionLabel: widget.sectionLabel,
            sectionIcon: widget.sectionIcon,
            sectionColor: widget.sectionColor,
            headerLeftActions: leftSectionActions.isEmpty
                ? null
                : leftSectionActions,
            headerRightActions: rightSectionActions.isEmpty
                ? null
                : rightSectionActions,
            headerLeftActionsInset: _headerLeftActionsInset,
            child: sectionBody,
          );
        },
      ),
    );
  }
}
