import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sample_one/pages/admin/admin_manage_location_page.dart';
import 'package:flutter_sample_one/pages/admin/admin_manage_requests_page.dart';
import 'package:flutter_sample_one/pages/admin/admin_scaffold_wrapper.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  int _userCount = 0;
  int _activeHallsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final ratingsSnapshot = await FirebaseFirestore.instance.collection('ratings').get();
    final ratedHallIds = ratingsSnapshot.docs.map((doc) => doc['hallId']).toSet();

    final hallsSnapshot = await FirebaseFirestore.instance.collection('billiard_halls').get();
    final activeHalls = hallsSnapshot.docs.where((doc) =>
    !(doc.data()['isArchived'] ?? false) && ratedHallIds.contains(doc.id));

    setState(() {
      _userCount = usersSnapshot.size;
      _activeHallsCount = activeHalls.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    final stats = [
      {'title': 'Users', 'count': _userCount, 'icon': Icons.person},
      {'title': 'Active Halls', 'count': _activeHallsCount, 'icon': Icons.table_bar},
    ];

    return AdminScaffoldWrapper(
      title: 'Dashboard',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: stats.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  final isCurrent = index == _currentPage;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: isCurrent ? 0 : 20),
                    transform: Matrix4.identity()..scale(isCurrent ? 1.0 : 0.9),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isCurrent ? [BoxShadow(color: mintGreen.withOpacity(0.3), blurRadius: 10)] : [],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(stat['icon'] as IconData, color: mintGreen, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          '${stat['count']}',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(stat['title'] as String, style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminManageLocationPage()),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage Billiard Hall', style: TextStyle(color: mintGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Manage available Billiard Halls', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminManageRequestsPage()),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage Requests', style: TextStyle(color: mintGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Review user-submitted hall requests', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
