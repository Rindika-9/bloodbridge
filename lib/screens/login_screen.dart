import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import Screens
import 'home_screen.dart';
import 'register_screen.dart';

// 🔴 Theme Colors
const Color kDarkPrimaryRed = Color(0xFF8B0000);
const Color kLightBg = Color(0xFFF5F5F5);
const Color kAccentWhite = Colors.white;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔐 Starting login...');

      // 🔐 Sign in with email + password
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('✅ Login successful for: ${cred.user?.email}');

      // 🔔 Get FCM token (with timeout)
      try {
        final token = await FirebaseMessaging.instance.getToken().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ FCM token timeout');
            return null;
          },
        );

        print('📱 FCM Token: ${token ?? "null"}');

        if (token != null && cred.user != null) {
          // 💾 Save token to Firestore (users collection)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set(
            {
              'email': cred.user!.email,
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          ).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ Firestore save timeout');
            },
          );
          print('💾 User data saved to Firestore');
        }
      } catch (e) {
        print('⚠️ FCM/Firestore error (non-critical): $e');
        // Don't block login if FCM fails
      }

      if (!mounted) return;

      print('🚀 Navigating to home screen...');

      // Navigate to home screen
      try {
        await Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } catch (e) {
        print('❌ Navigation error: $e');
        // Fallback navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, RegisterScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final existingUser = _currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B0616),
                    Color(0xFFB31217),
                    Color(0xFFFF5F3D),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(painter: _FadedCheckerPainter()),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    Text(
                      "BloodBridge",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: kAccentWhite,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Connecting donors with those in need",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    const SizedBox(height: 50),

                    Container(
                      padding: const EdgeInsets.all(24),
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: kAccentWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (existingUser != null) ...[
                            TextButton.icon(
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(
                                      context, HomeScreen.routeName),
                              icon: const Icon(
                                Icons.person,
                                color: kDarkPrimaryRed,
                              ),
                              label: Text(
                                "Continue as ${existingUser.email?.split('@').first}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kDarkPrimaryRed,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: "Email",
                                    filled: true,
                                    fillColor: kLightBg,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: kDarkPrimaryRed,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? "Invalid email"
                                      : null,
                                ),
                                const SizedBox(height: 15),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    filled: true,
                                    fillColor: kLightBg,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: kDarkPrimaryRed,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: kDarkPrimaryRed,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? "Min 6 chars"
                                      : null,
                                ),
                                const SizedBox(height: 25),

                                // Sign in button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kDarkPrimaryRed,
                                      foregroundColor: kAccentWhite,
                                      disabledBackgroundColor: kDarkPrimaryRed.withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: kAccentWhite,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                        : const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Create account
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _goToRegister,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: kDarkPrimaryRed,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        color: kDarkPrimaryRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Background faded checker
class _FadedCheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const double squareSize = 25;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        bool isSquare =
            ((x / squareSize).floor() % 2 == 0) ==
                ((y / squareSize).floor() % 2 == 0);

        if (isSquare) {
          double opacity = (1.0 - (x / size.width)) * 0.15;
          if (opacity < 0) opacity = 0;

          paint.color = Colors.black.withOpacity(opacity);
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}