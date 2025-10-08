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
  // final _googleSignIn = GoogleSignIn(scopes: ['email']);

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Normal email-password login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      switch (e.code) {
        case 'user-not-found':
          message = "No account found for this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          message = "Invalid email address.";
          break;
        case 'user-disabled':
          message = "This account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An unexpected error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Google login
  // Future<void> _signInWithGoogle() async {
  //   setState(() {
  //     _isGoogleLoading = true;
  //   });
  //
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       setState(() {
  //         _isGoogleLoading = false;
  //       });
  //       return; // User canceled
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth =
  //     await googleUser.authentication;
  //
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final userCredential =
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //     final user = userCredential.user;
  //
  //     if (user != null) {
  //       // Check if user exists in Firestore
  //       final userDoc = await FirebaseFirestore.instance
  //           .collection("users")
  //           .doc(user.uid)
  //           .get();
  //
  //       if (!mounted) return;
  //
  //       if (userDoc.exists) {
  //         Navigator.pushReplacementNamed(context, Routes.dashboard);
  //       } else {
  //         // Create user document if it doesn't exist
  //         await FirebaseFirestore.instance
  //             .collection("users")
  //             .doc(user.uid)
  //             .set({
  //           'uid': user.uid,
  //           'email': user.email,
  //           'name': user.displayName,
  //           'photoUrl': user.photoURL,
  //           'createdAt': FieldValue.serverTimestamp(),
  //         });
  //
  //         Navigator.pushReplacementNamed(context, Routes.dashboard);
  //       }
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Google Sign-In failed: ${e.message}"),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("Google Sign-In failed: $e"),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isGoogleLoading = false;
  //       });
  //     }
  //   }
  // }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[300]),
      filled: true,
      fillColor: Colors.grey[900],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
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
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        "MyMoneyMentor",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
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
                const SizedBox(height: 40),

                // Continue with Google Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGoogleLoading ? null : null,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : SvgPicture.asset(
                      "assets/icons/Google.svg",
                      width: 24,
                      height: 24,
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        _isGoogleLoading ? "Signing in..." : "Continue with Google",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[600],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "or",
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[600],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Email/Password login form
                Card(
                  color: Colors.grey[900],
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Login with Email",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              label: "Email",
                              hint: "Enter your email",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your email";
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return "Please enter a valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: !_isPasswordVisible,
                            decoration: _buildInputDecoration(
                              label: "Password",
                              hint: "Enter your password",
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your password";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF03DD89),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, Routes.signup);
                              },
                              child: const Text(
                                "Don't have an account? Sign Up",
                                style: TextStyle(
                                  color: Color(0xFF03DD89),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      ),
    );
  }
}

extension on GoogleSignInAuthentication {
  String? get accessToken => null;
}

