import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'venue_details_page.dart';
import 'package:flutter_sample_one/auth_service.dart';
import 'landing_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> venues = [
    {
      'name': 'Pool Hub',
      'image': 'images/poolhub.jpg',
      'rating': '4.5',
      'address': '1006 M. Dela Fuente St, Sampaloc, Manila',
      'area': 'Manila'
    },
    {
      'name': '8Ball Underground',
      'image': 'images/poolhub.jpg',
      'rating': '4.7',
      'address': 'Katipunan Ave, Quezon City',
      'area': 'Quezon City'
    },
    {
      'name': 'Green Felt Lounge',
      'image': 'images/poolhub.jpg',
      'rating': '4.8',
      'address': 'Ortigas Ave, Pasig City',
      'area': 'Pasig'
    },
  ];

  final List<String> filters = ['All', 'Manila', 'Quezon City', 'Pasig'];
  String selectedFilter = 'All';
  String searchQuery = '';
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? username = user?.displayName ?? "Guest";

    final filteredVenues = venues.where((venue) {
      final matchesFilter = selectedFilter == 'All' || venue['area'] == selectedFilter;
      final matchesSearch = venue['name']!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF001C13),
      drawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003720), Color(0xFF001C13)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sports_esports, color: Colors.greenAccent, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    user != null ? "Welcome, $username!" : "8Ball Finder",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user != null ? "You're logged in." : "Your pool hall guide",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),

            if (user == null) ...[
              ListTile(
                leading: const Icon(Icons.login, color: Colors.greenAccent),
                title: const Text("Log In", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.greenAccent),
                title: const Text("Sign Up", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage()));
                },
              ),
            ] else ...[

            ],

            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.sports_gymnastics, color: Colors.greenAccent),
              title: const Text("8Ball Mini-Game", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pool-game');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pool, color: Colors.greenAccent),
              title: const Text("Top Rated", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Handle Top Rated logic or navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined, color: Colors.greenAccent),
              title: const Text("Map View", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Handle Map View logic or navigation
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "© 8Ball Finder 2025",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.greenAccent),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.greenAccent),
            SizedBox(width: 6),
            Text(
              "Metro Manila",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search pool halls...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                  filled: true,
                  fillColor: const Color(0xFF102C22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = filter == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.greenAccent,
                      backgroundColor: const Color(0xFF102C22),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.3),
                        ),
                      ),
                      onSelected: (_) => setState(() => selectedFilter = filter),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingPage()),
                    );
                  },
                  child: const Text(
                    "Go to Landing Page",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),



            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredVenues.length,
                itemBuilder: (context, index) {
                  final venue = filteredVenues[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VenueDetailsPage(
                            name: venue['name']!,
                            image: venue['image']!,
                            address: venue['address']!,
                            rating: double.parse(venue['rating']!),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102C22),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.asset(
                              venue['image']!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber[400], size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      venue['rating']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  venue['name']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 16, color: Colors.white60),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        venue['address']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white60,
                                        ),
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
          ],
        ),
      ),
    );
  }
}
