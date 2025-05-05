import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  User? _currentUser;
  DocumentSnapshot? _userData;

  @override
  void initState() {
    super.initState();
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
        isSelected: _selectedIndex == 3,
        onPressed: () => _onItemTapped(3),
        user: _currentUser, // Düzeltildi: currentUser -> _currentUser
        photoUrl: _userData?['photoUrl'], // Düzeltildi: userData -> _userData
        userName: _userData?['name'], // Düzeltildi: userData -> _userData
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
