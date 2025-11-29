import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  static const String routeName = '/info';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ===== RED GRADIENT BACKGROUND =====
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF240003),
                  Color(0xFF5A0713),
                  Color(0xFF9A1220),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ===== BLUR LAYER =====
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.18),
              ),
            ),
          ),

          // ===== FOREGROUND CONTENT =====
          SafeArea(
            child: Column(
              children: [
                // Top: floating back button + title
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Ink(
                        decoration: const ShapeDecoration(
                          shape: CircleBorder(),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.redAccent),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Info & Eligibility',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scroll content
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // WHO CAN DONATE
                        _InfoCard(
                          icon: Icons.volunteer_activism,
                          title: 'Who can donate blood?',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'You can usually donate blood if:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              _Bullet('You are between 18–60 years old.'),
                              _Bullet('You usually weigh 45 kg or more.'),
                              _Bullet(
                                  'You feel well and have no fever or serious illness.'),
                              _Bullet(
                                  'You have not had major surgery or serious illness in recent months.'),
                              _Bullet(
                                  'You are not pregnant or breastfeeding (in most cases).'),
                              SizedBox(height: 14),
                              Text(
                                'Avoid donating blood today if you:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              _Bullet('Have fever, infection or feel unwell.'),
                              _Bullet(
                                  'Recently took strong antibiotics or other heavy medication.'),
                              _Bullet(
                                  'Had a tattoo, piercing or major dental work recently.'),
                              _Bullet(
                                  'Have been advised by a doctor not to donate blood.'),
                              SizedBox(height: 10),
                              Text(
                                'Always follow the advice of local doctors and blood bank experts.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DONOR STATS
                        const _BloodGroupStatsCard(),

                        const SizedBox(height: 16),

                        // BEFORE & AFTER
                        _InfoCard(
                          icon: Icons.health_and_safety,
                          title: 'Before & after donating',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _Bullet(
                                  'Sleep well and eat light food before donating.'),
                              _Bullet(
                                  'Drink plenty of water before and after donation.'),
                              _Bullet(
                                  'Avoid heavy exercise for the rest of the day.'),
                              _Bullet(
                                  'Keep the bandage on your arm for a few hours.'),
                              SizedBox(height: 10),
                              Text(
                                'If you feel dizzy, weak or unwell after donation, '
                                    'sit or lie down and inform a doctor or blood bank staff immediately.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// REUSABLE INFO CARD
// =======================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FF), // soft white / pink card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.redAccent),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// BLOOD GROUP STATS CARD
// =======================================================

class _BloodGroupStatsCard extends StatelessWidget {
  const _BloodGroupStatsCard();

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donors').snapshots(),
      builder: (context, snapshot) {
        // Loading / error states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _InfoCard(
            icon: Icons.bloodtype,
            title: 'Registered donors by blood group',
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _InfoCard(
            icon: Icons.bloodtype,
            title: 'Registered donors by blood group',
            child: Text(
              'Could not load donor data.\nPlease try again later.',
              style: const TextStyle(fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final Map<String, int> counts = {
          for (final bg in _BloodGroupStatsCard._bloodGroups) bg: 0
        };

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final bg = data['bloodGroup'] as String?;
          if (bg != null && counts.containsKey(bg)) {
            counts[bg] = counts[bg]! + 1;
          }
        }

        final total = docs.length;

        return _InfoCard(
          icon: Icons.bloodtype,
          title: 'Registered donors by blood group',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live numbers from BloodBridge donors.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                'Total registered donors: $total',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Responsive grid for blood groups
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width > 900) {
                    crossAxisCount = 4;
                  } else if (width > 600) {
                    crossAxisCount = 3;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: _bloodGroups.map((bg) {
                      final count = counts[bg] ?? 0;
                      return _BloodTile(
                        bloodGroup: bg,
                        count: count,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BloodTile extends StatelessWidget {
  final String bloodGroup;
  final int count;

  const _BloodTile({
    required this.bloodGroup,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F1), Color(0xFFFFE1E1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.red.shade400,
            child: Text(
              bloodGroup,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'donors',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
