import 'package:flutter/material.dart';

class SettingsProfilePicturePage extends StatelessWidget {
  const SettingsProfilePicturePage({super.key});

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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {}, // Add drawer action or Navigator.pop
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: mintGreen,
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                SizedBox(width: 12),
                Text(
                  'Melfred Fonclara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Change profile picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),

            // Large profile circle
            Center(
              child: CircleAvatar(
                radius: 100,
                backgroundColor: mintGreen,
                child: Icon(Icons.person, size: 100, color: greenDark),
              ),
            ),
            const SizedBox(height: 24),

            // Upload button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement file picker / image upload
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Upload a profile picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
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
