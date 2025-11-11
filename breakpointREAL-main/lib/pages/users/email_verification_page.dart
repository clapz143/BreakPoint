import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';


class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171717);
    const mintGreen = Color(0xFFB5FDCB);

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: mintGreen),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Check your email",
                      style: TextStyle(
                        color: mintGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "We sent a reset link to melbilliard@gmail.com\nenter 5 digit code that mentioned in the email",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: mintGreen, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: mintGreen, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C584A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Reset Password"),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text.rich(
                  TextSpan(
                    text: "Haven't got the email yet? ",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "Resend email",
                        style: TextStyle(color: mintGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
