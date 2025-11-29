import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import 'chat_screen.dart';
import 'register_donor_screen.dart';
import 'login_screen.dart';

// ===== COLORS (medical + blood theme) =====
const Color kBgTopRed = Color(0xFFB00020);
const Color kBgBottomRed = Color(0xFF4A0000);
const Color kCardBackground = Color(0xFFFDFDFD);
const Color kAccentRed = Color(0xFFE53935);
const Color kAccentGreen = Color(0xFF43A047);
const Color kAccentBlue = Color(0xFF1E88E5);
const Color kAccentGrey = Color(0xFF757575);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
              style: TextStyle(color: Colors.red),
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
        content: const Text('Language support coming soon (English / Mizo).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===== MODERN MEDICAL SETTINGS UI =====

  Widget _buildSettingsTab() {
    return Column(
      children: [
        // Top hero area (no AppBar, just custom header)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
                      'Manage your donor profile & app settings',
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
                            Navigator.pushNamed(
                              context,
                              RegisterDonorScreen.routeName,
                            );
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
    );
  }

  // ===== BODY FOR EACH TAB =====

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const ProfileScreen();
      case 1:
        return const ChatScreen();
      case 2:
      // Settings tab with modern UI, no AppBar
        return _buildSettingsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTANT: no appBar here at all
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgTopRed, kBgBottomRed],
          ),
        ),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ===== REUSABLE SETTINGS TILE WIDGET =====

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
