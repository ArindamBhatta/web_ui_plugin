import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required TextEditingController textController,
    required this.labelText,
    required this.icon,
    this.errorText,
    this.initialValue,
    this.height = 40,
    this.iconSize = 20,
    this.fontLabelSize = 12,
    this.floatingLabelFontSize = 16,
    this.keyboardType = TextInputType.text,
    this.fontSize = 14,
    this.maxLength,
    this.isPassword = false,
    this.multiline = false,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.done,
    this.onTap,
    this.readOnly = false,
    this.validator,
    this.onSaved,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    this.focusNode,
    this.onFieldSubmitted,
    this.enabled,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.mandatory = false,
    this.textColor,
    this.suffixIcon,
  }) : _textController = textController;

  final TextEditingController _textController;
  final String labelText;
  final String? errorText;
  final String? initialValue;
  final Widget? suffixIcon;
  final double height;
  final double iconSize;
  final double fontLabelSize;
  final double floatingLabelFontSize;
  final IconData? icon;
  final TextInputType keyboardType;
  final double fontSize;
  final int? maxLength;
  final bool isPassword;
  final bool multiline;
  final int maxLines;
  final TextInputAction textInputAction;
  final VoidCallback? onTap;
  final bool readOnly;

  // Added properties for validation and form integration
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final bool? enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool mandatory;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      buildCounter:
          (
            BuildContext context, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) {
            return null; // hides the counter
          },
      controller: _textController,
      style: TextStyle(fontSize: fontSize, color: textColor),
      decoration: InputDecoration(
        label: mandatory
            ? RichText(
                text: TextSpan(
                  text: labelText,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: fontLabelSize,
                  ),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        isDense: true,
        labelText: mandatory ? null : labelText,
        errorText: errorText,
        contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 16),
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, size: iconSize),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          fontSize: fontLabelSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        floatingLabelStyle: TextStyle(fontSize: floatingLabelFontSize),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      obscureText: isPassword,
      onChanged: (value) {
        String transformed = value;
        if (textCapitalization == TextCapitalization.words) {
          transformed = value
              .split(' ')
              .map((word) {
                if (word.isEmpty) return word;
                return word[0].toUpperCase() + word.substring(1);
              })
              .join(' ');
        }

        final selection = _textController.selection;
        _textController.value = _textController.value.copyWith(
          text: transformed,
          selection: selection.copyWith(
            baseOffset: selection.baseOffset.clamp(0, transformed.length),
            extentOffset: selection.extentOffset.clamp(0, transformed.length),
          ),
          composing: TextRange.empty,
        );
      },
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      textInputAction: multiline ? TextInputAction.newline : textInputAction,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: multiline ? null : maxLines,
      minLines: multiline ? null : maxLines,
      expands: multiline,
    );
  }
}
