import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
import 'package:hallomobil/widgets/router/router/bottom_nav_bar.dart';
import 'package:hallomobil/widgets/router/router/custom_fab.dart';

class RouterPage extends StatefulWidget {
  const RouterPage({super.key});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  int _selectedIndex = 0;

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
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: CustomFloatingActionButton(
        isSelected: _selectedIndex == 3,
        onPressed: () => _onItemTapped(3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
