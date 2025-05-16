import 'package:flutter/material.dart';

class AccountSettingsCard extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  const AccountSettingsCard({
    super.key,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesap Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: Colors.black54),
              title: const Text('Şifreyi Değiştir',
                  style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
              onTap: onChangePassword,
            ),
            const Divider(height: 1, color: Colors.grey),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hesabı Sil',
                  style: TextStyle(fontSize: 16, color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.red),
              onTap: onDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
