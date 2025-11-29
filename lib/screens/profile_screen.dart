import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'search_donor_screen.dart';
import 'info_screen.dart';
import 'about_screen.dart';
import 'register_donor_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 800,
            minHeight: size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F2FF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),

          // listen so displayName changes update live
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snap) {
              final user = snap.data ?? FirebaseAuth.instance.currentUser;

              String displayName;
              if (user == null) {
                displayName = 'Create / Login';
              } else if (user.displayName != null &&
                  user.displayName!.trim().isNotEmpty) {
                displayName = user.displayName!.trim();
              } else {
                displayName = user.email?.split('@').first ?? 'Profile';
              }

              return _buildContent(
                context: context,
                user: user,
                displayName: displayName,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required User? user,
    required String displayName,
  }) {
    final String initials =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔴 BIG PROFILE CARD
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              if (user == null) {
                Navigator.pushNamed(context, RegisterScreen.routeName);
              } else {
                Navigator.pushNamed(context, EditProfileScreen.routeName);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 24,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E5E), Color(0xFFDC1C27)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user == null
                        ? 'Tap to create your account'
                        : 'Tap to update your profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

        const SizedBox(height: 28),

        // ============== OPTIONS LIST ==============
        Expanded(
          child: ListView(
            children: [
              _ProfileBox(
                icon: Icons.person_add_alt_1,
                title: 'Register as Donor',
                subtitle: 'Create or update your donor details.',
                onTap: () {
                  if (user == null) {
                    Navigator.pushNamed(context, RegisterScreen.routeName);
                  } else {
                    Navigator.pushNamed(
                        context, RegisterDonorScreen.routeName);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ProfileBox(
                icon: Icons.search,
                title: 'Search Donor',
                subtitle: 'Find matching donors & send SOS.',
                onTap: () {
                  Navigator.pushNamed(context, SearchDonorScreen.routeName);
                },
              ),
              const SizedBox(height: 12),
              _ProfileBox(
                icon: Icons.info_outline,
                title: 'Info & Eligibility',
                subtitle: 'Know who can donate and when.',
                onTap: () {
                  Navigator.pushNamed(context, InfoScreen.routeName);
                },
              ),
              const SizedBox(height: 12),
              _ProfileBox(
                icon: Icons.groups_3_outlined,
                title: 'About BloodBridge',
                subtitle: 'Learn about this project & vision.',
                onTap: () {
                  Navigator.pushNamed(context, AboutScreen.routeName);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.red, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
