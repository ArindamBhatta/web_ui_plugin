import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_ui_plugin/src/core/widgets/custom_textfield.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

class FormFieldView extends StatefulWidget {
  final String? initialValue;
  final String? errorText;
  final String labelText;
  final bool? enabled;
  final bool? mandatory;
  final bool keepTextVisible;
  final IconData icon;
  final TextInputType keyboardType;
  final double iconSize;
  final bool isPassword;
  final TextCapitalization textCapitalization;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSaved;
  final String? Function(String?)? _validate;

  FormFieldView({
    super.key,
    this.initialValue,
    this.errorText,
    required this.labelText,
    this.enabled = true,
    this.mandatory = true,
    this.keepTextVisible = false,
    this.icon = FontAwesomeIcons.pen,
    this.keyboardType = TextInputType.text,
    this.iconSize = 22,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSaved,
    String? Function(String?)? validate,
  }) : _validate =
           validate ??
           ((value) {
             if (mandatory ?? true) {
               if (value == null || value.trim().isEmpty) {
                 return '$labelText is required';
               }
             }
             return null;
           });

  factory FormFieldView.name({
    Key? key,
    String? initialValue,
    String? labelText,
    bool? enabled = true,
    bool? mandatory = true,
    IconData? icon,
    double? iconSize,
    TextCapitalization? textCapitalization,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      onChanged: onChanged,
      labelText: labelText ?? 'Name',
      mandatory: mandatory,
      textCapitalization: textCapitalization ?? TextCapitalization.words,
      onSaved: onSaved,
      enabled: enabled,
      icon: icon ?? FontAwesomeIcons.solidUser,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
    );
  }

  factory FormFieldView.address({
    Key? key,
    String? initialValue,
    String? labelText,
    bool? enabled = true,
    bool? mandatory = true,
    IconData? icon,
    double? iconSize,
    TextCapitalization? textCapitalization,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      labelText: labelText ?? 'Address',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.locationDot,
      keyboardType: TextInputType.streetAddress,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
      textCapitalization: textCapitalization ?? TextCapitalization.sentences,
      onChanged: onChanged,
      onSaved: onSaved,
    );
  }

  factory FormFieldView.mobileNumber({
    Key? key,
    String? initialValue,
    String? labelText,
    bool? enabled = true,
    bool? mandatory = true,
    IconData? icon,
    double? iconSize,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
    bool Function(String)? isDuplicate,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      labelText: labelText ?? 'Mobile Number',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.phone,
      keyboardType: TextInputType.phone,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
      onChanged: onChanged,
      onSaved: onSaved,
      validate: (value) {
        if (mandatory ?? true) {
          if (value == null || value.trim().isEmpty) {
            return '$labelText is required';
          }
        }
        if (value != null && value.trim().isNotEmpty) {
          final mobileRegex = RegExp(r'^\d{10}$');
          if (!mobileRegex.hasMatch(value.trim())) {
            return 'Enter a valid 10-digit mobile number';
          }

          if (isDuplicate != null && isDuplicate(value.trim())) {
            return 'Mobile number already exists';
          }
        }
        return null;
      },
    );
  }

  factory FormFieldView.whatsapp({
    Key? key,
    String? initialValue,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
    bool? enabled = true,
    bool? mandatory = true,
    IconData? icon,
    double? iconSize,
    String? labelText,
    bool Function(String)? isDuplicate,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      labelText: labelText ?? 'WhatsApp Number',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.whatsapp,
      keyboardType: TextInputType.phone,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
      validate: (value) {
        if (mandatory ?? true) {
          if (value == null || value.trim().isEmpty) {
            return '$labelText is required';
          }
        }
        if (value != null && value.trim().isNotEmpty) {
          final mobileRegex = RegExp(r'^\d{10}$');
          if (!mobileRegex.hasMatch(value.trim())) {
            return 'Enter a valid 10-digit WhatsApp number';
          }

          if (isDuplicate != null && isDuplicate(value.trim())) {
            return 'already exist WhatsApp number';
          }
        }
        return null;
      },
    );
  }

  factory FormFieldView.email({
    Key? key,
    String? initialValue,
    String? errorText,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
    bool? enabled = true,
    bool? mandatory = true,
    IconData? icon,
    double? iconSize,
    String? labelText,
    bool Function(String)? isDuplicate,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSaved: onSaved,
      labelText: labelText ?? 'Email',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.envelope,
      keyboardType: TextInputType.emailAddress,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
      validate: ((value) {
        if (mandatory ?? true) {
          if (value == null || value.trim().isEmpty) {
            return '$labelText is required';
          }
        }
        if (value != null && value.trim().isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Enter a valid email address';
          }

          if (isDuplicate != null && isDuplicate(value.trim())) {
            return 'already exist email';
          }
        }
        return null;
      }),
    );
  }

  factory FormFieldView.amount({
    Key? key,
    String? initialValue,
    IconData? icon,
    double? iconSize,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
    bool? enabled = true,
    bool? mandatory = true,
    String? labelText,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      labelText: labelText ?? 'Amount',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.rupeeSign,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
    );
  }

  factory FormFieldView.password({
    Key? key,
    String? initialValue,
    String? errorText,
    IconData? icon,
    double? iconSize,
    void Function(String?)? onChanged,
    void Function(String?)? onSaved,
    bool? enabled = true,
    bool? mandatory = true,
    String? labelText,
  }) {
    return FormFieldView(
      key: key,
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSaved: onSaved,
      labelText: labelText ?? 'Password',
      enabled: enabled,
      mandatory: mandatory,
      icon: icon ?? FontAwesomeIcons.lock,
      keyboardType: TextInputType.visiblePassword,
      iconSize: iconSize ?? AppTheme.formFieldIconSize,
      isPassword: true,
    );
  }

  @override
  State<FormFieldView> createState() => _FormFieldViewState();
}

class _FormFieldViewState extends State<FormFieldView> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(() {
      widget.onChanged?.call(_controller.text.trim());
    });
    _focusNode = FocusNode();

    if (widget.textCapitalization == TextCapitalization.words) {
      _focusNode.addListener(() {
        if (!_focusNode.hasFocus) {
          final text = _controller.text;

          if (text.isNotEmpty) {
            final capitalized = text
                .split(' ')
                .map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() + word.substring(1);
                })
                .join(' ');

            if (capitalized != text) {
              _controller.text = capitalized;
              widget.onChanged?.call(capitalized.trim());
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  //selects a different record to edit), the initialValue for the field might change (e.g., from "Arindam" to "Arjuna").
  @override
  void didUpdateWidget(covariant FormFieldView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      final nextText = widget.initialValue ?? '';
      if (_controller.text != nextText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_controller.text != nextText) {
            _controller.text = nextText;
          }
        });
      }
    }
  }

  String get value => _controller.text.trim();

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      textController: _controller,
      labelText: widget.labelText,
      errorText: widget.errorText,
      icon: widget.icon,
      keyboardType: widget.keyboardType,
      isPassword: widget.isPassword,
      enabled: (widget.enabled ?? true) || widget.keepTextVisible, //added
      validator: widget._validate,
      onFieldSubmitted: null,
      inputFormatters: [],
      maxLength: null,
      iconSize: widget.iconSize,
      onSaved: widget.onSaved,
      readOnly: widget.enabled == false,
      textCapitalization: widget.textCapitalization,
      mandatory: widget.mandatory ?? true,
      focusNode: _focusNode,
    );
  }
}
