import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sample_one/pages/rate_billiardhall_page.dart';
import '../session_service.dart';
import 'all_reviews_page.dart';
import 'users/account_settings_page.dart';
import 'users/user_scaffold_wrapper.dart';
import 'package:intl/intl.dart';

class ViewBilliardHallPage extends StatefulWidget {
  final String hallId;
  const ViewBilliardHallPage({super.key, required this.hallId});

  @override
  State<ViewBilliardHallPage> createState() => _ViewBilliardHallPageState();
}

class _ViewBilliardHallPageState extends State<ViewBilliardHallPage> {
  int currentIndex = 0;
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

          final now = DateTime.now();
          final today = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][now.weekday - 1];
          final currentTime = TimeOfDay.fromDateTime(now);

          int _currentIndex = 0; //for carouselOptions

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
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('ratings')
                      .where('hallId', isEqualTo: widget.hallId)
                      .get(), // get all
                  builder: (context, ratingSnap) {
                    if (ratingSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final allDocs = ratingSnap.data?.docs ?? [];
                    if (allDocs.isEmpty) {
                      return const Text('No ratings yet', style: TextStyle(color: Colors.white70));
                    }

                    final total = allDocs.fold<num>(0, (sum, doc) => sum + (doc['stars'] ?? 0));
                    final avg = (total / allDocs.length).toStringAsFixed(1);

                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text('$avg Rating', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    );
                  },
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
                const SizedBox(height: 24),Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RateBilliardHallPage(hallId: widget.hallId),
                          ),
                        ).then((shouldRefresh) {
                          if (shouldRefresh == true) {
                            setState(() {}); // re-trigger build to refresh reviews
                          }
                        });
                      },
                      icon: const Icon(Icons.rate_review, color: Colors.white),
                      label: const Text('Leave a Rating'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('ratings')
                      .where('hallId', isEqualTo: widget.hallId)
                      .limit(4)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: mintGreen));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('This place has no rating yet! Rate now!', style: TextStyle(color: Colors.white70)),
                        ),
                      );
                    }

                    final totalStars = docs.fold<num>(0, (sum, doc) => sum + (doc['stars'] ?? 0));
                    final average = (totalStars / docs.length).toStringAsFixed(1);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                average,
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final rating = double.parse(average);
                                  return Icon(
                                    index < rating.floor()
                                        ? Icons.star
                                        : (index < rating ? Icons.star_half : Icons.star_border),
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...docs.map((doc) {
                          final firstName = doc['firstName'] ?? 'Anonymous';
                          final lastName = doc['lastName'] ?? '';
                          final fullName = '$firstName ${lastName}'.trim();
                          final reviewUserId = doc['userId'] ?? '';
                          final data = doc.data() as Map<String, dynamic>;
                          final profileImageUrl = data['profileImageUrl'] ?? '';
                          final date = (doc['timestamp'] as Timestamp).toDate();
                          final stars = doc['stars'] ?? 0;
                          final comment = doc['comment'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                                      child: profileImageUrl.isEmpty
                                          ? Text(
                                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fullName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: List.generate(
                                                  5,
                                                      (index) => Icon(
                                                    index < stars ? Icons.star : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat.yMMMMd().format(date),
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ],
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
                                          setState(() {}); // Refresh the reviews
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (docs.length >= 4)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AllReviewsPage(hallId: widget.hallId),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Show All Reviews',
                                  style: TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        const Text(
                          'Discover More Billiard Halls',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('billiard_halls').get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();

                            final halls = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return doc.id != widget.hallId && (data['isArchived'] != true);
                            })
                                .toList()
                              ..shuffle();

                            final discoverHalls = halls.take(6).map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final images = (data['photoUrls'] as List?)?.cast<String>() ?? [];
                              return {
                                'id': doc.id,
                                'name': data['name'] ?? 'Unnamed',
                                'address': data['address'] ?? 'No address',
                                'images': images,
                              };
                            }).toList();

                            return SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: discoverHalls.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final hall = discoverHalls[index];
                                  final coverImage = hall['images'].isNotEmpty
                                      ? hall['images'][0]
                                      : 'assets/images/default.jpg';

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewBilliardHallPage(hallId: hall['id']),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.transparent,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: coverImage.startsWith('http')
                                                ? Image.network(
                                              coverImage,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/default.jpg',
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                                : Image.asset(
                                              coverImage,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hall['name'],
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.place, size: 14, color: Colors.white54),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        hall['address'],
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w300,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                )
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
