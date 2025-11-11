
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../users/account_settings_page.dart';
import '../admin/admin_edit_billiard_hall_page.dart';
import '../admin/admin_scaffold_wrapper.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';


class AdminViewBilliardHallPage extends StatefulWidget {
  final String hallId;
  const AdminViewBilliardHallPage({super.key, required this.hallId});

  @override
  State<AdminViewBilliardHallPage> createState() => _AdminViewBilliardHallPageState();
}

class _AdminViewBilliardHallPageState extends State<AdminViewBilliardHallPage> {
  int currentIndex = 0;
  bool isArchived = false;

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Billiard Hall Details',
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: mintGreen));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Hall not found", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unnamed';
          final address = data['address'] ?? 'No address';
          final bio = data['bio'] ?? '';
          final operatingHours = data['operating_hours'] as Map<String, dynamic>? ?? {};
          final rates = List<Map<String, dynamic>>.from(data['rates'] ?? []);
          final List<dynamic> photoUrls = List.from(data['photoUrls'] ?? []);
          isArchived = data['isArchived'] == true;

          int _currentIndex = 0; //for carouselOptions

          final now = DateTime.now();
          final today = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][now.weekday - 1];
          final currentTime = TimeOfDay.fromDateTime(now);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoUrls.isNotEmpty
                      ? Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child:
                        StatefulBuilder(
                          builder: (context, setCarouselState) {
                            return Column(
                              children: [
                                CarouselSlider(
                                  items: photoUrls.map((url) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset('assets/images/default.jpg', fit: BoxFit.cover);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                  options: CarouselOptions(
                                    height: 200,
                                    autoPlay: true,
                                    autoPlayInterval: const Duration(seconds: 3),
                                    enableInfiniteScroll: true,
                                    viewportFraction: 1.0,
                                    enlargeCenterPage: false,
                                    scrollPhysics: const BouncingScrollPhysics(),
                                    onPageChanged: (index, reason) {
                                      setCarouselState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(photoUrls.length, (index) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentIndex == index ? Colors.white : Colors.grey,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  )
                      : Image.asset(
                    'assets/images/default.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEditBilliardHallPage(hallId: widget.hallId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('EDIT', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text("Are you sure you want to permanently remove this billiard hall?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remove")),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).delete();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      child: const Text('REMOVE', style: TextStyle(color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(isArchived ? "Unarchive Billiard Hall" : "Archive Billiard Hall"),
                            content: Text(
                                "Are you sure you want to ${isArchived ? 'unarchive' : 'archive'} this billiard hall?"
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirm")),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).update({
                            'isArchived': !isArchived,
                          });
                          setState(() => isArchived = !isArchived);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: Text(
                        isArchived ? 'UNARCHIVE' : 'ARCHIVE',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(address, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (bio.isNotEmpty) ...[
                  const Text('About', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(bio, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                const Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Operating Hours', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                ...operatingHours.entries.map((e) {
                  final open = e.value['open'] ?? 'NOT AVAILABLE';
                  final close = e.value['close'] ?? 'NOT AVAILABLE';
                  final isToday = e.key == today;
                  final isOpen = _isCurrentTimeWithin(open, close, currentTime);
                  return Padding(
                    padding: const EdgeInsets.only(left: 26, top: 2),
                    child: Text(
                      "$open - $close (${e.key})",
                      style: TextStyle(
                        color: isToday && isOpen ? mintGreen : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...rates.map((rate) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "${rate['amount']}   ${rate['description']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isCurrentTimeWithin(String open, String close, TimeOfDay now) {
    try {
      if (open == 'NOT AVAILABLE' || close == 'NOT AVAILABLE') return false;
      final openParts = open.split(RegExp(r'[: ]'));
      final closeParts = close.split(RegExp(r'[: ]'));

      int openHour = int.parse(openParts[0]);
      final openMin = int.parse(openParts[1]);
      final openIsPM = openParts[2].toLowerCase() == 'pm';
      openHour = openHour % 12 + (openIsPM ? 12 : 0);

      int closeHour = int.parse(closeParts[0]);
      final closeMin = int.parse(closeParts[1]);
      final closeIsPM = closeParts[2].toLowerCase() == 'pm';
      closeHour = closeHour % 12 + (closeIsPM ? 12 : 0);

      final openMinutes = openHour * 60 + openMin;
      final closeMinutes = closeHour * 60 + closeMin;
      final nowMinutes = now.hour * 60 + now.minute;

      if (closeMinutes < openMinutes) {
        return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
      } else {
        return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
      }
    } catch (_) {
      return false;
    }
  }
}