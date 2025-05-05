import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CustomGoogleAccountPicker extends StatelessWidget {
  final List<GoogleSignInAccount> accounts;
  final Function(GoogleSignInAccount) onAccountSelected;
  final Function() onAddAccount;

  const CustomGoogleAccountPicker({
    super.key,
    required this.accounts,
    required this.onAccountSelected,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesap Seçin',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Google hesabınızı seçin veya yeni bir hesap ekleyin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Accounts List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: accounts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: account.photoUrl != null
                        ? NetworkImage(account.photoUrl!)
                        : null,
                    child: account.photoUrl == null
                        ? Text(account.displayName?[0] ?? '?',
                            style: const TextStyle(fontSize: 18))
                        : null,
                  ),
                  title: Text(
                    account.displayName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    account.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => onAccountSelected(account),
                );
              },
            ),
          ),

          // Add Account Button
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            leading: const Icon(Icons.add, size: 24),
            title: const Text(
              'Yeni Hesap Ekle',
              style: TextStyle(fontSize: 16),
            ),
            onTap: onAddAccount,
          ),

          // Footer
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'HALLOLINGO, Google hesabınızı kullanarak giriş yapmanıza olanak tanır.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: InkWell(
              onTap: () {
                // Handle "Already have an account" action
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  children: const [
                    TextSpan(text: 'Zaten bir hesabınız var mı? '),
                    TextSpan(
                      text: 'Giriş yapın',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
