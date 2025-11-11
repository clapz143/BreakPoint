import 'package:flutter/material.dart';
import 'package:flutter_sample_one/session_service.dart';
import 'admin_add_billiard_hall_page.dart';
import 'admin_scaffold_wrapper.dart';
import 'admin_setting_display_name_page.dart';
import 'admin_settings_change_password_page.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  String firstName = '';
  String username = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getUserSession();
    setState(() {
      firstName = session['firstName'] ?? '';
      username = session['username'] ?? '';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Account Settings',
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: mintGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: mintGreen,
                  radius: 30,
                  child: Icon(Icons.person, color: Colors.black, size: 30),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _settingsTile(
              icon: Icons.edit,
              label: 'Change display name',
              subtext: 'Set your display name',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettingDisplayNamePage()),
                ).then((_) => _loadSession());
              },
            ),
            _settingsTile(
              icon: Icons.lock,
              label: 'Change password',
              subtext: 'Change your password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettingsChangePasswordPage()),
                );
              },
            ),

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAddBilliardHallPage()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2B1F),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Know a great billiard spot?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Click here to add a location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required String subtext,
    required VoidCallback onTap,
  }) {
    const inputBg = Color(0xFF2C2C2E);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white24)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Text(subtext, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
