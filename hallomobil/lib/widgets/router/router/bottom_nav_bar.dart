import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/widgets/router/router/nav_item.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: ColorConstants.MAINCOLOR,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onItemTapped,
            selectedColor: ColorConstants.WHITE,
          ),
          NavItem(
            icon: Icons.translate_outlined,
            selectedIcon: Icons.translate,
            index: 1,
            selectedIndex: selectedIndex,
            onTap: onItemTapped,
            selectedColor: ColorConstants.WHITE,
          ),
          NavItem(
            icon: Icons.book_outlined,
            selectedIcon: Icons.book,
            index: 2,
            selectedIndex: selectedIndex,
            onTap: onItemTapped,
            selectedColor: ColorConstants.WHITE,
          ),
          NavItem(
            icon: Icons.video_collection_rounded,
            selectedIcon: Icons.book,
            index: 3,
            selectedIndex: selectedIndex,
            onTap: onItemTapped,
            selectedColor: ColorConstants.WHITE,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.1),
        ],
      ),
    );
  }
}
