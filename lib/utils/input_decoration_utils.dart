import 'package:flutter/material.dart';

InputDecoration buildInputDecoration({
  required String labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isDense = false,
  Color? fillColor,
  Color? labelStyleColor,
  Color? hintStyleColor,
  Color? prefixIconColor,
  Color? suffixIconColor,
  Color? enabledBorderColor,
  Color? focusedBorderColor,
  double? borderRadius = 8.0,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: isDense,
    fillColor: fillColor,
    labelStyle: TextStyle(color: labelStyleColor),
    hintStyle: TextStyle(color: hintStyleColor),
    prefixIconColor: prefixIconColor,
    suffixIconColor: suffixIconColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius!),
      borderSide: BorderSide(color: enabledBorderColor ?? Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: focusedBorderColor ?? Colors.blue),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: enabledBorderColor ?? Colors.grey),
    ),
  );
}
