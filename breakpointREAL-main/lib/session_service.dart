import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<Map<String, String>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'role': prefs.getString('role') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'username': prefs.getString('username') ?? '',
      'profileImageUrl': prefs.getString('profileImageUrl') ?? '',
      'location': prefs.getString('location') ?? '',
      'locationTracking': prefs.getString('locationTracking') ?? 'false',
      'selectedLat': prefs.getString('selectedLat') ?? '14.5995',
      'selectedLng': prefs.getString('selectedLng') ?? '120.9842',
      'autoDetectedLocation': prefs.getString('autoDetectedLocation') ?? '',
    };
  }

  static Future<void> saveUserSession({
    required String userId,
    required String role,
    required String firstName,
    required String username,
    String profileImageUrl = '',
    String location = '',
    String locationTracking = 'false',
    String selectedLat = '14.5995',
    String selectedLng = '120.9842',
    String autoDetectedLocation = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('role', role);
    await prefs.setString('firstName', firstName);
    await prefs.setString('username', username);
    await prefs.setString('profileImageUrl', profileImageUrl);
    await prefs.setString('location', location);
    await prefs.setString('locationTracking', locationTracking);
    await prefs.setString('selectedLat', selectedLat);
    await prefs.setString('selectedLng', selectedLng);
    await prefs.setString('autoDetectedLocation', autoDetectedLocation);
  }


  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
