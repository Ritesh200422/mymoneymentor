import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  /// Normal email-password login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.dashboard);
        }
      } on FirebaseAuthException catch (e) {
        String message = "Login failed";
        if (e.code == 'user-not-found') {
          message = "No user found for this email";
        } else if (e.code == 'wrong-password') {
          message = "Incorrect password";
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  final GoogleSignIn googleSignIn =
  GoogleSignIn(); // ✅ Mobile: no clientId needed

  /// Google login
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user canceled

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // 🔍 Check Firestore if user with this email exists
        final query = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: user.email)
            .get();

        if (query.docs.isNotEmpty) {
          // ✅ Email already signed up → Dashboard
          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.dashboard);
          }
        } else {
          // ❌ First time Google login → Signup page
          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.signup);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
      }
    }
  }

  InputDecoration buildInputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[300]),
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo + text
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 120,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "MyMoneyMentor",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Continue with Google Button
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: SvgPicture.asset(
                  "assets/icons/Google.svg",
                  width: 24,
                  height: 24,
                ),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Continue with Google",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(225, 1, 241, 149),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                      endIndent: 10,
                    ),
                  ),
                  Text(
                    "or",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 10,
                    ),
                  ),
                ],
              ),

              // Email/Password login form
              Card(
                color: Colors.black,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: buildInputDecoration(
                            label: "Email",
                            hint: "Enter your email",
                          ),
                          validator: (value) =>
                          value!.isEmpty ? "Enter email" : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !_isPasswordVisible,
                          decoration:
                          buildInputDecoration(
                            label: "Password",
                            hint: "Enter your password",
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? "Enter password" : null,
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    3,
                                    221,
                                    137,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.signup);
                                },
                                child: const Text(
                                  "Don’t have an account? Sign Up",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 3, 221, 137),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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