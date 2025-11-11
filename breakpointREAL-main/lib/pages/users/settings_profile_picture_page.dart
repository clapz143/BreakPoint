import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../session_service.dart';

class SettingsProfilePicturePage extends StatefulWidget {
  const SettingsProfilePicturePage({super.key});

  @override
  State<SettingsProfilePicturePage> createState() => _SettingsProfilePicturePageState();
}

class _SettingsProfilePicturePageState extends State<SettingsProfilePicturePage> {
  String profileImageUrl = '';
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final session = await SessionService.getUserSession();
    setState(() {
      profileImageUrl = session['profileImageUrl'] ?? '';
    });
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => isUploading = true);

    final session = await SessionService.getUserSession();

    if (session['userId'] == null || session['userId']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please re-login.')),
      );
      return;
    }
    final String userId = session['userId']!;


    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');

    if (kIsWeb) {
      final data = await picked.readAsBytes();
      await ref.putData(data);
    } else {
      await ref.putFile(File(picked.path));
    }

    final url = await ref.getDownloadURL();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'profileImageUrl': url,
    });

    // Update local session
    await SessionService.saveUserSession(
      userId: userId,
      role: session['role'] ?? '',
      firstName: session['firstName'] ?? '',
      username: session['username'] ?? '',
      profileImageUrl: url,
      location: session['location'] ?? '',
      locationTracking: session['locationTracking'] ?? '',
      selectedLat: session['selectedLat'] ?? '',
      selectedLng: session['selectedLng'] ?? '',
      autoDetectedLocation: session['autoDetectedLocation'] ?? '',
    );

    setState(() {
      profileImageUrl = url;
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);
    const greenDark = Color(0xFF2C5631);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Account Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profileImageUrl.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: mintGreen,
                  child: const Icon(Icons.person, size: 100, color: greenDark),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: isUploading ? null : _uploadProfilePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: mintGreen)
                    : const Text('Upload a profile picture', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
