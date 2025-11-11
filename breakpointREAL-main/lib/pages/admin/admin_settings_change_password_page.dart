import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_sample_one/session_service.dart';
import 'admin_scaffold_wrapper.dart';

class AdminSettingsChangePasswordPage extends StatefulWidget {
  const AdminSettingsChangePasswordPage({super.key});

  @override
  State<AdminSettingsChangePasswordPage> createState() => _AdminSettingsChangePasswordPageState();
}

class _AdminSettingsChangePasswordPageState extends State<AdminSettingsChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String firstName = '';
  String userId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getUserSession();
    userId = session['userId'] ?? '';
    firstName = session['firstName'] ?? '';
    setState(() => isLoading = false);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _changePassword() async {
    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New and confirm password do not match")),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return;

    final currentHash = data['password'];
    final oldHash = _hashPassword(oldPass);

    if (oldHash != currentHash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current password is incorrect")),
      );
      return;
    }

    final newHash = _hashPassword(newPass);
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'password': newHash,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password updated successfully")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Change Password',
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
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Text(
                  firstName,
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
              'Change password',
              style: TextStyle(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),

            TextField(
              controller: oldPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your old password',
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
              controller: newPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter new password',
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
              controller: confirmPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
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
                onPressed: _changePassword,
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
