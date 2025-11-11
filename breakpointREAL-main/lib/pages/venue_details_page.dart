
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VenueDetailsPage extends StatefulWidget {
  final String name;
  final String image;
  final String address;
  final double rating;

  const VenueDetailsPage({
    super.key,
    required this.name,
    required this.image,
    required this.address,
    required this.rating,
  });

  @override
  State<VenueDetailsPage> createState() => _VenueDetailsPageState();
}

class _VenueDetailsPageState extends State<VenueDetailsPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  Future<void> submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _reviewController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('reviews').add({
      'venueName': widget.name.trim(),
      'userName': user.displayName ?? 'Anonymous',
      'userId': user.uid,
      'rating': _selectedRating,
      'comment': _reviewController.text.trim(),
      'timestamp': Timestamp.now(),
    });

    _reviewController.clear();
    setState(() => _selectedRating = 5);
  }

  Stream<QuerySnapshot> getReviews() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Image.asset(
                widget.image,
                width: double.infinity,
                height: screenWidth * 0.35,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Leave a review:", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      int star = index + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: star <= _selectedRating ? Colors.amber : Colors.white24,
                        ),
                        onPressed: () {
                          setState(() => _selectedRating = star);
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write your review here...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF102A1F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Submit"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const Text("Reviews", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: getReviews(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Card(
                        color: const Color(0xFF112F21),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "★ " * (data['rating'] ?? 5),
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['comment'] ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
