import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sample_one/pages/admin/admin_dashboard_page.dart';
import 'package:flutter_sample_one/pages/login_page.dart';
import 'package:flutter_sample_one/session_service.dart';
import 'firebase_options.dart';

import 'package:flutter_sample_one/pages/landing_page.dart';
import 'package:flutter_sample_one/pages/pool_game_page.dart';
import 'package:flutter_sample_one/pages/first_login_page.dart';
import 'package:flutter_sample_one/session_service.dart';
import 'package:flutter_sample_one/pages/admin/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Breakpoint());
}

class Breakpoint extends StatelessWidget {
  const Breakpoint({super.key});

  Future<Widget> _getInitialScreen() async {
    final session = await SessionService.getUserSession();
    final role = session['role'];
    if (role == 'admin') return const AdminDashboardPage();
    if (role == 'user') return const LandingPage();
    return const LoginLandingPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Breakpoint - 8Ball Venue Finder",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primaryColor: const Color(0xFF28356C),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xE0E35559),
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routes: {
        '/firstlogin': (context) => const LoginLandingPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const LandingPage(),
        '/pool-game': (context) => const PoolGamePage(),
      },
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
            );
          } else {
            return snapshot.data ?? const LoginLandingPage();
          }
        },
      ),
    );
  }
}
