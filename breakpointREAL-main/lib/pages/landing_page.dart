import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_billiard_hall_page.dart';
import 'users/account_settings_page.dart';
import '../session_service.dart';
import 'users/user_scaffold_wrapper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String firstName = '';
  String userLocation = '';
  List<Map<String, dynamic>> halls = [];
  List<String> filters = [];
  String selectedFilter = '';
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndHalls();
  }

  Future<List<Map<String, dynamic>>> _getTopRatedHalls() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('billiard_halls')
        .where('isArchived', isEqualTo: false)
        .get();

    final hallsWithRatings = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final hallId = doc.id;
      final hallData = doc.data();

      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('hallId', isEqualTo: hallId)
          .get();

      final ratings = ratingsSnapshot.docs
          .map((r) => (r.data()['stars'] ?? 0) as num)
          .toList();

      if (ratings.isEmpty) continue;

      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      hallsWithRatings.add({
        'id': hallId,
        'name': hallData['name'] ?? 'Unnamed',
        'address': hallData['address'] ?? '',
        'city': hallData['city'] ?? '',
        'images': List<String>.from(hallData['photoUrls'] ?? []),
        'rating': avgRating.toStringAsFixed(1),
      });
    }

    hallsWithRatings.sort((a, b) => double.parse(b['rating'])
        .compareTo(double.parse(a['rating'])));

    return hallsWithRatings.take(10).toList();
  }



  Future<void> _loadUserAndHalls() async {
    final session = await SessionService.getUserSession();
    setState(() {
      firstName = session['firstName'] ?? 'User';
      userLocation = session['location'] ?? '';
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('billiard_halls')
        .where('isArchived', isEqualTo: false)
        .get();

    final uniqueCities = <String>{};

    halls = snapshot.docs.map((doc) {
      final data = doc.data();
      final city = data['city'] ?? '';
      if (city.isNotEmpty) uniqueCities.add(city);
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unnamed',
        'address': data['address'] ?? '',
        'bio': data['bio'] ?? '',
        'city': city,
        'images': List<String>.from(data['photoUrls'] ?? []),
      };
    }).toList();

    setState(() {
      filters = uniqueCities.toList();
      selectedFilter = filters.isNotEmpty ? filters.first : '';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF34C759);

    return UserScaffoldWrapper(
      title: 'Browse Billiard Halls',
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: greenColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a billiard hall',
                hintStyle: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (userLocation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_pin, color: Color(0xFF34C759), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        userLocation,
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                final isSelected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                  selectedColor: Colors.white,
                  backgroundColor: const Color(0xFF2C2C2E),
                  avatar: isSelected
                      ? const CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 10,
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  )
                      : null,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),



            // Top Rated Section
            if (searchQuery.isEmpty)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getTopRatedHalls(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final topHalls = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Rated',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: topHalls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final hall = topHalls[index];
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
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, size: 14, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${hall['rating']}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
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
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),




            // Venue List
            const Text(
              'Discover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            ..._filteredHalls().map((hall) {
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
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: coverImage.startsWith('http')
                              ? Image.network(
                            coverImage,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default.jpg',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            coverImage,
                            height: 150,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (_filteredHalls().isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'There are no available billiard places!',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredHalls() {
    return halls.where((hall) {
      final matchesSearch = hall['name'].toLowerCase().contains(searchQuery) ||
          hall['address'].toLowerCase().contains(searchQuery);
      final matchesFilter = selectedFilter.isEmpty || hall['city'] == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }
}
