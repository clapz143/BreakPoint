import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../session_service.dart';
import '../users/user_scaffold_wrapper.dart';
import 'package:flutter_sample_one/session_service.dart';

class RequestBilliardHallPage extends StatefulWidget {
  const RequestBilliardHallPage({super.key});

  @override
  State<RequestBilliardHallPage> createState() => _RequestBilliardHallPageState();
}

class _RequestBilliardHallPageState extends State<RequestBilliardHallPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final operatingHours = List.generate(7, (index) => {'open': '', 'close': ''});
  final rates = [{'amount': TextEditingController(), 'description': TextEditingController()}];
  final selectedImages = <XFile>[];
  bool isSubmitting = false;
  String userId = '';
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = await SessionService.getUserSession();
    setState(() {
      userId = session['userId'] ?? '';
      username = session['username'] ?? '';
    });
  }

  Future<void> _selectTime(int i, bool isOpening) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() {
        operatingHours[i][isOpening ? 'open' : 'close'] = time.format(context);
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => selectedImages.addAll(files));
    }
  }

  Future<void> _submitRequest() async {
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    final bio = bioController.text.trim();
    final hallDoc = FirebaseFirestore.instance.collection('requests').doc();
    final hallId = hallDoc.id;

    setState(() => isSubmitting = true);

    final imageUrls = <String>[];
    for (var image in selectedImages) {
      final ref = FirebaseStorage.instance.ref('requests_photos/$hallId/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(image.path));
      }
      imageUrls.add(await ref.getDownloadURL());
    }

    final data = {
      'name': name,
      'address': address,
      'bio': bio,
      'photoUrls': imageUrls,
      'operating_hours': {
        for (var i = 0; i < days.length; i++)
          days[i]: {
            'open': operatingHours[i]['open']!.isEmpty ? 'NOT AVAILABLE' : operatingHours[i]['open'],
            'close': operatingHours[i]['close']!.isEmpty ? 'NOT AVAILABLE' : operatingHours[i]['close'],
          },
      },
      'rates': rates
          .map((r) => {
        'amount': 'Php ${r['amount']!.text.trim()}',
        'description': r['description']!.text.trim(),
      })
          .where((r) => r['amount']!.isNotEmpty || r['description']!.isNotEmpty)
          .toList(),
      'status': 'pending',
      'requestedBy': userId,
      'requestedByUsername': username,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await hallDoc.set(data);
    setState(() => isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return UserScaffoldWrapper(
      title: 'Request a Billiard Hall',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request A Billiard Hall!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Upload photo/s', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 150,
                decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                child: selectedImages.isNotEmpty
                    ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(selectedImages[index].path, fit: BoxFit.cover, width: 150)
                              : Image.file(File(selectedImages[index].path), fit: BoxFit.cover, width: 150),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => setState(() => selectedImages.removeAt(index)),
                          ),
                        )
                      ],
                    );
                  },
                )
                    : const Center(child: Icon(Icons.upload_rounded, color: Colors.white70, size: 48)),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Name', nameController),
            _buildTextField('Address', addressController, maxLines: 2),
            _buildTextField('Description / Bio', bioController, maxLines: 3),
            const SizedBox(height: 20),
            const Text('Operating Hours', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ...List.generate(7, (i) => _buildOperatingHourRow(i)),
            const SizedBox(height: 20),
            const Text('Rates', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ...rates.asMap().entries.map((entry) => _buildRateRow(entry.key)),
            TextButton(
              onPressed: () => setState(() => rates.add({
                'amount': TextEditingController(),
                'description': TextEditingController(),
              })),
              child: const Text('Add another rate', style: TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 20),
            isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB5FDCB)))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5FDCB),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitRequest,
              child: const Center(
                child: Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: 'Enter $label',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget _buildOperatingHourRow(int i) {
    final day = days[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(day, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(i, true),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      operatingHours[i]['open']!.isEmpty ? 'Open' : operatingHours[i]['open']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => operatingHours[i]['open'] = ''),
              )
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(i, false),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      operatingHours[i]['close']!.isEmpty ? 'Close' : operatingHours[i]['close']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => operatingHours[i]['close'] = ''),
              )
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: rates[i]['amount'],
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Php',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: rates[i]['description'],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          if (i > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
              onPressed: () => setState(() => rates.removeAt(i)),
            )
        ],
      ),
    );
  }
}
