import 'package:flutter/material.dart';
import 'package:web_ui_plugin/src/core/contracts/data_model.dart';
import 'package:web_ui_plugin/src/core/widgets/package_enums.dart';

class PluginGridView extends StatefulWidget {
  final List<DataModel> data;
  final DataModel? selectedItem;
  final ValueChanged<DataModel> onItemTap;
  final Color sectionColor;
  final IconData sectionIcon;
  final String? Function(DataModel item)? statusKeyOf;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final String? defaultTitle;
  final String? defaultSubTitle;

  const PluginGridView({
    super.key,
    required this.data,
    required this.onItemTap,
    required this.selectedItem,
    required this.sectionColor,
    required this.sectionIcon,
    this.statusKeyOf,
    this.sortBy = SortBy.id,
    this.sortOrder = SortOrder.descending,
    this.defaultTitle,
    this.defaultSubTitle,
  });

  @override
  State<PluginGridView> createState() => _PluginGridViewState();
}

class _PluginGridViewState extends State<PluginGridView> {
  late List<DataModel> _sortedData;

  @override
  void initState() {
    super.initState();
    _sortedData = _computeSortedData();
  }

  @override
  void didUpdateWidget(covariant PluginGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.sortBy != oldWidget.sortBy ||
        widget.sortOrder != oldWidget.sortOrder) {
      _sortedData = _computeSortedData();
    }
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

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sortedData.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final dataItem = _sortedData[index];
        final isSelected = widget.selectedItem?.uid == dataItem.uid;
        final status = widget.statusKeyOf?.call(dataItem);

        return GridCardWidget(
          title: widget.defaultTitle ?? dataItem.title ?? 'No Title',
          subTitle: widget.defaultSubTitle ?? dataItem.subTitle ?? 'No Subtitle',
          isSelected: isSelected,
          status: status,
          sectionColor: widget.sectionColor,
          sectionIcon: widget.sectionIcon,
          onTap: () => widget.onItemTap(dataItem),
        );
      },
    );
  }
}

class GridCardWidget extends StatefulWidget {
  final String title;
  final String subTitle;
  final bool isSelected;
  final String? status;
  final Color sectionColor;
  final IconData sectionIcon;
  final VoidCallback onTap;

  const GridCardWidget({
    super.key,
    required this.title,
    required this.subTitle,
    required this.isSelected,
    required this.status,
    required this.sectionColor,
    required this.sectionIcon,
    required this.onTap,
  });

  @override
  State<GridCardWidget> createState() => _GridCardWidgetState();
}

class _GridCardWidgetState extends State<GridCardWidget> {
  bool _isHovered = false;

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final normalized = status.toLowerCase().trim();
    if (normalized == 'active' ||
        normalized == 'true' ||
        normalized == 'booked' ||
        normalized == 'workdone' ||
        normalized == 'available' ||
        normalized == 'yes') {
      return const Color(0xFF10B981); // Emerald
    }
    if (normalized == 'inactive' ||
        normalized == 'false' ||
        normalized == 'cancelled' ||
        normalized == 'no show' ||
        normalized == 'unavailable' ||
        normalized == 'no') {
      return const Color(0xFFF43F5E); // Rose
    }
    if (normalized == 'pending' ||
        normalized == 'work in progress' ||
        normalized == 'unsure') {
      return const Color(0xFFF59E0B); // Amber
    }
    return widget.sectionColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.status);
    final cardBorderColor = widget.isSelected
        ? widget.sectionColor
        : (_isHovered
            ? widget.sectionColor.withOpacity(0.5)
            : theme.colorScheme.outline.withOpacity(0.15));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -4, 0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardBorderColor,
              width: widget.isSelected ? 2 : 1.5,
            ),
            color: widget.isSelected
                ? widget.sectionColor.withOpacity(0.04)
                : (_isHovered
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainerLow),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.sectionColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: _isHovered ? const Offset(0, 6) : const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Premium glassmorphic background highlight
                if (widget.isSelected)
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.sectionColor.withOpacity(0.08),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Icon & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Section Icon inside a beautiful circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected
                                  ? widget.sectionColor.withOpacity(0.18)
                                  : widget.sectionColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              widget.sectionIcon,
                              size: 18,
                              color: widget.sectionColor,
                            ),
                          ),
                          // Status Badge if available
                          if (widget.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: statusColor.withOpacity(0.12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.status!.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),

                      // Title
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isSelected
                              ? widget.sectionColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        widget.subTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
                        ),
                      ),
                      
                      const Spacer(),

                      // Subtle interactive bottom indicator/action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Click to view',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _isHovered
                                  ? widget.sectionColor
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          AnimatedTranslation(
                            offset: _isHovered ? const Offset(2, 0) : Offset.zero,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: _isHovered
                                  ? widget.sectionColor
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A helper widget for simple offset transitions
class AnimatedTranslation extends StatelessWidget {
  final Offset offset;
  final Widget child;

  const AnimatedTranslation({
    super.key,
    required this.offset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
      child: child,
    );
  }
}
