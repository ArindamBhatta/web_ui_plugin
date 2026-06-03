import 'package:flutter/material.dart';
import 'package:web_ui_plugin/src/core/list_with_form_section/widget/custom_list_tile.dart';
import 'package:web_ui_plugin/src/core/widgets/package_enums.dart';
import 'package:web_ui_plugin/src/core/contracts/data_model.dart';

class CustomListView extends StatefulWidget {
  final List<DataModel> data;
  final DataModel? selectedItem;
  final ValueChanged<DataModel> onItemTap;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final String? defaultTitle;
  final String? defaultSubTitle;

  const CustomListView({
    super.key,
    required this.data,
    required this.onItemTap,
    required this.selectedItem,
    this.sortBy = SortBy.id,
    this.sortOrder = SortOrder.descending,
    this.defaultTitle,
    this.defaultSubTitle,
  });

  @override
  State<CustomListView> createState() => _CustomListViewState();
}

class _CustomListViewState extends State<CustomListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Animation<double>? _barAnimation;
  double _barOffset = 0;
  double _scrollOffset = 0;
  int? _currentSelectedIndex;
  late List<DataModel> _sortedData;

  static const double _itemHeight = 50;
  static const double _dividerHeight = 1;
  static const double _totalItemHeight = _itemHeight + _dividerHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      if (_barAnimation != null) {
        setState(() {
          _barOffset = _barAnimation!.value;
        });
      }
    });
    _sortedData = _computeSortedData();
    final index = _findSelectedIndex(_sortedData);
    if (index != null) {
      _barOffset = index * _totalItemHeight;
      _currentSelectedIndex = index;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<DataModel> _computeSortedData() {
    final data = List<DataModel>.from(widget.data);
    data.sort((a, b) {
      switch (widget.sortBy) {
        case SortBy.name:
          return a.title?.compareTo(b.title ?? '') ?? 0;
        case SortBy.id:
          return _compareIds(a.uid, b.uid);
      }
    });
    if (widget.sortOrder == SortOrder.descending) {
      return data.reversed.toList();
    }
    return data;
  }

  int _compareIds(String? a, String? b) {
    final aId = a ?? '';
    final bId = b ?? '';
    final aAsNum = int.tryParse(aId);
    final bAsNum = int.tryParse(bId);

    if (aAsNum != null && bAsNum != null) {
      return aAsNum.compareTo(bAsNum);
    }

    return aId.toLowerCase().compareTo(bId.toLowerCase());
  }

  int? _findSelectedIndex(List<DataModel> sortedData) {
    if (widget.selectedItem == null) return null;
    final index = sortedData.indexOf(widget.selectedItem!);
    return index == -1 ? null : index;
  }

  void _animateToIndex(int newIndex) {
    final double newOffset = newIndex * _totalItemHeight;
    if (_currentSelectedIndex == null) {
      _barOffset = newOffset;
      _currentSelectedIndex = newIndex;
    } else if (newIndex != _currentSelectedIndex) {
      _barAnimation = Tween<double>(begin: _barOffset, end: newOffset).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _currentSelectedIndex = newIndex;
      _animationController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant CustomListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.sortBy != oldWidget.sortBy ||
        widget.sortOrder != oldWidget.sortOrder) {
      _sortedData = _computeSortedData();
    }
    final newIndex = _findSelectedIndex(_sortedData);
    if (newIndex == null) {
      _currentSelectedIndex = null;
    } else {
      _animateToIndex(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        setState(() {
          _scrollOffset = notification.metrics.pixels;
        });
        return false;
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ListView.separated(
            itemCount: _sortedData.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, index) {
              final DataModel dataItem = _sortedData[index];
              return InkWell(
                onTap: () {
                  widget.onItemTap(dataItem);
                },
                child: CustomizableListTile(
                  title: widget.defaultTitle ?? dataItem.title ?? 'No Title',
                  subTitle:
                      widget.defaultSubTitle ??
                      dataItem.subTitle ??
                      'No Subtitle',
                  isSelected: widget.selectedItem == dataItem,
                ),
              );
            },
          ),
          if (_currentSelectedIndex != null)
            Positioned(
              left: 0,
              top: _barOffset - _scrollOffset,
              child: IgnorePointer(
                child: Container(
                  width: 3,
                  height: _itemHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
