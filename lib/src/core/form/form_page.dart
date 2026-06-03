import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

enum FieldType {
  status,
  general,
  name,
  address,
  mobileNumber,
  whatsapp,
  email,
  password,
  age,
  dropdown,
  date,
  time,
  multiSelect,
  amount,
}

class FormPageView extends StatefulWidget {
  final FormCubit formCubit;
  final DataModel dataModel;

  // Api for create UI widgets
  final List<WidgetConfig> fields;
  // Api for converting form data back to DataModel for saving
  final DataModel Function(Map<String, dynamic> data) rebuildDataModel;

  final List<CustomButton> actionButtons;
  final String? primaryButtonText;
  final String? cancelButtonText;
  final VoidCallback? onCancel;
  final VoidCallback? onSaveSuccess;
  final bool supportsCrud;

  final String? snackBarEntityName;

  const FormPageView({
    super.key,
    required this.formCubit,
    required this.dataModel,
    required this.fields,
    required this.rebuildDataModel,
    this.actionButtons = const [],
    this.primaryButtonText,
    this.cancelButtonText,
    this.onCancel,
    this.onSaveSuccess,
    this.supportsCrud = true,
    this.snackBarEntityName,
  });

  @override
  State<FormPageView> createState() => _FormPageViewState();
}

class _FormPageViewState extends State<FormPageView> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _keyboardFocusNode = FocusNode();

  ///for checking different we compare original data with clone data and a flag track data mismatch .
  //1. mutable, current user edits
  //2. key is field name, value can string, List<string> so we use dynamic
  final Map<String, dynamic> _formData = {};

  //immutable baseline snapshot for dirty-check
  final Map<String, dynamic> _cloneFormData = {};

  bool _isDataMismatch = false;

  /// This version number is used to force rebuild of form fields when we reset the form to initial snapshot. Whenever we reset form, we increment this version, and include it in the keys of form fields. This way, when we reset form, all keys change, and all form fields are rebuilt with initial values.
  int _formResetVersion = 0;

  void _showUnsavedChangesLostSnackBar() {
    CustomSnackBar.show(
      context,
      "You lost some unsaved changes by navigating out of this page.",
      category: SnackBarCategory.warning,
    );
  }

  //Only helps widget rebuild keys for FormDateField and FormMultiSelectField It forces those widgets to re-initialize when initial data changes. It does not decide save enabled/disabled directly.
  String _fieldFingerprint(WidgetConfig field) {
    if (field is ListingWidgetConfig) {
      return '${field.key}:${field.initialData?.uid ?? ''}';
    }
    if (field is MultiSelectWidgetConfig) {
      final ids = field.initialDataSet?.map((e) => e.uid).join(',') ?? '';
      return '${field.key}:$ids';
    }
    return '${field.key}:${field.initialValue ?? ''}'; //status:Work In Progress
  }

  // Initialize form data with initial values
  void _initializeFormData() {
    // Clear existing data before initializing to avoid stale data issues when switching between different data models. This ensures that _formData and _cloneFormData always accurately reflect the current form's initial state.
    _formData.clear();
    _cloneFormData.clear();

    for (final WidgetConfig field in widget.fields) {
      final String key = field.key;
      final String? initialValue = field.initialValue;
      _formData[key] = initialValue;
      _cloneFormData[key] = initialValue;
    }

    _formData['id'] = widget.dataModel.uid;
    _cloneFormData['id'] = widget.dataModel.uid;
    //  debugPrint('------ --- Initialized form data: $_formData');

    //--- Handle ListingWidgetConfig initial data
    for (final WidgetConfig field in widget.fields) {
      if (field is ListingWidgetConfig) {
        final String key = field.key;
        _formData[key] = field.initialData?.title;
        _formData['${key}Id'] = field.initialData?.uid;

        _cloneFormData[key] = field.initialData?.title;
        _cloneFormData['${key}Id'] = field.initialData?.uid;
      }
    }
    // debugPrint('------ --- After handling ListingWidgetConfig initial data: $_formData');

    // Handle MultiSelectWidgetConfig initial data
    for (final WidgetConfig field in widget.fields) {
      if (field is MultiSelectWidgetConfig) {
        final String key = field.key;
        final initialIds =
            field.initialDataSet?.map((e) => e.uid).toList() ?? [];
        final initialNames =
            field.initialDataSet?.map((e) => e.title ?? '').join(', ') ?? '';
        _formData['${key}Id'] = initialIds;
        _formData[key] = initialNames;
        _cloneFormData['${key}Id'] = initialIds;
        _cloneFormData[key] = initialNames;
      }
    }

    _isDataMismatch = false;
    SectionCubit.hasUnsavedFormChanges = false;
  }

  dynamic _cloneValue(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return value;
  }

  void _resetToInitialSnapshot() {
    _formKey.currentState?.reset();
    _formData
      ..clear()
      ..addEntries(
        _cloneFormData.entries.map(
          (entry) => MapEntry(entry.key, _cloneValue(entry.value)),
        ),
      );
    _isDataMismatch = false;
    SectionCubit.hasUnsavedFormChanges = false;
    _formResetVersion++;
    setState(() {});
    CustomSnackBar.show(
      context,
      'Form has been reset to initial values.',
      category: SnackBarCategory.info,
    );
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    final isAltKey =
        event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight;

    if (isAltKey && mounted) {
      setState(() {});
    }

    return false;
  }

  KeyEventResult _onFormKeyEvent(FocusNode node, KeyEvent event) {
    return KeyEventResult.ignored;
  }

  dynamic _normalizeForDirtyCheck(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FormPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousUid = oldWidget.dataModel.uid;
    final currentUid = widget.dataModel.uid;
    final didDataModelChange = previousUid != currentUid;
    final didFieldsChange = oldWidget.fields != widget.fields;

    if (didDataModelChange || didFieldsChange) {
      if (_isDataMismatch && mounted) {
        _showUnsavedChangesLostSnackBar();
      }
      _initializeFormData();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  //check any mismatch is present
  bool _checkFormDirty() {
    for (final key in _cloneFormData.keys) {
      final currentValue = _normalizeForDirtyCheck(_formData[key]);
      final originalValue = _normalizeForDirtyCheck(_cloneFormData[key]);

      // Skip comparing 'items' - only check 'itemsId'
      if (key == 'items' && _cloneFormData.containsKey('itemsId')) {
        continue;
      }

      // Handle list comparison (for itemsId which are lists)
      if (currentValue is List && originalValue is List) {
        // Compare lists by converting to sorted strings
        final currentList = currentValue.map((e) => e.toString()).toList()
          ..sort();
        final originalList = originalValue.map((e) => e.toString()).toList()
          ..sort();

        // Check if lists are equal by comparing their string representations
        if (currentList.join(',') != originalList.join(',')) {
          return true;
        }
      } else if (currentValue != originalValue) {
        return true;
      }
    }
    return false;
  }

  //called whenever field changed
  void _onFieldChanged() {
    final bool wasDirty = _isDataMismatch;
    final bool isDirty = _checkFormDirty();

    //Update the flag!
    _isDataMismatch = isDirty;
    SectionCubit.hasUnsavedFormChanges = _isDataMismatch;

    final hasDynamicDropdown = widget.fields.any(
      (field) => field is ListingWidgetConfig && field.itemsBuilder != null,
    );

    //only rebuild if dirty state changed
    if (wasDirty != isDirty || hasDynamicDropdown) {
      setState(() {});
    }
  }

  String _composeTimeForTracking(String hour, String minute, String period) {
    final normalizedPeriod = period.toUpperCase() == 'PM' ? 'PM' : 'AM';
    return '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')} $normalizedPeriod';
  }

  //reset dirty state
  Future<bool> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        _formKey.currentState?.save();

        // Convert items to list if it's a string
        if (_formData['items'] is String) {
          _formData['items'] = (_formData['items'] as String)
              .split(',')
              .map((item) => item.trim())
              .toList();
        } else if (_formData['items'] == null ||
            (_formData['items'] is String &&
                (_formData['items'] as String).isEmpty)) {
          _formData['items'] = [];
        }

        // Convert itemsId to list if it's a string
        if (_formData['itemsId'] is String) {
          _formData['itemsId'] = (_formData['itemsId'] as String)
              .split(',')
              .where((id) => id.isNotEmpty)
              .toList();
        } else if (_formData['itemsId'] == null ||
            (_formData['itemsId'] is List &&
                (_formData['itemsId'] as List).isEmpty)) {
          _formData['itemsId'] = [];
        }

        final currentItemId = (_formData['id'] as String?)?.trim();
        DataModel formSubmittedDataModel = widget.rebuildDataModel(_formData);

        /// If uid is null, it's a new item, so we call createItem. Otherwise, it's an existing item, so we call updateItem with the index of the item being edited.
        if (currentItemId == null || currentItemId.isEmpty) {
          final createdId = await widget.formCubit.createItem(
            formSubmittedDataModel,
          );
          debugPrint('Created item with ID: $createdId');

          // Persist the created document ID locally so the next save uses update.
          _formData['id'] = createdId;
          _cloneFormData['id'] = createdId;
          formSubmittedDataModel = widget.rebuildDataModel(_formData);
        } else {
          await widget.formCubit.updateItem(
            widget.formCubit.repo.items.indexWhere(
              (item) => (item as DataModel?)?.uid == currentItemId,
            ),
            formSubmittedDataModel,
          );
        }

        // Reset dirty state after successful save
        _isDataMismatch = false;
        SectionCubit.hasUnsavedFormChanges = false;

        final bool isEdit = currentItemId != null && currentItemId.isNotEmpty;
        final String action = isEdit ? "updated" : "created";
        final String entity = widget.snackBarEntityName ?? "Data";

        if (mounted) {
          CustomSnackBar.show(
            context,
            "$entity $action successfully!",
            category: SnackBarCategory.success,
          );
        }
        widget.onSaveSuccess?.call();
        return true;
      } catch (e) {
        debugPrint("Error saving data: $e");
        if (mounted) {
          CustomSnackBar.show(
            context,
            "Error saving data: $e",
            category: SnackBarCategory.failure,
          );
        }
        return false;
      }
    } else {
      CustomSnackBar.show(
        context,
        "Please correct the errors in the form.",
        category: SnackBarCategory.failure,
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.formCubit,
      child: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _onFormKeyEvent,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.sidePadding),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${widget.dataModel.uid.isEmpty ? 'new' : widget.dataModel.uid}|$_formResetVersion',
                    ),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Column(
                          spacing: AppTheme.formFieldGap,
                          children: widget.fields
                              // Handle field-level visibility
                              .where((field) {
                                if (field.isVisible != null) {
                                  return field.isVisible!(_formData);
                                } else {
                                  return true;
                                }
                              })
                              //
                              .map((field) {
                                return KeyedSubtree(
                                  key: ValueKey(
                                    '${widget.dataModel.uid.isEmpty ? 'new' : widget.dataModel.uid}|${field.key}|$_formResetVersion',
                                  ),
                                  child: getWidgetForFieldType(field),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              //save button and cancel button
              Padding(
                padding: EdgeInsets.only(top: AppTheme.sidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<FormCubit<DataModel>, FormViewState>(
                            builder: (context, state) {
                              ButtonState saveButtonState;
                              ButtonState cancelButtonState;
                              final bool isUndoMode =
                                  HardwareKeyboard.instance.isAltPressed;

                              if (state is FormInProgress) {
                                saveButtonState = ButtonState.working;
                                cancelButtonState = ButtonState.disabled;
                              } else {
                                /// Disable update button if true data mismatch
                                saveButtonState =
                                    (_isDataMismatch && widget.supportsCrud)
                                    ? ButtonState.enabled
                                    : ButtonState.disabled;
                                cancelButtonState = ButtonState.enabled;
                              }
                              return Row(
                                children: [
                                  ...widget.actionButtons.map((button) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: AppTheme.formFieldGap,
                                      ),
                                      child: button,
                                    );
                                  }),

                                  const Spacer(),

                                  if (widget.dataModel.uid.isEmpty ||
                                      widget.cancelButtonText != null) ...[
                                    CustomButton(
                                      text: widget.cancelButtonText ?? "Cancel",
                                      icon: Icons.cancel_outlined,
                                      buttonType: ButtonType.tertiary,
                                      buttonState: cancelButtonState,
                                      onPressed: () {
                                        if (_isDataMismatch) {
                                          _showUnsavedChangesLostSnackBar();
                                          SectionCubit.hasUnsavedFormChanges =
                                              false;
                                        }

                                        if (widget.onCancel != null) {
                                          widget.onCancel!.call();
                                          return;
                                        }

                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    SizedBox(width: AppTheme.formFieldGap),
                                  ],

                                  CustomButton(
                                    text: isUndoMode
                                        ? "Reset"
                                        : (widget.primaryButtonText ??
                                              "Update"),
                                    icon: isUndoMode
                                        ? Icons.restore_page_outlined
                                        : Icons.save_outlined,
                                    height: AppTheme.buttonHeight,
                                    buttonState: saveButtonState,
                                    onPressed: () {
                                      final bool isUndoModeOnClick =
                                          HardwareKeyboard
                                              .instance
                                              .isAltPressed;

                                      if (isUndoModeOnClick) {
                                        if (!_isDataMismatch) {
                                          CustomSnackBar.show(
                                            context,
                                            "No changes made to the data.",
                                            category: SnackBarCategory.info,
                                          );
                                          return;
                                        }
                                        _resetToInitialSnapshot();
                                        return;
                                      }
                                      if (!_isDataMismatch) {
                                        CustomSnackBar.show(
                                          context,
                                          "No changes made to the data.",
                                          category: SnackBarCategory.info,
                                        );
                                        return;
                                      } else {
                                        _handleSave();
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
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
    );
  }

  /// switch expression:
  Widget getWidgetForFieldType(WidgetConfig field) {
    final fieldType = field.fieldType;
    final key = field.key;
    final initialValue = field.initialValue;
    final labelText = field.labelText ?? '';
    final enabled = (field.enabled ?? true) && widget.supportsCrud;
    final mandatory = field.mandatory;
    final icon = field.icon ?? Icons.text_fields_sharp;
    final iconSize = field.iconSize ?? 20.0;
    final isFieldInteractive = fieldType == FieldType.status
        ? field.keepTextVisible
        : (enabled != false);

    final fieldWidget = switch (fieldType) {
      FieldType.general => FormFieldView(
        key: Key(key),
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        icon: icon,
        iconSize: iconSize,
        textCapitalization: field.textCapitalization ?? TextCapitalization.none,
      ),

      ///
      FieldType.status => FormFieldView(
        key: Key(key),
        initialValue: initialValue,
        labelText: labelText.isEmpty ? 'Status' : labelText,
        enabled: false,
        mandatory: false,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.dropdown =>
        //IIFE: - before return from switch case we perform some task
        (() {
          //This cast gives access to properties and methods specific to dropdowns, like items, itemsBuilder, etc.
          final listingField = field as ListingWidgetConfig;

          // If itemsBuilder is provided, it’s a function that dynamically generates the list of items based on the current form data (_formData).
          final List<DataModel> dropdownItems =
              listingField.itemsBuilder?.call(_formData) ?? field.items;

          final String? selectedId = _formData['${key}Id']?.toString();

          DataModel? selectedItem;

          if (selectedId != null && selectedId.isNotEmpty) {
            for (final item in dropdownItems) {
              if (item.uid == selectedId) {
                selectedItem = item;
                break;
              }
            }
          }

          selectedItem ??= listingField.initialData;

          /// Key includes selected item id so dropdown rebuilds when a dependent
          return FormDropdownField<DataModel>(
            key: ValueKey(
              '${widget.dataModel.uid}|$key|${selectedItem?.uid ?? ''}',
            ),

            initialText: _formData[key]?.toString(),
            initialValue: selectedItem,

            onValueChanged: (Map<String, dynamic>? obj) {
              _formData[key] = obj?['value'];
              _formData['${key}Id'] = obj?['id'];

              DataModel? changedSelection;

              final String? changedId = obj?['id']?.toString();
              if (changedId != null && changedId.isNotEmpty) {
                for (final item in dropdownItems) {
                  if (item.uid == changedId) {
                    changedSelection = item;
                    break;
                  }
                }
              }

              //Hook:-  Optional hook so parent form can update related fields
              listingField.onChanged?.call(changedSelection, _formData);

              _onFieldChanged();
            },

            onSaved: (Map<String, String>? obj) {
              _formData[key] = obj?['value'];
              _formData['${key}Id'] = obj?['id'];
            },

            labelText: labelText,
            enabled: enabled,
            keepTextVisible: field.keepTextVisible,
            mandatory: mandatory,
            buttonText: 'Select $labelText',
            dialogTitle: labelText,
            dialogFooterMessage: listingField.dialogFooterMessage,
            emptyStateMessage: listingField.emptyStateMessage,
            emptyStateIcon: listingField.emptyStateIcon,
            itemLabel: field.itemLabel != null
                ? (item) => field.itemLabel!(item) ?? ''
                : null,
            items: dropdownItems,
            icon: icon,
            iconSize: iconSize,
            sortBy: field.sortBy,
            sortOrder: field.sortOrder,
            enableTextFieldTap: listingField.enableTextFieldTap,
          );
        })(),

      ///
      FieldType.time => FormTimeField(
        initialValue: initialValue,
        icon: icon,
        iconSize: iconSize,
        onChanged: (String hour, String minute, String period) {
          _formData[key] = _composeTimeForTracking(hour, minute, period);
          _onFieldChanged();
        },
        onSaved: (String hour, String minute, String period) {
          _formData[key] = DatetimeUtils.formatTimeToString(
            hour,
            minute,
            period,
          );
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
      ),

      ///
      FieldType.age => FormAgeField(
        initialValue: initialValue,
        onChanged: (year, month, day) {
          final y = int.tryParse(year);
          final m = int.tryParse(month.isEmpty ? '0' : month);
          final d = int.tryParse(day.isEmpty ? '0' : day);
          if (y != null && m != null && d != null) {
            _formData[key] = DatetimeUtils.getDateStringFromAge(y, m, d);
          }
          _onFieldChanged();
        },
        onSaved: ((String, String, String) value) {
          _formData[key] = DatetimeUtils.getDateStringFromAge(
            int.parse(value.$1),
            int.parse(value.$2),
            int.parse(value.$3),
          );
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.name => FormFieldView.name(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        textCapitalization: field.textCapitalization,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.address => FormFieldView.address(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        textCapitalization: field.textCapitalization,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.whatsapp => FormFieldView.whatsapp(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        isDuplicate: field.isDuplicate,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.mobileNumber => FormFieldView.mobileNumber(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        isDuplicate: field.isDuplicate,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.email => FormFieldView.email(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        isDuplicate: field.isDuplicate,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.password => FormFieldView.password(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText.isEmpty ? 'Password' : labelText,
        enabled: enabled,
        mandatory: mandatory,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.date => (() {
        final dateField = field is DateWidgetConfig ? field : null;
        return FormDateField(
          key: ValueKey(
            '${widget.dataModel.uid}|$key|${_fieldFingerprint(field)}',
          ),
          initialValue: initialValue,
          onChanged: (String value) {
            _formData[key] = value;
            dateField?.onChanged?.call(value, _formData);
            _onFieldChanged();
          },
          onSaved: (String value) {
            _formData[key] = value;
          },
          labelText: labelText,
          enabled: enabled,
          mandatory: mandatory,
          dateRangeEndInDays: dateField?.dateRangeEndInDays,
          dateRangeStartInDays: dateField?.dateRangeStartInDays,
          keepTextVisible: field.keepTextVisible,
          defaultDateInDays: dateField?.defaultDateInDays,
          onPickDate: dateField?.onPickDateWithFormData != null
              ? () => dateField!.onPickDateWithFormData!.call(_formData)
              : dateField?.onPickDate,
          icon: icon,
          iconSize: iconSize,
        );
      })(),

      ///
      FieldType.amount => FormFieldView.amount(
        initialValue: initialValue,
        onChanged: (value) {
          _formData[key] = value;
          _onFieldChanged();
        },
        onSaved: (value) {
          _formData[key] = value;
        },
        labelText: labelText,
        enabled: enabled,
        mandatory: mandatory,
        icon: icon,
        iconSize: iconSize,
      ),

      ///
      FieldType.multiSelect => FormMultiSelectField<DataModel>(
        key: ValueKey(
          '${widget.dataModel.uid}|$key|${_fieldFingerprint(field)}',
        ),
        initialText: (field as MultiSelectWidgetConfig).initialValue,
        initialValues: (field).initialDataSet != null
            ? [...(field).initialDataSet!]
            : null,
        // onChange is not present previously
        onChanged: (List<DataModel>? selectedItems) {
          final ids = selectedItems?.map((e) => e.uid).toList() ?? [];
          final names =
              selectedItems?.map((e) => e.title ?? '').join(', ') ?? '';
          _formData['${key}Id'] = ids;
          _formData[key] = names;
          _onFieldChanged();
        },
        onSaved: (Map<String, String>? obj) {
          _formData[key] = obj?['value'];
          // Keep itemsId as List, don't convert to string
          // The obj?['ids'] is a comma-separated string, convert it to List
          _formData['${key}Id'] = (obj?['ids'] ?? '')
              .split(',')
              .where((id) => id.isNotEmpty)
              .toList();
        },
        labelText: labelText,
        enabled: enabled,
        keepTextVisible: field.keepTextVisible,
        mandatory: mandatory,
        buttonText: 'Select $labelText',
        dialogTitle: labelText,
        itemLabel: field.itemLabel != null
            ? (item) => field.itemLabel!(item) ?? ''
            : null,
        highlightedIds: (field).highlightedIds,
        highlightedTextColor: (field).highlightedTextColor,
        items: field.items,
        icon: icon,
        iconSize: iconSize,
        sortBy: field.sortBy,
        sortOrder: field.sortOrder,
      ),
    };
    if (isFieldInteractive) return fieldWidget;
    return MouseRegion(
      cursor: SystemMouseCursors.forbidden,
      child: AbsorbPointer(child: fieldWidget),
    );
  }
}

/// UI Model for UI access
class WidgetConfig {
  final FieldType fieldType;
  final String key;
  final String? initialValue;
  final String? labelText;
  final IconData? icon;
  final double? iconSize;
  final bool? enabled;
  final bool? mandatory;
  final bool keepTextVisible; //globally access
  final bool Function(String)? isDuplicate;
  final TextCapitalization? textCapitalization;
  final bool Function(Map<String, dynamic> formData)? isVisible;

  WidgetConfig({
    required this.fieldType,
    required this.key,
    this.initialValue,
    this.labelText,
    this.icon,
    this.iconSize,
    this.enabled,
    this.mandatory,
    this.keepTextVisible = false,
    this.isDuplicate,
    this.textCapitalization,
    this.isVisible,
  });
}

class ListingWidgetConfig extends WidgetConfig {
  final List<DataModel> items;
  final DataModel? initialData;
  final String? Function(DataModel?)? itemLabel;
  final SortBy? sortBy;
  final SortOrder? sortOrder;
  final List<DataModel> Function(Map<String, dynamic> formData)? itemsBuilder;
  // Called whenever this dropdown selection changes.
  // Use this to update dependent values in shared formData.
  final void Function(DataModel?, Map<String, dynamic>)? onChanged;
  // Optional note shown at the bottom of dropdown dialog.
  // If set, selection in dialog becomes read-only and this message explains why.
  final String? dialogFooterMessage;
  // Optional empty-state text/icon shown when dropdown has no items.
  final String? emptyStateMessage;
  final IconData? emptyStateIcon;
  final bool enableTextFieldTap;

  ListingWidgetConfig({
    required super.key,
    super.initialValue,
    super.labelText,
    super.icon,
    super.iconSize,
    super.enabled,
    super.mandatory,
    super.keepTextVisible,
    required this.items,
    this.initialData,
    this.itemLabel,
    this.sortBy,
    this.sortOrder,
    this.itemsBuilder,
    this.onChanged,
    this.dialogFooterMessage,
    this.emptyStateMessage,
    this.emptyStateIcon,
    this.enableTextFieldTap = true,
    super.isVisible,
  }) : super(fieldType: FieldType.dropdown);
}

class MultiSelectWidgetConfig extends WidgetConfig {
  final List<DataModel> items;
  final List<DataModel>? initialDataSet;
  final String? Function(DataModel?)? itemLabel;
  final SortBy? sortBy;
  final SortOrder? sortOrder;
  final Set<String>? highlightedIds;
  final Color? highlightedTextColor;

  MultiSelectWidgetConfig({
    required super.key,
    super.initialValue,
    super.labelText,
    super.icon,
    super.iconSize,
    super.enabled,
    super.mandatory,
    super.keepTextVisible,
    required this.items,
    this.initialDataSet,
    this.itemLabel,
    this.sortBy,
    this.sortOrder,
    this.highlightedIds,
    this.highlightedTextColor,
  }) : super(fieldType: FieldType.multiSelect);
}

class DateWidgetConfig extends WidgetConfig {
  final int? dateRangeEndInDays;
  final int? dateRangeStartInDays;
  final int? defaultDateInDays;
  final Future<String?> Function()? onPickDate;
  final Future<String?> Function(Map<String, dynamic> formData)?
  onPickDateWithFormData;
  final void Function(String?, Map<String, dynamic>)? onChanged;

  DateWidgetConfig({
    required super.key,
    super.initialValue,
    super.labelText,
    super.icon,
    super.iconSize,
    super.enabled,
    super.mandatory,
    super.keepTextVisible,
    this.dateRangeEndInDays,
    this.dateRangeStartInDays,
    this.defaultDateInDays,
    this.onPickDate,
    this.onPickDateWithFormData,
    this.onChanged,
  }) : super(fieldType: FieldType.date);
}
