import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallomobil/app_router.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/widgets/custom_snackbar.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  final DocumentSnapshot? userData;

  const ProfilePage({
    super.key,
    this.user,
    this.userData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> _levelData;
  late Map<String, dynamic> _skills;

  @override
  void initState() {
    super.initState();
    _levelData = widget.userData?['level'] ?? {};
    _skills = _levelData['skills'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ayarlar sayfasına yönlendirme
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildLevelProgress(),
            const SizedBox(height: 24),
            _buildSkillsProgress(),
            const SizedBox(height: 24),
            _buildAccountActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(widget.user?.photoURL ??
              widget.userData?['photoUrl'] ??
              'assets/default_profile.png'),
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user?.displayName ?? widget.userData?['name'] ?? 'Misafir',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.user?.email ?? 'E-posta bilgisi yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                _levelData['currentLevel']?.toString().toUpperCase() ??
                    'BAŞLANGIÇ',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: ColorConstants.MAINCOLOR,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelProgress() {
    final progress = _levelData['progress'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Genel İlerleme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(ColorConstants.MAINCOLOR),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Tamamlandı',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${_levelData['currentLevel'] ?? 'Başlangıç'} Seviyesi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beceri İlerlemeleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSkillItem('Okuma', _skills['reading']?['progress'] ?? 0.0),
            _buildSkillItem('Yazma', _skills['writing']?['progress'] ?? 0.0),
            _buildSkillItem(
                'Dinleme', _skills['listening']?['progress'] ?? 0.0),
            _buildSkillItem('Gramer', _skills['grammar']?['progress'] ?? 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItem(String title, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.MAINCOLOR),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Tamamlandı',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.MAINCOLOR,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // Profil düzenleme sayfasına yönlendirme
          },
          child: const Text(
            'Profili Düzenle',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.red[400]!),
          ),
          onPressed: _showLogoutDialog,
          child: Text(
            'Çıkış Yap',
            style: TextStyle(color: Colors.red[400]),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content:
            const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Giriş sayfasına yönlendirme yapılabilir
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRouter.login, (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  showCustomSnackBar(
                    context: context,
                    message: 'Çıkış yapılırken hata oluştu: ${e.toString()}',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
