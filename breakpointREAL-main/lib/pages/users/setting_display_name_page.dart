import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sample_one/session_service.dart';
import '../users/user_scaffold_wrapper.dart';

class SettingDisplayNamePage extends StatefulWidget {
  const SettingDisplayNamePage({super.key});

  @override
  State<SettingDisplayNamePage> createState() => _SettingDisplayNamePageState();
}

class _SettingDisplayNamePageState extends State<SettingDisplayNamePage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  String userId = '';
  String profileImageUrl = '';
  String originalFirstName = '';
  String originalLastName = '';
  String originalUsername = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getUserSession();
    userId = session['userId'] ?? '';
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data != null) {
      originalFirstName = data['firstName'] ?? '';
      originalLastName = data['lastName'] ?? '';
      originalUsername = data['username'] ?? '';
      profileImageUrl = data['profileImageUrl'] ?? '';
      firstNameController.text = originalFirstName;
      lastNameController.text = originalLastName;
      usernameController.text = originalUsername;
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    final updatedFirstName = firstNameController.text.trim();
    final updatedLastName = lastNameController.text.trim();
    final updatedUsername = usernameController.text.trim();

    final updateData = <String, dynamic>{};
    if (updatedFirstName.isNotEmpty && updatedFirstName != originalFirstName) {
      updateData['firstName'] = updatedFirstName;
    }
    if (updatedLastName.isNotEmpty && updatedLastName != originalLastName) {
      updateData['lastName'] = updatedLastName;
    }
    if (updatedUsername.isNotEmpty && updatedUsername != originalUsername) {
      updateData['username'] = updatedUsername;
    }

    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);
      final prefs = await SharedPreferences.getInstance();
      if (updateData.containsKey('firstName')) {
        await prefs.setString('firstName', updatedFirstName);
      }
      if (updateData.containsKey('username')) {
        await prefs.setString('username', updatedUsername);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes to update")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return UserScaffoldWrapper(
      title: 'Change Display Name',
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
                  backgroundColor: mintGreen,
                  radius: 20,
                  backgroundImage: (profileImageUrl.isNotEmpty)
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  originalFirstName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Change display name',
              style: TextStyle(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),
            TextField(
              controller: firstNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'First Name',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Last Name',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: inputBg,
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
