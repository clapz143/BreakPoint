import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'session_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String?> signUp(String username, String email, String password, String role, {required String firstName, required String lastName}) async {
    final hashedPassword = _hashPassword(password);

    final existingEmail = await _firestore.collection('users').where('email', isEqualTo: email).get();
    if (existingEmail.docs.isNotEmpty) return null;

    final existingUsername = await _firestore.collection('users').where('username', isEqualTo: username).get();
    if (existingUsername.docs.isNotEmpty) return null;

    final docRef = await _firestore.collection('users').add({
      'username': username,
      'email': email,
      'password': hashedPassword,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': '', // default blank
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final hashedPassword = _hashPassword(password);
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: hashedPassword)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();

    await SessionService.saveUserSession(
      userId: doc.id,
      role: data['role'],
      firstName: data['firstName'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      location: data['location'] ?? '',
      locationTracking: data['locationTracking']?.toString() ?? 'false',
      selectedLat: data['selectedLat']?.toString() ?? '14.5995',
      selectedLng: data['selectedLng']?.toString() ?? '120.9842',
      autoDetectedLocation: data['autoDetectedLocation'] ?? '',
    );

    return {
      'userId': doc.id,
      'username': data['username'],
      'email': data['email'],
      'role': data['role'],
      'firstName': data['firstName'],
      'lastName': data['lastName'],
      'profileImageUrl': data['profileImageUrl'],
    };
  }
}
