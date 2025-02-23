import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextInputType keyboardType;
  final bool autovalidate;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final IconButton? suffixIcon;
  final VoidCallback? onTapOutside;
  final bool obscureText;
  final int? maxLength;
  final String? counterText;
  final int? maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? disabledBorder;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? labelStyle;
  final TextStyle? style;

  final String? prefixText;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.hintStyle,
    this.keyboardType = TextInputType.text,
    this.autovalidate = false,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onTapOutside,
    this.obscureText = false,
    this.maxLength,
    this.counterText,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
    this.filled = true,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.disabledBorder,
    this.contentPadding,
    this.labelStyle,
    this.style,
    this.prefixText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      autovalidateMode: autovalidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      onTapOutside: (focusNode) {
        FocusScope.of(context).unfocus();
        onTapOutside?.call();
      },
      cursorColor: Colors.white,
      focusNode: focusNode,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        counterText: counterText,
        prefixText: prefixText,
        labelText: labelText,
        labelStyle: labelStyle ??
            TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
        hintText: hintText,
        hintStyle: hintStyle ??
            TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
        filled: filled,
        fillColor: fillColor ?? Colors.white.withOpacity(0.1),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: Colors.white,
              )
            : null,
        border: border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
        enabledBorder: enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
        focusedBorder: focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
        disabledBorder: disabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 1,
              ),
            ),
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
      ),
      style: style ??
          TextStyle(
            decorationThickness: 0,
            color: Colors.white,
          ),
      validator: validator,
    );
  }
}
