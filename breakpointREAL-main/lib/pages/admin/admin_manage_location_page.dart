import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add_billiard_hall_page.dart';
import 'admin_edit_billiard_hall_page.dart';
import 'admin_view_billiard_hall_page.dart';
import 'admin_scaffold_wrapper.dart';

class AdminManageLocationPage extends StatefulWidget {
  const AdminManageLocationPage({super.key});

  @override
  State<AdminManageLocationPage> createState() => _AdminManageLocationPageState();
}

class _AdminManageLocationPageState extends State<AdminManageLocationPage> {
  bool showArchived = false;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Manage Billiard Halls',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminAddBilliardHallPage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Billiard Hall"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => showArchived = !showArchived),
                  child: Text(
                    showArchived ? "Show Active" : "Show Archived",
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by hall name...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
              ),
              onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('billiard_halls').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: mintGreen));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final address = data['address']?.toString().toLowerCase() ?? '';
                  final isArchived = data['isArchived'] ?? false;
                  return isArchived == showArchived && (_search.isEmpty || name.contains(_search) || address.contains(_search));
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "It's empty, add a new one!",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'No Name';
                    final address = data['address'] ?? 'No Address';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminViewBilliardHallPage(hallId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: mintGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
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
          ),
        ],
      ),
    );
  }
}
