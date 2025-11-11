import 'package:flutter/material.dart';
import 'package:flutter_sample_one/pages/users/request_billiard_hall_page.dart';
import 'package:flutter_sample_one/session_service.dart';
import 'settings_change_password_page.dart';
import 'setting_display_name_page.dart';
import 'settings_profile_picture_page.dart';
import '../users/user_scaffold_wrapper.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String firstName = '';
  String username = '';
  String profileImageUrl = '';
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
      profileImageUrl = session['profileImageUrl'] ?? '';
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return UserScaffoldWrapper(
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: mintGreen,
                  backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.black, size: 30)
                      : null,
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
              icon: Icons.camera_alt,
              label: 'Change profile picture',
              subtext: 'Upload a photo of yourself',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsProfilePicturePage()),
                );
              },
            ),
            _settingsTile(
              icon: Icons.edit,
              label: 'Change display name',
              subtext: 'Set your display name',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingDisplayNamePage()),
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
                  MaterialPageRoute(builder: (_) => const SettingChangePasswordPage()),
                );
              },
            ),

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestBilliardHallPage()),
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
                      'Click here to submit a location',
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
