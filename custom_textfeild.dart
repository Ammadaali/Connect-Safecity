import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:connect_safecity/Utils/constants.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validate;
  final Function(String?)? onsave;
  final int? maxLines;
  final bool isPassword;
  final bool enable;
  final bool? check;
  final TextInputType? keyboardtype;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLength;
  final String? helperText;
  final InputDecoration? decoration; // Added decoration property
  final List<TextInputFormatter>?
      inputFormatters; // Added inputFormatters property

  CustomTextField({
    this.helperText,
    this.controller,
    this.check,
    this.enable = true,
    this.focusNode,
    this.hintText,
    this.isPassword = false,
    this.keyboardtype,
    this.maxLines,
    this.onsave,
    this.prefix,
    this.suffix,
    this.textInputAction,
    this.validate,
    this.maxLength,
    this.decoration, // Added decoration property
    this.inputFormatters, // Added inputFormatters property
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLength: maxLength,
      enabled: enable == true ? true : enable,
      maxLines: maxLines == null ? 1 : maxLines,
      onSaved: onsave,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardtype == null ? TextInputType.name : keyboardtype,
      controller: controller,
      validator: validate,
      obscureText: isPassword == false ? false : isPassword,
      decoration: decoration ??
          InputDecoration(
            prefixIcon: prefix,
            suffixIcon: suffix,
            prefixIconColor: Color(0xff273b7a),
            suffixIconColor: Color(0xff273b7a),
            labelText: hintText ?? "hint text..",
            helperText: helperText, // Add this line to show helperText
            labelStyle: TextStyle(color: primaryColor),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Theme.of(context).primaryColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: primaryColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Theme.of(context).primaryColor,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: primaryColor,
              ),
            ),
          ),
      inputFormatters: inputFormatters, // Added inputFormatters property
    );
  }
}
