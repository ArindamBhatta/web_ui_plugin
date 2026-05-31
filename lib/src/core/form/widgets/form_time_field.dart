import 'package:flutter/material.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';
import 'package:toggle_switch/toggle_switch.dart';

class FormTimeField extends StatefulWidget {
  final String? initialValue; // Format: "HH:mm a" (e.g., "09:30 AM")
  final String? labelText;
  final bool? enabled;
  final bool? mandatory;
  final void Function(String hour, String minute, String period)? onChanged;
  final void Function(String hour, String minute, String period)? onSaved;
  // Validators for each field
  final String? Function(String?)? hourValidator;
  final String? Function(String?)? minuteValidator;
  final IconData icon;
  final double iconSize;

  const FormTimeField({
    super.key,
    this.initialValue,
    this.labelText,
    this.enabled = true,
    this.mandatory = true,
    this.onChanged,
    this.onSaved,
    this.hourValidator,
    this.minuteValidator,
    required this.icon,
    required this.iconSize,
  });

  @override
  State<FormTimeField> createState() => _FormTimeFieldState();
}

class _FormTimeFieldState extends State<FormTimeField> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    String hour = '', minute = '';
    bool isAm = true;
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final parts = widget.initialValue!.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        if (timeParts.length == 2) {
          hour = timeParts[0].padLeft(2, '0');
          minute = timeParts[1].padLeft(2, '0');
        }
        isAm = parts[1].toUpperCase() == 'AM';
      }
    }
    _hourController = TextEditingController(text: hour);
    _minuteController = TextEditingController(text: minute);
    _isAm = isAm;
    _hourController.addListener(_emitChanged);
    _minuteController.addListener(_emitChanged);
  }

  @override
  void dispose() {
    _hourController.removeListener(_emitChanged);
    _minuteController.removeListener(_emitChanged);
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _emitChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(
        _hourController.text.padLeft(2, '0'),
        _minuteController.text.padLeft(2, '0'),
        _isAm ? 'AM' : 'PM',
      );
    }
  }

  void _onSaved() {
    if (widget.onSaved != null) {
      widget.onSaved!(
        _hourController.text.padLeft(2, '0'),
        _minuteController.text.padLeft(2, '0'),
        _isAm ? 'AM' : 'PM',
      );
    }
  }

  String? _defaultHourValidator(String? value) {
    if ((widget.mandatory ?? true) && (value == null || value.isEmpty)) {
      return 'Hour required';
    }
    if (value != null && value.isNotEmpty) {
      final n = int.tryParse(value);
      if (n == null || n < 1 || n > 12) return '1-12 only';
    }
    return null;
  }

  String? _defaultMinuteValidator(String? value) {
    if ((widget.mandatory ?? true) && (value == null || value.isEmpty)) {
      return 'Minute required';
    }
    if (value != null && value.isNotEmpty) {
      final n = int.tryParse(value);
      if (n == null || n < 0 || n > 59) return '0-59 only';
    }
    return null;
  }

  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final initialHour = int.tryParse(_hourController.text) ?? now.hourOfPeriod;
    final initialMinute = int.tryParse(_minuteController.text) ?? now.minute;
    final initialPeriod = _isAm ? DayPeriod.am : DayPeriod.pm;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialPeriod == DayPeriod.am
            ? (initialHour == 12 ? 0 : initialHour)
            : (initialHour == 12 ? 12 : initialHour + 12),
        minute: initialMinute,
      ),
    );
    if (picked != null) {
      int hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      String hourStr = hour.toString().padLeft(2, '0');
      String minuteStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _hourController.text = hourStr;
        _minuteController.text = minuteStr;
        _isAm = picked.period == DayPeriod.am;
      });
      _onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: CustomTextField(
            textController: _hourController,
            labelText: '${widget.labelText ?? 'Time'} : Hour',
            icon: Icons.access_time,
            keyboardType: TextInputType.number,
            enabled: widget.enabled,
            onSaved: (_) => _onSaved(),
            validator: widget.hourValidator ?? _defaultHourValidator,
            maxLength: 2,
            mandatory: widget.mandatory ?? true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(":", style: TextStyle(fontSize: 18)),
        ),
        Expanded(
          flex: 2,
          child: CustomTextField(
            textController: _minuteController,
            labelText: 'Minute',
            icon: Icons.timelapse,
            keyboardType: TextInputType.number,
            enabled: widget.enabled,
            onSaved: (_) => _onSaved(),
            validator: widget.minuteValidator ?? _defaultMinuteValidator,
            maxLength: 2,
          ),
        ),
        SizedBox(width: AppTheme.formFieldGap),
        ToggleSwitch(
          minWidth: 50.0,
          initialLabelIndex: _isAm ? 0 : 1,
          totalSwitches: 2,
          labels: ['AM', 'PM'],
          cornerRadius: 4.0,
          activeBgColors: [
            [Colors.white],
            [Colors.white],
          ],
          inactiveBgColor: Colors.grey[300],
          onToggle: widget.enabled == false
              ? null
              : (index) {
                  setState(() {
                    _isAm = index == 0;
                  });
                  _emitChanged();
                  _onSaved();
                },
          customTextStyles: [
            TextStyle(
              color: _isAm ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            TextStyle(
              color: !_isAm ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        SizedBox(width: AppTheme.formFieldGap),
        CustomButton(
          buttonType: ButtonType.tertiary,
          text: 'Pick Time',
          icon: Icons.access_time,
          onPressed: widget.enabled == false ? null : () => _pickTime(context),
        ),
      ],
    );
  }
}
