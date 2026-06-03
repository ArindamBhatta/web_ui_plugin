import 'package:flutter/material.dart';
import 'package:web_ui_plugin/src/core/widgets/package_enums.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

class FormMultiSelectField<T extends DataModel> extends StatefulWidget {
  final String? labelText;
  final String? initialText;
  final String buttonText;
  final IconData? icon;
  final double? iconSize;
  final bool? enabled;
  final bool? mandatory;
  final bool keepTextVisible;

  final List<T> items;
  final List<T>? initialValues;

  final IconData? buttonIcon;
  final String dialogTitle;

  final void Function(List<T>?)? onChanged;
  final void Function(Map<String, String>?)? onSaved;

  final SortBy? sortBy;
  final SortOrder? sortOrder;
  final Set<String>? highlightedIds;
  final Color? highlightedTextColor;

  late final String? Function(String?)? validateFn;
  late final String Function(T?) itemLabelFn;

  FormMultiSelectField({
    super.key,
    this.labelText,
    this.icon,
    this.iconSize,
    this.enabled = true,
    this.mandatory = true,
    this.keepTextVisible = false,
    this.initialText,
    required this.items,
    this.initialValues,
    this.onChanged,
    required this.buttonText,
    this.buttonIcon,
    required this.dialogTitle,
    this.onSaved,
    this.sortBy,
    this.sortOrder,
    this.highlightedIds,
    this.highlightedTextColor,
    String? Function(String?)? validate,
    String Function(T?)? itemLabel,
  }) {
    validateFn =
        validate ??
        (mandatory ?? true
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$labelText is required';
                }
                return null;
              }
            : (_) => null);

    itemLabelFn = itemLabel ?? (item) => item?.title ?? '';
  }

  @override
  State<FormMultiSelectField<T>> createState() =>
      _FormMultiSelectFieldState<T>();
}

class _FormMultiSelectFieldState<T extends DataModel>
    extends State<FormMultiSelectField<T>> {
  late TextEditingController _controller;
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValues != null
        ? List<T>.from(widget.initialValues!)
        : [];

    _controller = TextEditingController(
      text: widget.initialText ?? _selectedText,
    );

    _sortItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------

  String get _selectedText => _selected
      .map((e) {
        final label = widget.itemLabelFn(e);
        return _isHighlighted(e) ? '$label (Cancelled)' : label;
      })
      .join(', ');

  bool _isHighlighted(T? item) {
    final id = item?.uid ?? '';
    if (id.isEmpty) return false;
    return widget.highlightedIds?.contains(id) == true;
  }

  void _sortItems() {
    if (widget.sortBy == SortBy.id) {
      widget.items.sort((a, b) => _compareIds(a.uid, b.uid));
    } else if (widget.sortBy == SortBy.name) {
      widget.items.sort((a, b) {
        final aLabel = widget.itemLabelFn(a).toLowerCase();
        final bLabel = widget.itemLabelFn(b).toLowerCase();

        return (widget.sortOrder == SortOrder.descending)
            ? bLabel.compareTo(aLabel)
            : aLabel.compareTo(bLabel);
      });
    }
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

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextField(
            readOnly: true,
            textController: _controller,
            labelText: widget.labelText ?? '',
            icon: widget.icon,
            iconSize: widget.iconSize ?? 20.0,
            //enable is default true.
            enabled: (widget.enabled ?? true) || widget.keepTextVisible,
            validator: widget.validateFn,
            textColor: _selected.any(_isHighlighted)
                ? (widget.highlightedTextColor ?? Colors.black)
                : null,
            onSaved: (String? value) {
              widget.onSaved?.call({
                "value": value ?? '',
                "ids": _selected.map((e) => e.uid).join(','),
              });
            },
            mandatory: widget.mandatory ?? true,
          ),
        ),
        SizedBox(width: AppTheme.formFieldGap),
        CustomButton(
          buttonType: ButtonType.tertiary,
          text: widget.buttonText,
          //change button state
          buttonState: (widget.enabled == false)
              ? ButtonState.disabled
              : ButtonState.enabled,
          icon: widget.buttonIcon ?? Icons.arrow_drop_down,
          onPressed: widget.enabled == false ? null : _openDialog,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Dialog
  // ----------------------------------------------------------

  void _openDialog() {
    final List<T> tempSelected = List<T>.from(_selected);
    final TextEditingController searchCtrl = TextEditingController();
    List<T> filtered = List<T>.from(widget.items);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return CustomDialogBox(
          title: widget.dialogTitle,
          width: 300,
          child: StatefulBuilder(
            builder: (innerCtx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // search bar
                  CustomizableSearchBar(
                    controller: searchCtrl,
                    onChanged: (query) {
                      setState(() {
                        filtered = widget.items
                            .where(
                              (item) => widget
                                  .itemLabelFn(item)
                                  .toLowerCase()
                                  .contains(query.toLowerCase()),
                            )
                            .toList();
                      });
                    },
                  ),

                  SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final label = widget.itemLabelFn(item);

                        return CheckboxListTile(
                          title: Text(
                            _isHighlighted(item) ? '$label (Cancelled)' : label,
                            style: _isHighlighted(item)
                                ? TextStyle(
                                    color:
                                        widget.highlightedTextColor ??
                                        Colors.red,
                                  )
                                : null,
                          ),
                          value: tempSelected.contains(item),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                tempSelected.add(item);
                              } else {
                                tempSelected.remove(item);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(AppTheme.sidePadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          text: "Cancel",
                          onPressed: () => Navigator.pop(dialogContext),
                          buttonType: ButtonType.tertiary,
                        ),
                        SizedBox(width: AppTheme.sidePadding),
                        CustomButton(
                          text: "OK",
                          buttonType: ButtonType.primary,
                          onPressed: () {
                            // Check if selection actually changed
                            final hasChanged =
                                tempSelected.length != _selected.length ||
                                !tempSelected.every(
                                  (item) => _selected.contains(item),
                                );

                            if (hasChanged) {
                              // Only update UI if there was a real change
                              setState(() {
                                _selected = List<T>.from(tempSelected);
                                _controller.text = _selectedText;
                              });

                              // Fire onChanged ONLY if there was a real change
                              widget.onChanged?.call(_selected);
                            }

                            Navigator.pop(dialogContext);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
