import 'package:flutter/material.dart';
import 'package:flutter_sample_one/pages/admin/admin_manage_location_page.dart';
import 'package:flutter_sample_one/pages/admin/admin_setting_display_page.dart';
import 'package:flutter_sample_one/pages/login_page.dart';
import 'package:flutter_sample_one/session_service.dart';

import 'admin_dashboard_page.dart';

class AdminScaffoldWrapper extends StatelessWidget {
  final Widget body;
  final String title;
  final VoidCallback? onAddPressed;

  const AdminScaffoldWrapper({
    super.key,
    required this.body,
    required this.title,
    this.onAddPressed,
  });

  String _getGreetingMessage(String firstName) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $firstName!';
    if (hour < 17) return 'Good afternoon, $firstName!';
    return 'Good evening, $firstName!';
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return FutureBuilder<Map<String, String>>(
      future: SessionService.getUserSession(),
      builder: (context, snapshot) {
        final firstName = snapshot.data?['firstName'] ?? 'Admin';
        final profileImage = snapshot.data?['profileImageUrl'] ?? '';

        return Scaffold(
          backgroundColor: darkBg,
          drawer: Drawer(
            backgroundColor: darkBg,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 30),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: mintGreen,
                    backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.black)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 30),
                _drawerItem(context, Icons.home, 'Dashboard', () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                  );
                }),
                _drawerItem(context, Icons.place, 'View Billiards Halls', () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminManageLocationPage()),
                  );
                }),
                _drawerItem(context, Icons.person, 'Profile', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsPage()));
                }),
                _drawerItem(context, Icons.logout, 'Logout', () async {
                  await SessionService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                }),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: darkBg,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _getGreetingMessage(firstName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 20,
                fontFamily: 'Montserrat',
              ),
            ),
            actions: [
              if (onAddPressed != null)
                IconButton(
                  icon: const Icon(Icons.add, color: mintGreen),
                  onPressed: onAddPressed,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: mintGreen,
                  backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                  radius: 18,
                  child: profileImage.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
