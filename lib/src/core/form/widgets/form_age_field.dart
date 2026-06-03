import 'package:flutter/material.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

class FormAgeField extends StatefulWidget {
  final String? initialValue; // dateTime string, e.g. "2020-01-01"
  final String? labelText;
  final bool? enabled;
  final bool? mandatory;
  final IconData? icon;
  final double? iconSize;
  final void Function((String year, String month, String day))? onSaved;
  final void Function(String year, String month, String day)? onChanged;

  /// Validators for each field
  final String? Function(String?)? yearValidator;
  final String? Function(String?)? monthValidator;
  final String? Function(String?)? dayValidator; // Todo make it optional

  const FormAgeField({
    super.key,
    this.initialValue,
    this.labelText,
    this.enabled = true,
    this.mandatory = true,
    this.icon,
    this.iconSize,
    this.onSaved,
    this.onChanged,
    this.yearValidator,
    this.monthValidator,
    this.dayValidator,
  });

  @override
  State<FormAgeField> createState() => _FormAgeFieldState();
}

class _FormAgeFieldState extends State<FormAgeField> {
  late TextEditingController _yearController;
  late TextEditingController _monthController;
  late TextEditingController _dayController;
  late FocusNode _yearFocusNode;

  String? _savedYear;
  String? _savedMonth;
  String? _savedDay;

  @override
  void initState() {
    super.initState();
    int years = 0, months = 0, days = 0;
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      (years, months, days) = DatetimeUtils.calculateAge(widget.initialValue!);
    }
    _yearController = TextEditingController(
      text: years > 0 ? years.toString() : '',
    );
    _monthController = TextEditingController(
      text: months > 0 ? months.toString() : '',
    );
    _dayController = TextEditingController(
      text: days > 0 ? days.toString() : '',
    );
    _yearFocusNode = FocusNode();
    _yearFocusNode.addListener(() {
      if (!_yearFocusNode.hasFocus) {
        _autoFillUnknownDobParts();
      }
    });
    _yearController.addListener(_notifyChanged);
    _monthController.addListener(_notifyChanged);
    _dayController.addListener(_notifyChanged);
  }

  @override
  void dispose() {
    _yearFocusNode.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  /// Returns the current age as (years, months, days)
  (String year, String month, String day) get ageValues =>
      (_yearController.text, _monthController.text, _dayController.text);

  void _notifyChanged() {
    widget.onChanged?.call(
      _yearController.text,
      _monthController.text,
      _dayController.text,
    );
  }

  void _onFieldSaved({String? year, String? month, String? day}) {
    if (year != null) _savedYear = year;
    if (month != null) _savedMonth = month;
    if (day != null) _savedDay = day;

    // If all are non-null, call the main onSaved
    if (_savedYear != null && _savedMonth != null && _savedDay != null) {
      final allEmpty =
          (_savedYear!.isEmpty && _savedMonth!.isEmpty && _savedDay!.isEmpty);
      if (widget.onSaved != null && !allEmpty) {
        // Convert empty strings to "0" for month and day when year is provided
        String finalMonth = _savedMonth!.isEmpty ? "0" : _savedMonth!;
        String finalDay = _savedDay!.isEmpty ? "0" : _savedDay!;
        widget.onSaved!((_savedYear!, finalMonth, finalDay));
      }
    }
  }

  void _autoFillUnknownDobParts() {
    final yearText = _yearController.text.trim();
    if (yearText.isEmpty) return;

    if (_monthController.text.trim().isEmpty) {
      _monthController.text = '0';
    }
    if (_dayController.text.trim().isEmpty) {
      _dayController.text = '0';
    }
  }

  // Default validators
  String? _defaultYearValidator(String? value) {
    if ((widget.mandatory ?? true) && (value == null || value.isEmpty)) {
      return 'Year is required';
    }
    if (value != null && value.isNotEmpty) {
      final n = int.tryParse(value);
      if (n == null || n < 0) return 'Invalid year';
    }
    return null;
  }

  String? _defaultMonthValidator(String? value) {
    // For pets, month is not mandatory when year is provided
    // Only validate if there's a value, but don't require it
    if (value != null && value.isNotEmpty) {
      final n = int.tryParse(value);
      if (n == null || n < 0 || n > 11) return '0-11 only';
    }
    return null;
  }

  String? _defaultDayValidator(String? value) {
    // For pets, day is not mandatory when year is provided
    // Only validate if there's a value, but don't require it
    if (value != null && value.isNotEmpty) {
      final n = int.tryParse(value);
      if (n == null || n < 0 || n > 30) return '0-29 only';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextField(
            textController: _yearController,
            labelText: '${widget.labelText ?? 'Age'} : Years',
            icon: Icons.access_time,
            keyboardType: TextInputType.number,
            enabled: widget.enabled,
            focusNode: _yearFocusNode,
            onFieldSubmitted: (_) => _autoFillUnknownDobParts(),
            onSaved: (val) => _onFieldSaved(year: val),
            validator: widget.yearValidator ?? _defaultYearValidator,
            mandatory: widget.mandatory ?? true,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Icon(Icons.add, size: 20, color: Colors.grey),
        ),

        Expanded(
          child: CustomTextField(
            textController: _monthController,
            labelText: 'Months',
            initialValue: _monthController.text,
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            enabled: widget.enabled,
            onSaved: (val) => _onFieldSaved(month: val),
            validator: widget.monthValidator ?? _defaultMonthValidator,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Icon(Icons.add, size: 20, color: Colors.grey),
        ),
        Expanded(
          child: CustomTextField(
            textController: _dayController,
            labelText: 'Days',
            icon: Icons.today,
            keyboardType: TextInputType.number,
            initialValue: _dayController.text,
            enabled: widget.enabled,
            onSaved: (val) => _onFieldSaved(day: val),
            validator: widget.dayValidator ?? _defaultDayValidator,
          ),
        ),
        SizedBox(width: AppTheme.formFieldGap),
        CustomButton(
          buttonType: ButtonType.tertiary,
          text: 'Date of Birth',
          icon: Icons.date_range,
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(Duration(days: 365 * 100)),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              String formattedDate =
                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

              final (int years, int months, int days) =
                  DatetimeUtils.calculateAge(formattedDate);

              _yearController.text = years.toString();
              _monthController.text = months.toString();
              _dayController.text = days.toString();

              setState(() {});
              // save(); // Call onSaved after picking date
            }
          },
        ),
      ],
    );
  }
}
