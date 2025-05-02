import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class RememberMeCheckbox extends StatefulWidget {
  final ValueChanged<bool>? onChanged;
  final String label;

  const RememberMeCheckbox({
    super.key,
    this.onChanged,
    required this.label,
  });

  @override
  State<RememberMeCheckbox> createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor:
                ColorConstants.WHITE, // Border color when unchecked
          ),
          child: Checkbox(
            value: _isChecked,
            checkColor: ColorConstants.MAINCOLOR, // Checkmark color
            fillColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return ColorConstants.WHITE; // Background color when checked
                }
                return Colors.transparent; // Background color when unchecked
              },
            ),
            side: BorderSide(
              color: ColorConstants.WHITE, // Border color
              width: 2.0,
            ),
            onChanged: (value) {
              setState(() {
                _isChecked = value!;
              });
              widget.onChanged?.call(_isChecked);
            },
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(color: ColorConstants.WHITE),
        ),
      ],
    );
  }
}
