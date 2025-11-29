import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import 'chat_screen.dart';
import 'register_donor_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'register_screen.dart';

// Reuse main app colors (same family as login)
const Color kDarkPrimaryRed = Color(0xFF8B0000);
const Color kAccentWhite = Colors.white;

// Extra accent colors for the modern medical UI
const Color kAccentRed = Color(0xFFE53935);
const Color kAccentGreen = Color(0xFF43A047);
const Color kAccentBlue = Color(0xFF1E88E5);
const Color kAccentGrey = Color(0xFF757575);
const Color kCardBackground = Color(0xFFFDFDFD);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ===== SETTINGS ACTIONS =====

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
          (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your BloodBridge account.\n'
              'You may need to log in again if your session is old.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await user.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'requires-recent-login'
                ? 'Please log in again, then try deleting your account.'
                : 'Failed to delete account: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change language'),
        content: const Text('Language change coming soon (English / Mizo).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===== MODERN SETTINGS TAB =====

  Widget _buildSettingsTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            // Hero header (no AppBar, just custom top section)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BloodBridge Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your donor profile and app preferences',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    // Profile & language card
                    Card(
                      elevation: 8,
                      color: kCardBackground,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.edit_rounded,
                              iconBgColor: kAccentBlue.withOpacity(0.12),
                              iconColor: kAccentBlue,
                              title: 'Edit donor profile',
                              subtitle:
                              'Update your donor details or register as a donor',
                              onTap: () {
                                final user =
                                    FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  Navigator.pushNamed(
                                      context, RegisterScreen.routeName);
                                } else {
                                  Navigator.pushNamed(
                                      context, EditProfileScreen.routeName);
                                }
                              },
                            ),
                            const Divider(height: 0),
                            _SettingsTile(
                              icon: Icons.language_rounded,
                              iconBgColor: kAccentGreen.withOpacity(0.12),
                              iconColor: kAccentGreen,
                              title: 'Language',
                              subtitle: 'English / Mizo (coming soon)',
                              onTap: _changeLanguage,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Danger actions card
                    Card(
                      elevation: 8,
                      color: kCardBackground,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.delete_forever_rounded,
                              iconBgColor: kAccentRed.withOpacity(0.10),
                              iconColor: kAccentRed,
                              title: 'Delete account',
                              subtitle:
                              'Permanently remove your BloodBridge account',
                              titleStyle: const TextStyle(
                                color: kAccentRed,
                                fontWeight: FontWeight.w600,
                              ),
                              onTap: _deleteAccount,
                            ),
                            const Divider(height: 0),
                            _SettingsTile(
                              icon: Icons.logout_rounded,
                              iconBgColor: kAccentGrey.withOpacity(0.10),
                              iconColor: kAccentGrey,
                              title: 'Log out',
                              subtitle: 'Sign out from this device',
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Thank you for being a lifesaver ❤️',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== BODY FOR EACH TAB =====

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
      // HOME tab – wrap ProfileScreen in a centered, max-width layout
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const ProfileScreen(),
          ),
        );

      case 1:
        return const ChatScreen();

      case 2:
      // New modern medical UI (no AppBar)
        return _buildSettingsTab();

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTANT: no AppBar anymore → removes "Settings" top bar completely
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF240003),
                    Color(0xFF5A0713),
                    Color(0xFF9A1220),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _FadedCheckerPainter(),
              ),
            ),
          ),
          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDEBEC), // soft red tint
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, -3),
              color: Colors.black12,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kDarkPrimaryRed,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// updated checker painter – now uses dark red instead of black
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

          // dark red tint instead of black
          paint.color = const Color(0xFF550010).withOpacity(opacity);

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

// ===== reusable tile widget for modern settings UI =====

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle ??
                        const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
