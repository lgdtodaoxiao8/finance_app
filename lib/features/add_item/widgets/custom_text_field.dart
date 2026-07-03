import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required super.key,
    this.prefixBackgroundColor,
    this.prefixIcon,
    this.prefixIconColor = Colors.white,
    this.shadowRadis = 3,
    this.errorTextPadding = const EdgeInsetsGeometry.symmetric(horizontal: 20),
    this.counterTextPadding = const EdgeInsetsGeometry.symmetric(
      horizontal: 20,
    ),
    this.fieldBorderRadius = 20,
    this.fieldFontSize = 19,
    this.prefixIconSize = 30,
    this.textPadding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 16,
    ),
    this.prefixPadding = const EdgeInsets.symmetric(horizontal: 6),
    this.keyboardType = TextInputType.text,
    this.validate,
    this.label,
    this.counter,
    this.onChanged,
    required this.hint,
  });

  final void Function()? onChanged;
  final TextInputType keyboardType;
  final EdgeInsetsGeometry textPadding;
  final EdgeInsetsGeometry prefixPadding;
  final EdgeInsetsGeometry errorTextPadding;
  final EdgeInsetsGeometry counterTextPadding;
  final double prefixIconSize;
  final double fieldBorderRadius;
  final double fieldFontSize;
  final double shadowRadis;
  final String hint;
  final String? label;
  final String? counter;
  final String? Function(String)? validate;
  final Color? prefixBackgroundColor;
  final Color? prefixIconColor;
  final IconData? prefixIcon;

  @override
  State<CustomTextField> createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  final _fieldFocusNode = FocusNode();

  final _fieldTextController = TextEditingController();

  String? errorText;

  @override
  void initState() {
    super.initState();

    _fieldFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fieldTextController.dispose();
    super.dispose();
  }

  bool validate() {
    if (widget.validate == null) {
      return true;
    }
    setState(() {
      errorText = widget.validate!(_fieldTextController.text.trim());
    });
    return errorText == null;
  }

  String get text {
    return _fieldTextController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.fieldBorderRadius),
            color: themeFromSeed.scaffoldBackgroundColor,
            border: Border.all(
              width: 2,
              color: _fieldFocusNode.hasFocus
                  ? themeFromSeed.colorScheme.primaryFixedDim
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: widget.shadowRadis,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            children: [
              if (widget.prefixBackgroundColor != null ||
                  widget.prefixIcon != null)
                Container(
                  margin: widget.prefixPadding,
                  padding: EdgeInsets.all(widget.prefixIconSize / 3),
                  decoration: BoxDecoration(
                    color: widget.prefixBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.prefixIcon,
                    size: widget.prefixIconSize,
                    color: widget.prefixIconColor,
                  ),
                ),
              Expanded(
                child: TextField(
                  focusNode: _fieldFocusNode,
                  onTapOutside: (event) {
                    _fieldFocusNode.unfocus();
                  },
                  keyboardType: widget.keyboardType,
                  controller: _fieldTextController,
                  clipBehavior: Clip.hardEdge,
                  style: kTextStyle.copyWith(
                    fontSize: widget.fieldFontSize,
                    color: const Color(0xFF242528),
                  ),
                  onChanged: (event) {
                    widget.onChanged?.call();

                    if (widget.validate == null) {
                      return;
                    }
                    if (errorText == null) {
                      return;
                    }

                    setState(() {
                      errorText = widget.validate!(
                        _fieldTextController.text.trim(),
                      );
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: widget.textPadding,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    hintText: widget.hint,
                    labelText: widget.label,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintStyle: kTextStyle.copyWith(
                      fontSize: widget.fieldFontSize,
                    ),
                    labelStyle: kTextStyle.copyWith(
                      fontSize: widget.fieldFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.validate != null)
              Flexible(
                // fit: FlexFit.loose,
                child: Padding(
                  padding: widget.errorTextPadding,
                  child: Text(
                    errorText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      color: Colors.red[700],
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            // const Spacer(),
            if (widget.counter != null)
              Padding(
                padding: widget.counterTextPadding,
                child: Text(
                  widget.counter ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kTextStyle.copyWith(
                    fontSize: 12.5,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
