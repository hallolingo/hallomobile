import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const NavItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.iconSize = 26,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return IconButton(
      icon: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? selectedColor : unselectedColor,
      ),
      onPressed: () => onTap(index),
      iconSize: iconSize,
      padding: padding,
    );
  }
}
