import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../session_service.dart';
import 'users/user_scaffold_wrapper.dart';

class AllReviewsPage extends StatefulWidget {
  final String hallId;
  const AllReviewsPage({super.key, required this.hallId});

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  void _loadCurrentUserId() async {
    final session = await SessionService.getUserSession();
    setState(() {
      currentUserId = session['userId'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return UserScaffoldWrapper(
      title: 'All Reviews',
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('ratings')
            .where('hallId', isEqualTo: widget.hallId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: mintGreen));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No reviews yet!',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final reviewUserId = data['userId'] ?? '';
              final firstName = data['firstName'] ?? 'Anonymous';
              final lastName = data['lastName'] ?? '';
              final profileImageUrl = data['profileImageUrl'] ?? '';
              final date = (data['timestamp'] as Timestamp).toDate();
              final stars = data['stars'] ?? 0;
              final comment = data['comment'] ?? '';
              final fullName = '$firstName $lastName'.trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: mintGreen,
                          backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                          child: profileImageUrl.isEmpty
                              ? Text(
                            firstName.isNotEmpty ? firstName[0] : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.yMMMMd().format(date),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                                (i) => Icon(
                              i < stars ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (reviewUserId == currentUserId)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete your review?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await FirebaseFirestore.instance.collection('ratings').doc(doc.id).delete();
                              setState(() {}); // refresh UI
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
