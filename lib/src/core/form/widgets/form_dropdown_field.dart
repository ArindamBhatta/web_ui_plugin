import 'package:flutter/material.dart';
import 'package:web_ui_plugin/src/core/widgets/package_enums.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

class FormDropdownField<T extends DataModel> extends StatefulWidget {
  final String? labelText;
  final String? initialText;
  final String buttonText;
  final IconData? icon;
  final double? iconSize;
  final bool? enabled;
  final bool? mandatory;
  final bool keepTextVisible;
  final bool enableTextFieldTap;

  final List<T> items;
  final T? initialValue;

  final IconData? buttonIcon;
  final String dialogTitle;

  //If message is present, checkbox selection is disabled (read-only) and message is shown at dialog bottom.
  final String? dialogFooterMessage;
  final String? emptyStateMessage;
  final IconData? emptyStateIcon;

  final void Function(T?)? onChanged;
  final void Function(Map<String, String>?)? onSaved;

  final void Function(Map<String, dynamic>?)? onValueChanged; // extra

  final SortBy? sortBy;
  final SortOrder? sortOrder;
  late final String? Function(String?)? _validate;
  late final String? Function(T?)? _itemLabel;

  FormDropdownField({
    super.key,
    this.labelText,
    this.icon,
    this.iconSize,
    this.enabled = true,
    this.mandatory = true,
    this.initialText,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.onValueChanged,
    this.keepTextVisible = false,
    this.enableTextFieldTap = false,
    required this.buttonText,
    this.buttonIcon,
    required this.dialogTitle,
    this.dialogFooterMessage,
    this.emptyStateMessage,
    this.emptyStateIcon,
    this.onSaved,
    this.sortBy,
    this.sortOrder,
    String? Function(String?)? validate,
    String? Function(T?)? itemLabel,
  }) {
    _validate =
        validate ??
        ((value) {
          if (mandatory ?? true) {
            if (value == null || value.trim().isEmpty) {
              return '$labelText is required';
            } else {
              // print('Value for $labelText is valid: $value');
            }
          }
          return null;
        });
    _itemLabel = itemLabel ?? ((item) => item?.title ?? '');
  }

  @override
  State<FormDropdownField<T>> createState() => _FormDropdownFieldState<T>();
}

class _FormDropdownFieldState<T extends DataModel>
    extends State<FormDropdownField<T>> {
  late TextEditingController _controller;
  T? _selected;

  // Add a controller and a list for search
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _controller = TextEditingController(
      text:
          widget.initialText ??
          (_selected != null ? widget._itemLabel?.call(_selected as T) : ''),
    );
    _searchController = TextEditingController();
    _filteredItems = List<T>.from(widget.items);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  T? get selectedValue => _selected;

  void _openDropdownDialog(BuildContext context) {
    final blocContext = context;
    showDialog(
      context: blocContext,
      builder: (dialogContext) {
        T? selected = _selected;
        // Reset search when dialog opens
        _searchController.clear();
        _filteredItems = List<T>.from(widget.items);

        return CustomDialogBox(
          title: widget.dialogTitle,
          width: 200,
          child: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (innerContext, setState) {
                final bool isDialogReadOnly = (widget.dialogFooterMessage ?? '')
                    .trim()
                    .isNotEmpty;
                return Column(
                  children: [
                    if (widget.items.length > 5)
                      CustomizableSearchBar(
                        controller: _searchController,
                        onChanged: (query) {
                          setState(() {
                            _filteredItems = widget.items
                                .where(
                                  (item) =>
                                      (widget._itemLabel?.call(item) ?? '')
                                          .toLowerCase()
                                          .contains(query.toLowerCase()),
                                )
                                .toList();
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.emptyStateIcon ??
                                          Icons.inbox_outlined,
                                      size: 36,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (widget.emptyStateMessage ??
                                              'No items available.')
                                          .trim(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (ctx, index) {
                                final item = _filteredItems[index];
                                return CheckboxListTile(
                                  title: Text(
                                    widget._itemLabel?.call(item) ?? '',
                                  ),
                                  contentPadding: EdgeInsets.only(
                                    left: AppTheme.sidePadding,
                                    right: AppTheme.sidePadding / 2,
                                  ),
                                  value: selected == item,
                                  onChanged: isDialogReadOnly
                                      ? null
                                      : (checked) {
                                          if (checked == true) {
                                            setState(() {
                                              selected = item;
                                            });
                                            setState(() {
                                              _selected = item;
                                              _controller.text =
                                                  widget._itemLabel?.call(
                                                    item,
                                                  ) ??
                                                  '';
                                            });

                                            //* Call onValueChanged with the map
                                            if (widget.onValueChanged != null) {
                                              widget.onValueChanged!({
                                                'value':
                                                    widget._itemLabel?.call(
                                                      item,
                                                    ) ??
                                                    '',
                                                'id': item.uid,
                                              });
                                            }

                                            if (widget.onChanged != null) {
                                              widget.onChanged!(item);
                                            }
                                            Future.delayed(
                                              const Duration(milliseconds: 200),
                                              () {
                                                if (dialogContext.mounted) {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                }
                                              },
                                            );
                                          }
                                        },
                                );
                              },
                            ),
                    ),
                    if (isDialogReadOnly) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.dialogFooterMessage!.trim(),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _sort();
    // Always update filtered items when items change
    _filteredItems = List<T>.from(widget.items);
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
            enabled: (widget.enabled ?? true) || widget.keepTextVisible,
            onTap: widget.enableTextFieldTap
                ? () => _openDropdownDialog(context)
                : null,
            onSaved: (String? value) {
              widget.onSaved?.call({
                'value': value ?? '',
                'id': _selected?.uid ?? '',
              });
            },
            validator: widget._validate,
            mandatory: widget.mandatory ?? true,
          ),
        ),
        SizedBox(width: AppTheme.formFieldGap),
        CustomButton(
          buttonType: ButtonType.tertiary,
          text: widget.buttonText,
          icon: widget.buttonIcon ?? Icons.arrow_drop_down,
          iconSize: 24,
          buttonState: (widget.enabled == false)
              ? ButtonState.disabled
              : ButtonState.enabled,
          onPressed: widget.enabled == false
              ? null
              : () => _openDropdownDialog(context),
        ),
      ],
    );
  }

  void _sort() {
    if (widget.sortBy == SortBy.id) {
      widget.items.sort((a, b) => _compareIds(a.uid, b.uid));
    } else if (widget.sortBy == SortBy.name) {
      if (widget.sortOrder == SortOrder.descending) {
        widget.items.sort(
          (a, b) => (widget._itemLabel!(b) ?? '').toLowerCase().compareTo(
            (widget._itemLabel!(a) ?? '').toLowerCase(),
          ),
        );
      } else {
        widget.items.sort(
          (a, b) => (widget._itemLabel!(a) ?? '').toLowerCase().compareTo(
            (widget._itemLabel!(b) ?? '').toLowerCase(),
          ),
        );
      }
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
}
