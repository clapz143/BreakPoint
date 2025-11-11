import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'admin_scaffold_wrapper.dart';

class AdminAddBilliardHallPage extends StatefulWidget {
  const AdminAddBilliardHallPage({super.key});

  @override
  State<AdminAddBilliardHallPage> createState() => _AdminAddBilliardHallPageState();
}
bool _nameError = false;
bool _addressError = false;
bool _rateError = false;

class _AdminAddBilliardHallPageState extends State<AdminAddBilliardHallPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final List<Map<String, String>> operatingHours = List.generate(7, (index) => {'open': '', 'close': ''});
  final List<Map<String, TextEditingController>> rates = [
    {'amount': TextEditingController(), 'description': TextEditingController()}
  ];
  final List<XFile> selectedImages = [];
  bool _isSaving = false;

  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  Future<void> _selectTime(int i, bool isOpening) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      final formatted = time.format(context);
      setState(() {
        operatingHours[i][isOpening ? 'open' : 'close'] = formatted;
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      setState(() => selectedImages.addAll(files));
    }
  }

  Future<void> _saveHallToFirestore() async {
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    final firstRate = rates.isNotEmpty ? rates[0] : null;
    final rateAmount = firstRate?['amount']?.text.trim() ?? '';
    final rateDesc = firstRate?['description']?.text.trim() ?? '';

    setState(() {
      _nameError = name.isEmpty;
      _addressError = address.isEmpty;
      _rateError = rateAmount.isEmpty || rateDesc.isEmpty;
    });

    if (_nameError || _addressError || _rateError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Name, Address, and at least one valid Rate.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    List<String> imageUrls = [];
    final hallDoc = FirebaseFirestore.instance.collection('billiard_halls').doc();
    final hallId = hallDoc.id;

    for (var image in selectedImages) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('billiard_hall_photos')
          .child(hallId)
          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(image.path), metadata);
      }
      final downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    final hallData = {
      'name': name,
      'address': address,
      'bio': bioController.text.trim(),
      'photoUrls': imageUrls,
      'rates': rates
          .map((rate) => {
        'amount': 'Php ${rate['amount']!.text.trim()}',
        'description': rate['description']!.text.trim()
      })
          .where((r) => r['amount']!.isNotEmpty || r['description']!.isNotEmpty)
          .toList(),
      'operating_hours': {
        for (var i = 0; i < days.length; i++)
          days[i]: {
            'open': operatingHours[i]['open']!.isEmpty ? 'NOT AVAILABLE' : operatingHours[i]['open'],
            'close': operatingHours[i]['close']!.isEmpty ? 'NOT AVAILABLE' : operatingHours[i]['close'],
          }
      },
      'createdAt': FieldValue.serverTimestamp(),
      'isArchived': false,
    };

    await hallDoc.set(hallData);

    setState(() => _isSaving = false);
    Navigator.pop(context);
  }


  InputDecoration _inputDecoration(Color bg, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const inputBg = Color(0xFF2C2C2E);
    const mintGreen = Color(0xFFB5FDCB);

    return AdminScaffoldWrapper(
      title: 'Add a Billiard Hall',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload photo/s', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 150,
                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 24),
            const Text('Name of Billiard Hall', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(_nameError ? Colors.red.shade700 : inputBg, 'Enter name'),
            ),
            const SizedBox(height: 24),
            const Text('Full Address', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration(_addressError ? Colors.red.shade700 : inputBg, 'Enter address'),
            ),
            const SizedBox(height: 24),
            const Text('Bio / Description', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration(inputBg, 'Enter description or promo'),
            ),
            const SizedBox(height: 24),
            const Text('Operating Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...List.generate(days.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(30)),
                      child: Text(days[i], style: const TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(i, true),
                              child: Container(
                                height: 45,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  operatingHours[i]['open']!.isEmpty ? 'Open' : operatingHours[i]['open']!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                            onPressed: () => setState(() => operatingHours[i]['open'] = ''),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(i, false),
                              child: Container(
                                height: 45,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  operatingHours[i]['close']!.isEmpty ? 'Close' : operatingHours[i]['close']!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                            onPressed: () => setState(() => operatingHours[i]['close'] = ''),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text('Rates', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            ...List.generate(rates.length, (i) {
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration(
                          _rateError && i == 0 ? Colors.red.shade700 : inputBg,
                          'Php',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: rates[i]['description'],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          _rateError && i == 0 ? Colors.red.shade700 : inputBg,
                          'Description',
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
            }),
            TextButton(
              onPressed: () => setState(() {
                rates.add({'amount': TextEditingController(), 'description': TextEditingController()});
              }),
              child: const Text(
                'Add another rate',
                style: TextStyle(color: Colors.white60, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 20),
            if (_isSaving)
              const Center(child: CircularProgressIndicator(color: Color(0xFFB5FDCB)))
            else
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveHallToFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5FDCB),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Add Billiard Hall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
