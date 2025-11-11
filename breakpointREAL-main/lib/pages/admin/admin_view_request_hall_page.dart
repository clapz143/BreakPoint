import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_scaffold_wrapper.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AdminViewRequestHallPage extends StatefulWidget {
  final String requestId;
  const AdminViewRequestHallPage({super.key, required this.requestId});

  @override
  State<AdminViewRequestHallPage> createState() => _AdminViewRequestHallPageState();
}

class _AdminViewRequestHallPageState extends State<AdminViewRequestHallPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const mintGreen = Color(0xFFB5FDCB);
    const inputBg = Color(0xFF2C2C2E);

    return AdminScaffoldWrapper(
      title: 'Request Details',
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('requests').doc(widget.requestId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: mintGreen));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unnamed';
          final address = data['address'] ?? 'No address';
          final bio = data['bio'] ?? '';
          final operatingHours = data['operating_hours'] as Map<String, dynamic>? ?? {};
          final rates = List<Map<String, dynamic>>.from(data['rates'] ?? []);
          final List<dynamic> photoUrls = List.from(data['photoUrls'] ?? []);
          final requestedByUsername = data['requestedByUsername'] ?? 'Unknown';
          final status = data['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrls.isNotEmpty)
                  Column(
                    children: [
                      CarouselSlider(
                        items: photoUrls.map((url) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                Text(name, style: const TextStyle(color: mintGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(address, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Text("Requested by: $requestedByUsername", style: const TextStyle(color: Colors.white60)),
                Text("Status: $status", style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                if (bio.isNotEmpty) ...[
                  const Text("Description", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(bio, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                ],
                const Text("Operating Hours", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...operatingHours.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    "${entry.key}: ${entry.value['open']} - ${entry.value['close']}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                )),
                const SizedBox(height: 16),
                const Text("Rates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ...rates.map((rate) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text("${rate['amount']} - ${rate['description']}", style: const TextStyle(color: Colors.white70)),
                )),
                const SizedBox(height: 24),
                if (status == 'pending')
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({'status': 'rejected'});
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Rejected')));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text("REJECT"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          // Move data to billiard_halls
                          final newDoc = FirebaseFirestore.instance.collection('billiard_halls').doc();
                          await newDoc.set({
                            'name': name,
                            'address': address,
                            'bio': bio,
                            'photoUrls': photoUrls,
                            'operating_hours': operatingHours,
                            'rates': rates,
                            'isArchived': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          // Update request status
                          await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({'status': 'accepted'});
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Accepted and Added')));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: mintGreen),
                        child: const Text("ACCEPT", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
