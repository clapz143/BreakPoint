import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:http/http.dart' as http;
import '../../session_service.dart';
import 'user_scaffold_wrapper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool isTrackingEnabled = false;
  bool isLoading = true;
  bool isManualEditEnabled = true;
  LatLng _selectedLatLng = LatLng(14.5995, 120.9842);
  String _autoDetectedCity = '';
  String _errorMessage = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final session = await SessionService.getUserSession();
    final userId = session['userId'];
    if (userId == null || userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      _locationController.text = session['location'] ?? '';
      isTrackingEnabled = session['locationTracking'] == 'true';
      _autoDetectedCity = session['autoDetectedLocation'] ?? '';
      _selectedLatLng = LatLng(
        double.tryParse(session['selectedLat'] ?? '14.5995') ?? 14.5995,
        double.tryParse(session['selectedLng'] ?? '120.9842') ?? 120.9842,
      );
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final session = await SessionService.getUserSession();
    final uid = session['userId'];
    if (uid == null || uid.isEmpty) {
      setState(() => _errorMessage = 'User ID missing.');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please select or enter a location.');
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'location': _locationController.text.trim(),
      'locationTracking': isTrackingEnabled,
      'selectedLat': _selectedLatLng.latitude,
      'selectedLng': _selectedLatLng.longitude,
    });

    await SessionService.saveUserSession(
      userId: uid,
      role: session['role'] ?? '',
      firstName: session['firstName'] ?? '',
      username: session['username'] ?? '',
      profileImageUrl: session['profileImageUrl'] ?? '',
      location: _locationController.text.trim(),
      locationTracking: isTrackingEnabled.toString(),
      selectedLat: _selectedLatLng.latitude.toString(),
      selectedLng: _selectedLatLng.longitude.toString(),
      autoDetectedLocation: session['autoDetectedLocation'] ?? '',
    );


    if (isTrackingEnabled) {
      await _updateCurrentCityFromLatLng();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved.")),
    );

    await _loadUserSettings();
  }


  Future<void> _updateCurrentCityFromLatLng() async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${_selectedLatLng.latitude}&lon=${_selectedLatLng.longitude}&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'flutter-breakpoint'});
      final data = jsonDecode(response.body);
      final city = data['address']['city'] ??
          data['address']['town'] ??
          data['address']['village'] ??
          data['address']['county'] ??
          'Unknown';

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'autoDetectedLocation': city,
        });

        final session = await SessionService.getUserSession();
        await SessionService.saveUserSession(
          userId: session['userId'] ?? '',
          role: session['role'] ?? '',
          firstName: session['firstName'] ?? '',
          username: session['username'] ?? '',
          profileImageUrl: session['profileImageUrl'] ?? '',
          location: session['location'] ?? '',
          locationTracking: session['locationTracking'] ?? '',
          selectedLat: session['selectedLat'] ?? '',
          selectedLng: session['selectedLng'] ?? '',
          autoDetectedLocation: city,
        );
      }

      setState(() => _autoDetectedCity = city);
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${latlng.latitude}&lon=${latlng.longitude}&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'flutter-breakpoint'});
      final data = jsonDecode(response.body);
      final address = data['display_name'] ?? '';
      setState(() {
        _locationController.text = address;
        isManualEditEnabled = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get address from pin.');
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) return;
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json');
    final response = await http.get(url, headers: {'User-Agent': 'flutter-breakpoint'});
    final List results = jsonDecode(response.body);
    setState(() {
      _searchResults = results.map((e) => {
        'label': e['display_name'],
        'lat': double.parse(e['lat']),
        'lon': double.parse(e['lon']),
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const mintGreen = Color(0xFFB5FDCB);
    return UserScaffoldWrapper(
      title: "Settings",
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: mintGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search location',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _searchPlaces,
            ),
            if (_searchResults.isNotEmpty)
              ..._searchResults.map((res) => ListTile(
                title: Text(res['label'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  final latlng = LatLng(res['lat'], res['lon']);
                  setState(() {
                    _selectedLatLng = latlng;
                    _locationController.text = res['label'];
                    _searchResults.clear();
                    _searchController.clear();
                    isManualEditEnabled = false;
                  });
                },
              )),
            const SizedBox(height: 25),
            TextField(
              controller: _locationController,
              enabled: isManualEditEnabled,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Manual or Selected Location',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_autoDetectedCity.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Detected Location: $_autoDetectedCity", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Enable Location Tracking", style: TextStyle(color: Colors.white)),
              activeColor: mintGreen,
              value: isTrackingEnabled,
              onChanged: (val) => setState(() => isTrackingEnabled = val),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedLatLng,
                    initialZoom: 13,
                    onTap: (tapPosition, latlng) {
                      setState(() => _selectedLatLng = latlng);
                      _reverseGeocode(latlng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: CancellableNetworkTileProvider(),
                      userAgentPackageName: 'com.example.breakpoint',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: _selectedLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                      )
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text("Save Settings"),
              style: ElevatedButton.styleFrom(
                backgroundColor: mintGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
