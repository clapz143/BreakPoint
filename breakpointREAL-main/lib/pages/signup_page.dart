import 'package:flutter/material.dart';
import 'package:flutter_sample_one/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();

      // 'user' is the default role for new signups
      final docId = await _authService.signUp(
        username,
        email,
        password,
        'user',
        firstName: firstName,
        lastName: lastName,
      );
      setState(() => _isLoading = false);

      if (docId != null) {
        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: docId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email or username already in use.")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Color(0xFFB7F1B9),
                    fontFamily: 'Montserrat',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join the 8Ball Community!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("First Name", Icons.person_outline),
                  validator: (value) => value!.isEmpty ? "Enter your first name" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _lastNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Last Name", Icons.person_outline),
                  validator: (value) => value!.isEmpty ? "Enter your last name" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Username", Icons.person),
                  validator: (value) => value!.isEmpty ? "Enter a username" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration("Email", Icons.email),
                  validator: (value) =>
                  value!.isEmpty || !value.contains("@") ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildPasswordDecoration(
                    "Password",
                    _obscurePassword,
                        () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) =>
                  value!.length < 6 ? "Password must be at least 6 characters" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildPasswordDecoration(
                    "Confirm Password",
                    _obscureConfirmPassword,
                        () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) =>
                  value != _passwordController.text ? "Passwords do not match" : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C584A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("SIGN UP", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
                // const Text(
                //   "or continue with",
                //   style: TextStyle(
                //     color: Colors.greenAccent,
                //     fontSize: 12,
                //     fontFamily: 'Montserrat',
                //   ),
                // ),
                // const SizedBox(height: 12),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     // TODO: Add Google Sign-up logic
                //   },
                //   icon: const Icon(Icons.mail_outline, color: Colors.green),
                //   label: const Text(
                //     "Login with Google",
                //     style: TextStyle(
                //       fontFamily: 'Montserrat',
                //       fontSize: 14,
                //       fontWeight: FontWeight.w600,
                //       color: Colors.green,
                //     ),
                //   ),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.white,
                //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(20),
                //     ),
                //     elevation: 0,
                //   ),
                // ),
                const SizedBox(height: 32),
                const Divider(color: Colors.white30),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Log In",
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: Colors.greenAccent),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _buildPasswordDecoration(
      String hint,
      bool obscure,
      VoidCallback toggle,
      ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: const Icon(Icons.lock, color: Colors.greenAccent),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
        onPressed: toggle,
      ),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
