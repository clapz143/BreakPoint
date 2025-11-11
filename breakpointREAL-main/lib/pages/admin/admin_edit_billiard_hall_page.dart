import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'admin_scaffold_wrapper.dart';
import 'admin_view_billiard_hall_page.dart';

class AdminEditBilliardHallPage extends StatefulWidget {
  final String hallId;
  const AdminEditBilliardHallPage({super.key, required this.hallId});

  @override
  State<AdminEditBilliardHallPage> createState() => _AdminEditBilliardHallPageState();
}

bool _nameError = false;
bool _addressError = false;
bool _rateError = false;

class _AdminEditBilliardHallPageState extends State<AdminEditBilliardHallPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<TextEditingController> openingControllers = [];
  final List<TextEditingController> closingControllers = [];
  final List<Map<String, TextEditingController>> rateControllers = [];
  final List<XFile> selectedImages = [];
  final List<String> existingImageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < days.length; i++) {
      openingControllers.add(TextEditingController());
      closingControllers.add(TextEditingController());
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).get();
    final data = doc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      addressController.text = data['address'] ?? '';
      bioController.text = data['bio'] ?? '';
      final hours = data['operating_hours'] ?? {};
      for (int i = 0; i < days.length; i++) {
        openingControllers[i].text = hours[days[i]]?['open'] ?? '';
        closingControllers[i].text = hours[days[i]]?['close'] ?? '';
      }
      final rates = List<Map<String, dynamic>>.from(data['rates'] ?? []);
      for (var rate in rates) {
        final amountText = rate['amount']?.replaceAll('Php ', '') ?? '';
        rateControllers.add({
          'amount': TextEditingController(text: amountText),
          'description': TextEditingController(text: rate['description']),
        });
      }
      if (rateControllers.isEmpty) {
        rateControllers.add({
          'amount': TextEditingController(),
          'description': TextEditingController(),
        });
      }
      final List<dynamic> urls = data['photoUrls'] ?? [];
      existingImageUrls.addAll(urls.map((e) => e.toString()));
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteImage(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      setState(() => existingImageUrls.remove(url));
      await FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).update({
        'photoUrls': existingImageUrls
      });
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> _selectTime(int i, bool isOpening) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      final formatted = time.format(context);
      setState(() {
        if (isOpening) {
          openingControllers[i].text = formatted;
        } else {
          closingControllers[i].text = formatted;
        }
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

  Future<void> _saveData() async {
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    final rateAmount = rateControllers.isNotEmpty ? rateControllers[0]['amount']!.text.trim() : '';
    final rateDesc = rateControllers.isNotEmpty ? rateControllers[0]['description']!.text.trim() : '';

    setState(() {
      _nameError = name.isEmpty;
      _addressError = address.isEmpty;
      _rateError = rateAmount.isEmpty || rateDesc.isEmpty;
    });

    if (_nameError || _addressError || _rateError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in Name, Address, and at least one valid Rate."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    List<String> imageUrls = [];
    for (var image in selectedImages) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('billiard_hall_photos')
          .child(widget.hallId)
          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(image.path));
      }
      imageUrls.add(await ref.getDownloadURL());
    }

    final updated = {
      'name': nameController.text.trim(),
      'address': addressController.text.trim(),
      'bio': bioController.text.trim(),
      'photoUrls': FieldValue.arrayUnion(imageUrls),
      'operating_hours': {
        for (int i = 0; i < days.length; i++)
          days[i]: {
            'open': openingControllers[i].text.trim().isEmpty ? 'NOT AVAILABLE' : openingControllers[i].text.trim(),
            'close': closingControllers[i].text.trim().isEmpty ? 'NOT AVAILABLE' : closingControllers[i].text.trim(),
          }
      },
      'rates': rateControllers.map((c) => {
        'amount': 'Php ${c['amount']!.text.trim()}',
        'description': c['description']!.text.trim()
      }).toList()
    };

    await FirebaseFirestore.instance.collection('billiard_halls').doc(widget.hallId).update(updated);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdminViewBilliardHallPage(hallId: widget.hallId)),
    );
  }

  InputDecoration _inputDecoration(Color bg, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
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
      title: 'Edit Billiard Hall',
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: mintGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uploaded photo/s', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            if (existingImageUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(existingImageUrls[index], width: 150, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => _deleteImage(existingImageUrls[index]),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text('Upload new photo/s', style: TextStyle(color: Colors.white)),
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
            for (int i = 0; i < days.length; i++)
              Padding(
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
                                  openingControllers[i].text.isEmpty ? 'Open' : openingControllers[i].text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                            onPressed: () => setState(() => openingControllers[i].clear()),
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
                                  closingControllers[i].text.isEmpty ? 'Close' : closingControllers[i].text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                            onPressed: () => setState(() => closingControllers[i].clear()),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text('Rates', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            for (int i = 0; i < rateControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: rateControllers[i]['amount'],
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration(_rateError && i == 0 ? Colors.red.shade700 : inputBg, 'Php'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: rateControllers[i]['description'],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(_rateError && i == 0 ? Colors.red.shade700 : inputBg, 'Description'),
                      ),
                    ),
                    if (i > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                        onPressed: () => setState(() => rateControllers.removeAt(i)),
                      )
                  ],
                ),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  rateControllers.add({
                    'amount': TextEditingController(),
                    'description': TextEditingController(),
                  });
                });
              },
              child: const Text(
                'Add another rate',
                style: TextStyle(color: Colors.white60, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
