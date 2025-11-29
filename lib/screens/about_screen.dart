import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String routeName = '/about';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // ❌ no AppBar – we design everything inside body
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 900,
                minHeight: size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F2FF),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======== HEADER CARD ========
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E5E), Color(0xFFDC1C27)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // back button row
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'About BloodBridge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.bloodtype_rounded,
                                color: Color(0xFFDC1C27),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'BloodBridge',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Smart Blood Donation & Emergency Support System',
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
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _HeaderChip(icon: Icons.location_on_outlined, label: 'Pilot: Mizoram'),
                            _HeaderChip(icon: Icons.public_rounded, label: 'Vision: All-India'),
                            _HeaderChip(icon: Icons.volunteer_activism_outlined, label: 'Donors • Patients • NGOs'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ======== SECTION: WHAT IS BLOODBRIDGE ========
                  const _SectionTitle('What is BloodBridge?'),
                  const SizedBox(height: 8),
                  const Text(
                    'BloodBridge is a community-driven app that connects blood donors, '
                        'patients, hospitals and NGOs in real-time. The goal is to reduce '
                        'the time taken to find safe, compatible blood during emergencies '
                        'and planned treatments.',
                    style: TextStyle(fontSize: 14.5, height: 1.5),
                  ),

                  const SizedBox(height: 20),

                  // ======== SECTION: HOW IT WORKS ========
                  const _SectionTitle('How does it work?'),
                  const SizedBox(height: 8),
                  _BulletPoint(
                    text:
                    'Donors create a simple profile with blood group, district and contact number.',
                  ),
                  _BulletPoint(
                    text:
                    'During an emergency, families or NGOs can search for compatible donors nearby.',
                  ),
                  _BulletPoint(
                    text:
                    'The app shows matching donors and can be used to send SOS requests.',
                  ),
                  _BulletPoint(
                    text:
                    'Over time, the network grows stronger, making it easier to find help quickly.',
                  ),

                  const SizedBox(height: 20),

                  // ======== SECTION: WHO IS THIS FOR ========
                  const _SectionTitle('Who is this app for?'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _TagPill(icon: Icons.favorite_border, label: 'Voluntary donors'),
                      _TagPill(icon: Icons.local_hospital_outlined, label: 'Hospitals & blood banks'),
                      _TagPill(icon: Icons.groups_outlined, label: 'NGOs & churches'),
                      _TagPill(icon: Icons.family_restroom_outlined, label: 'Patients & families'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ======== SECTION: TECH / PRIVACY ========
                  const _SectionTitle('Safety & privacy'),
                  const SizedBox(height: 8),
                  _BulletPoint(
                    text:
                    'Your phone number is never publicly visible; it is shared only for genuine requests.',
                  ),
                  _BulletPoint(
                    text:
                    'You can update health status in your donor profile when you are not fit to donate.',
                  ),
                  _BulletPoint(
                    text:
                    'Data is stored securely using Firebase (Google Cloud).',
                  ),

                  const SizedBox(height: 24),

                  // ======== FOOTER CARD ========
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_outlined,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'BloodBridge is still growing. Every new donor and supporter '
                                'helps save more lives in Mizoram and beyond.',
                            style: TextStyle(fontSize: 13.5, height: 1.4),
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
      ),
    );
  }
}

// ====== SMALL UI HELPERS ======

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, size: 6, color: Colors.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
