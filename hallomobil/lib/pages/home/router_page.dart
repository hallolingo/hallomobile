import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/pages/dictionary/dictionary_page.dart';
import 'package:hallomobil/pages/home/education_page.dart';
import 'package:hallomobil/pages/home/home_page.dart';
import 'package:hallomobil/pages/profile/profile_page.dart';
import 'package:hallomobil/pages/translate/translate_page.dart';
import 'package:hallomobil/pages/videos/videos_page.dart';
import 'package:hallomobil/widgets/router/router/bottom_nav_bar.dart';
import 'package:hallomobil/widgets/router/router/custom_fab.dart';

class RouterPage extends StatefulWidget {
  final int initialIndex; // Başlangıç sekmesi parametresi

  const RouterPage({super.key, this.initialIndex = 0});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  int _selectedIndex = 0;
  User? _currentUser;
  DocumentSnapshot? _userData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Başlangıç sekmesini ayarla
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _currentUser = user;
        _userData = userData;
      });
    }
  }

  final List<Widget> _pages = [
    const HomePage(),
    const TranslationPage(),
    const DictionaryPage(),
    const EducationPage(),
    const ProfilePage(),
  ];

  // Kullanıcı verisini alt sayfalara ileten yeni metod
  Widget _buildPageWithUserData(Widget page) {
    return page is HomePage
        ? HomePage(user: _currentUser, userData: _userData)
        : page is ProfilePage
            ? ProfilePage(user: _currentUser, userData: _userData)
            : page;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: _buildPageWithUserData(_pages[_selectedIndex]),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: CustomFloatingActionButton(
        heroTag: 'router_tag',
        isSelected: _selectedIndex == 4,
        onPressed: () => _onItemTapped(4),
        user: _currentUser,
        photoUrl: _userData?['photoUrl'],
        userName: _userData?['name'],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
