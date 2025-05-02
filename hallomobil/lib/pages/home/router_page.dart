import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
import 'package:hallomobil/widgets/router/router/nav_item.dart';

class RouterPage extends StatefulWidget {
  const RouterPage({super.key});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  int _selectedIndex = 0;

  // Pages for each navigation item
  final List<Widget> _pages = [
    const HomePage(),
    const TranslationPage(),
    const DictionaryPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: ColorConstants.WHITE,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Button
            NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              index: 0,
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedColor: ColorConstants.MAINCOLOR,
            ),

            // Translation Button
            NavItem(
              icon: Icons.translate_outlined,
              selectedIcon: Icons.translate,
              index: 1,
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedColor: ColorConstants.MAINCOLOR,
            ),

            // Dictionary Button
            NavItem(
              icon: Icons.book_outlined,
              selectedIcon: Icons.book,
              index: 2,
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedColor: ColorConstants.MAINCOLOR,
            ),

            // Empty space for the FAB
            const SizedBox(width: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onItemTapped(3);
        },
        backgroundColor:
            _selectedIndex == 3 ? Colors.red.shade50 : Colors.white,
        elevation: 2,
        shape: const CircleBorder(), // This ensures a perfect circle shape
        child: Icon(
          _selectedIndex == 3 ? Icons.person : Icons.person_outline,
          color: ColorConstants.MAINCOLOR,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
