import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class LoginLandingPage extends StatefulWidget {
  const LoginLandingPage({super.key});

  @override
  State<LoginLandingPage> createState() => _LoginLandingPageState();
}

class _LoginLandingPageState extends State<LoginLandingPage> with SingleTickerProviderStateMixin {
  double _textOpacity = 0.0;
  late AnimationController _ballController;
  late Animation<Offset> _ballOffset;
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();

    _ballController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _ballOffset = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _ballController, curve: Curves.easeOut));
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('firstLaunchDone') != true;

    if (_isFirstLaunch) {
      await prefs.setBool('firstLaunchDone', true);
      Timer(const Duration(milliseconds: 300), () => setState(() => _textOpacity = 1.0));
      _ballController.forward();
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      });
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  void dispose() {
    _ballController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, const Color(0xFF0A1C0F), Colors.green.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Billiard ball sliding in
            Positioned(
              bottom: -30,
              right: 0,
              child: SlideTransition(
                position: _ballOffset,
                child: Image.asset(
                  'assets/images/billiard-ball.png',
                  width: MediaQuery.of(context).size.width * 0.85,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Positioned text
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 32, right: 32, top: 60),
                child: AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    "EVERY\nSHOT\nCOUNTS",
                    style: GoogleFonts.anton(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: 1.5,
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
