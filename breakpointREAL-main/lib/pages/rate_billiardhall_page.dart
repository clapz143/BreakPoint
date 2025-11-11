import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample_one/session_service.dart';

class RateBilliardHallPage extends StatefulWidget {
  final String hallId;
  const RateBilliardHallPage({super.key, required this.hallId});

  @override
  State<RateBilliardHallPage> createState() => _RateBilliardHallPageState();
}

class _RateBilliardHallPageState extends State<RateBilliardHallPage> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _submitting = false;

  Future<void> _submitRating() async {
    final session = await SessionService.getUserSession();
    final userId = session['userId'] ?? '';

    if (_selectedRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give a rating and comment')),
      );
      return;
    }

    setState(() => _submitting = true);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    final firstName = userData['firstName'] ?? 'Anonymous';
    final lastName = userData['lastName'] ?? '';
    final username = userData['username'] ?? '';
    final profileImageUrl = userData['profileImageUrl'] ?? '';

    final ratingData = {
      'hallId': widget.hallId,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'comment': _commentController.text.trim(),
      'stars': _selectedRating,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('ratings')
        .add(ratingData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your review!')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How was your experience?',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = starIndex),
                  icon: Icon(
                    _selectedRating >= starIndex ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mintGreen,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  'Submit Review',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
