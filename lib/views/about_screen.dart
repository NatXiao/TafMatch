import 'package:flutter/material.dart';
import 'package:taf_match/utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _developers = [
    (name: 'Flavien', role: 'Mobile & Firebase'),
    (name: 'Natasha', role: 'Mobile & Firebase'),
    (name: 'Joshua', role: 'UI / UX'),
    (name: 'Florian', role: 'Backend & ML'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Barre du haut ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text('About',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                children: [
                  Text('Taf Match',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 4),
                  Text('Version 1.0',
                      style: TextStyle(fontSize: 14, color: colors.muted)),
                  const SizedBox(height: 20),
                  Text(
                    'Taf Match connects students looking for jobs with local '
                    'employers. Built as part of the Mobile Development summer '
                    'school project.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: colors.text),
                  ),
                  const SizedBox(height: 32),

                  Text('Developers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.field,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _developers.length; i++) ...[
                          if (i > 0) Divider(color: colors.border, height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Text(_developers[i].name,
                                    style: TextStyle(fontSize: 15, color: colors.text)),
                                const Spacer(),
                                Text(_developers[i].role,
                                    style: TextStyle(fontSize: 14, color: colors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Made with Flutter · 2026',
                      style: TextStyle(fontSize: 13, color: colors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}