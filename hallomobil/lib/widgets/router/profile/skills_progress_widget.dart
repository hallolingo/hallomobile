import 'package:flutter/material.dart';
import 'package:hallomobil/widgets/router/profile/skill_item_widget.dart';

class SkillsProgressWidget extends StatelessWidget {
  final Map<String, dynamic> skills;

  const SkillsProgressWidget({
    super.key,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beceri İlerlemeleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SkillItemWidget(
                title: 'Okuma',
                progress: skills['reading']?['progress'] ?? 0.0),
            const Divider(),
            SkillItemWidget(
                title: 'Yazma',
                progress: skills['writing']?['progress'] ?? 0.0),
            const Divider(),
            SkillItemWidget(
                title: 'Dinleme',
                progress: skills['listening']?['progress'] ?? 0.0),
            const Divider(),
            SkillItemWidget(
                title: 'Kelime', progress: skills['words']?['progress'] ?? 0.0),
          ],
        ),
      ),
    );
  }
}
