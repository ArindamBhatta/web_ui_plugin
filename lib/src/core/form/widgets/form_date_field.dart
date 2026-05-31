import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class FormDateField extends StatefulWidget {
  final String? initialValue; // date string, e.g. "2020-01-01"
  final String? labelText;
  final bool? enabled;
  final bool keepTextVisible;
  final bool? mandatory;
  final IconData? icon;
  final double? iconSize;

  final void Function(String date)? onChanged;
  final void Function(String date)? onSaved;

  final String? Function(String?)? validator;
  final int? dateRangeEndInDays;
  final int? dateRangeStartInDays;
  final int? defaultDateInDays;
  final Future<String?> Function()? onPickDate;

  const FormDateField({
    super.key,
    this.initialValue,
    this.labelText,
    this.enabled = true,
    this.mandatory = true,
    this.keepTextVisible = false,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.dateRangeEndInDays,
    this.dateRangeStartInDays,
    this.defaultDateInDays,
    this.onPickDate,
    this.icon,
    this.iconSize,
  });

  @override
  State<FormDateField> createState() => _FormDateFieldState();
}

class _FormDateFieldState extends State<FormDateField> {
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Determine default date
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _selectedDate = DateTime.tryParse(widget.initialValue!);
    } else if (widget.defaultDateInDays != null) {
      _selectedDate = DateTime.now().add(
        Duration(days: widget.defaultDateInDays!),
      );
    } else {
      _selectedDate = null;
    }
    _dateController = TextEditingController(
      text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String? _defaultValidator(String? value) {
    if ((widget.mandatory ?? true) && (value == null || value.isEmpty)) {
      return 'Date is required';
    }
    //check if the date format is conforming to YYYY-MM-DD and that it is a valid date
    if (value != null && value.isNotEmpty) {
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!regex.hasMatch(value)) {
        return 'Invalid date format. Use YYYY-MM-DD';
      }
      final parts = value.split('-');
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) {
        return 'Invalid date components';
      }
      try {
        final date = DateTime(year, month, day);
        if (date.year != year || date.month != month || date.day != day) {
          return 'Invalid date';
        }
      } catch (e) {
        return 'Invalid date';
      }
    }
    return null;
  }

  void _onSaved(String? value) {
    if (widget.onSaved != null && value != null && value.isNotEmpty) {
      widget.onSaved!(value);
    }
  }

  void _onChanged(String? value) {
    if (widget.onChanged != null && value != null) {
      widget.onChanged!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate firstDate and lastDate based on properties
    DateTime today = DateTime.now();
    DateTime firstDate = widget.dateRangeStartInDays != null
        ? today.add(Duration(days: widget.dateRangeStartInDays!))
        : today.subtract(Duration(days: 365 * 100));
    DateTime lastDate = widget.dateRangeEndInDays != null
        ? today.add(Duration(days: widget.dateRangeEndInDays!))
        : today.add(Duration(days: 365 * 100));

    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            textController: _dateController,
            labelText: widget.labelText ?? 'Date',
            icon: widget.icon ?? FontAwesomeIcons.calendar,
            iconSize: widget.iconSize ?? AppTheme.formFieldIconSize,
            enabled: (widget.enabled ?? true) || widget.keepTextVisible,
            onSaved: _onSaved,
            validator: widget.validator ?? _defaultValidator,
            mandatory: widget.mandatory ?? true,
          ),
        ),
        SizedBox(width: AppTheme.formFieldGap),
        CustomButton(
          buttonType: ButtonType.tertiary,
          text: 'Pick Date',
          icon: FontAwesomeIcons.calendar,
          buttonState: (widget.enabled == false)
              ? ButtonState.disabled
              : ButtonState.enabled,
          onPressed: widget.enabled == false
              ? null
              : () async {
                  if (widget.onPickDate != null) {
                    final selected = await widget.onPickDate!.call();
                    if (selected != null && selected.isNotEmpty) {
                      final parsed = DateTime.tryParse(selected);
                      setState(() {
                        _selectedDate = parsed;
                        _dateController.text = parsed != null
                            ? _formatDate(parsed)
                            : selected;
                      });
                      _onChanged(_dateController.text);
                      _onSaved(_dateController.text);
                    }
                    return;
                  }

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: () {
                      DateTime initial =
                          DateTime.tryParse(_dateController.text) ?? today;
                      if (initial.isBefore(firstDate)) {
                        initial = firstDate;
                      } else if (initial.isAfter(lastDate)) {
                        initial = lastDate;
                      }
                      return initial;
                    }(),
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _dateController.text = _formatDate(_selectedDate!);
                    });
                    _onChanged(_dateController.text);
                  }
                },
        ),
      ],
    );
  }
}
