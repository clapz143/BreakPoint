import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_view_request_hall_page.dart';
import 'admin_scaffold_wrapper.dart';

class AdminManageRequestsPage extends StatefulWidget {
  const AdminManageRequestsPage({super.key});

  @override
  State<AdminManageRequestsPage> createState() => _AdminManageRequestsPageState();
}

class _AdminManageRequestsPageState extends State<AdminManageRequestsPage> {
  String _search = '';
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Manage Hall Requests',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search',
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
                const SizedBox(width: 12),
                DropdownButton<String>(
                  dropdownColor: inputBg,
                  value: _filterStatus,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) => setState(() => _filterStatus = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: mintGreen));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = data['requestedByUsername']?.toLowerCase() ?? '';
                  final status = data['status']?.toLowerCase() ?? '';
                  final hallName = data['name']?.toLowerCase() ?? '';
                  final matchesSearch = _search.isEmpty || username.contains(_search) || hallName.contains(_search);
                  final matchesStatus = _filterStatus == 'all' || status == _filterStatus;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No matching requests found.",
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
                    final requestedBy = data['requestedByUsername'] ?? 'Unknown User';
                    final status = data['status'] ?? 'unknown';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminViewRequestHallPage(requestId: doc.id),
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
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Requested By: $requestedBy',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              Text(
                                'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                                style: const TextStyle(color: Colors.amber, fontSize: 12),
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
