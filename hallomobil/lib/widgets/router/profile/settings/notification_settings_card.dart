import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class NotificationSettingsCard extends StatefulWidget {
  final bool isEmailVerification;
  final bool isSMSVerification;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onSMSChanged;

  const NotificationSettingsCard({
    super.key,
    required this.isEmailVerification,
    required this.isSMSVerification,
    required this.onEmailChanged,
    required this.onSMSChanged,
  });

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
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
              'Bildirim Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: Colors.black54),
              title: const Text('E-posta Bildirimleri',
                  style: TextStyle(fontSize: 16)),
              trailing: Switch(
                value: widget.isEmailVerification,
                onChanged: widget.onEmailChanged,
                activeColor: ColorConstants.MAINCOLOR,
                inactiveTrackColor: Colors.grey[300],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sms_outlined, color: Colors.black54),
              title: const Text('SMS Bildirimleri',
                  style: TextStyle(fontSize: 16)),
              trailing: Switch(
                value: widget.isSMSVerification,
                onChanged: widget.onSMSChanged,
                activeColor: ColorConstants.MAINCOLOR,
                inactiveTrackColor: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
