import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterDonorScreen extends StatefulWidget {
  const RegisterDonorScreen({super.key});

  static const String routeName = '/register-donor';

  @override
  State<RegisterDonorScreen> createState() => _RegisterDonorScreenState();
}

class _RegisterDonorScreenState extends State<RegisterDonorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedWeight;
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedBloodGroup;
  bool? _isBloodClear;

  bool _isLoading = true;
  bool _alreadyRegistered = false;

  final List<String> _mizoramDistricts = const [
    'Aizawl','Lunglei','Champhai','Kolasib','Mamit','Serchhip',
    'Lawngtlai','Siaha','Hnahthial','Khawzawl','Saitual'
  ];

  final List<String> _weightCategories = const [
    '40–45 kg','45–50 kg','50–55 kg','55–60 kg','60 kg or more'
  ];

  final List<String> _ageCategories = const [
    '18–20 years','20–30 years','30–40 years','40–50 years','50–60 years'
  ];

  final List<String> _genders = const [
    'Male','Female','Other / Prefer not to say'
  ];

  final List<String> _bloodGroups = const [
    'A+','A-','B+','B-','O+','O-','AB+','AB-'
  ];

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered();
  }

  Future<void> _checkIfAlreadyRegistered() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(user.uid)
          .get();

      if (donorDoc.exists) {
        setState(() {
          _alreadyRegistered = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _alreadyRegistered = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking registration: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before registering.'),
        ),
      );
      return;
    }

    // EXTRA SAFETY: block if already registered
    if (_alreadyRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already registered as a donor.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null ||
        _selectedWeight == null ||
        _selectedGender == null ||
        _selectedAge == null ||
        _selectedBloodGroup == null ||
        _isBloodClear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields before registering.'),
        ),
      );
      return;
    }

    if (_isBloodClear == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are currently not eligible to donate. '
                'Please register only when your health and blood are clear.',
          ),
        ),
      );
      return;
    }

    try {
      final uid = user.uid;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await FirebaseFirestore.instance.collection('donors').doc(uid).set({
        'userId': uid,
        'email': user.email,
        'name': name,
        'phone': phone,
        'district': _selectedDistrict,
        'weightCategory': _selectedWeight,
        'gender': _selectedGender,
        'ageRange': _selectedAge,
        'bloodGroup': _selectedBloodGroup,
        'isBloodClear': _isBloodClear,
        'registeredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'district': _selectedDistrict,
        'bloodGroup': _selectedBloodGroup,
        'isBloodClear': _isBloodClear,
        'donorProfileCompleted': true,
        'donorUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Donor profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save donor: $e')),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.red.shade700),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }

  Widget _buildChipGroup({
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final bool isSelected = selectedValue == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              selectedColor: Colors.red.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
              onSelected: (_) => setState(() => onChanged(opt)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHealthChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: Colors.red.shade500, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Health Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Fit to Donate'),
              selected: _isBloodClear == true,
              selectedColor: Colors.green.shade600,
              labelStyle: TextStyle(
                color: _isBloodClear == true ? Colors.white : Colors.black87,
              ),
              onSelected: (_) => setState(() => _isBloodClear = true),
            ),
            ChoiceChip(
              label: const Text('Not right now'),
              selected: _isBloodClear == false,
              selectedColor: Colors.red.shade600,
              labelStyle: TextStyle(
                color: _isBloodClear == false ? Colors.white : Colors.black87,
              ),
              onSelected: (_) => setState(() => _isBloodClear = false),
            ),
          ],
        ),
      ],
    );
  }

  /// 🔥 STYLED "ALREADY REGISTERED" SCREEN
  Widget _buildAlreadyRegisteredScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient background (slightly different from main form)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF312E81), // indigo
                  Color(0xFF7C3AED), // violet
                  Color(0xFFEC4899), // pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Soft blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.20)),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'You’re already a registered donor 💉',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            const Text(
                              'Thank you for stepping up as a blood donor. '
                                  'Your details are already in the BloodBridge system, '
                                  'so we can reach you quickly during emergencies.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Divider(height: 1),

                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.info_outline,
                                    size: 18, color: Color(0xFF7C3AED)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You only need to register once. '
                                        'If your phone number, blood group or district changes, '
                                        'you can update it from the “Edit donor profile” option '
                                        'in Settings.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.favorite_border,
                                    size: 18, color: Color(0xFFEC4899)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Staying registered increases the chance that someone '
                                        'will find a matching donor when they need it most.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      'Back',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4C1D95),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                    ),
                                    child: const Text(
                                      'Okay, got it',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'Tip: You can review or update your donor details any time '
                            'from the Settings screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // ⛔ If already registered → show the special screen, NOT the form
    if (_alreadyRegistered) {
      return _buildAlreadyRegisteredScreen();
    }

    // Registration UI with back button + dark red gradient
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF240003), Color(0xFF4A0000), Color(0xFF1A0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),

          // BACK BUTTON TOP LEFT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Registration card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Register as Donor',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameController,
                          decoration:
                          _buildInputDecoration('Full name', Icons.person),
                          validator: (value) => value == null ||
                              value.trim().isEmpty
                              ? 'Please enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: _buildInputDecoration(
                              'District (Mizoram)', Icons.location_on),
                          items: _mizoramDistricts
                              .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDistrict = value),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                              'Phone number', Icons.phone),
                        ),
                        const SizedBox(height: 20),

                        _buildChipGroup(
                          title: 'Weight',
                          icon: Icons.monitor_weight,
                          options: _weightCategories,
                          selectedValue: _selectedWeight,
                          onChanged: (v) => _selectedWeight = v,
                        ),
                        const SizedBox(height: 18),

                        _buildChipGroup(
                          title: 'Gender',
                          icon: Icons.wc,
                          options: _genders,
                          selectedValue: _selectedGender,
                          onChanged: (v) => _selectedGender = v,
                        ),
                        const SizedBox(height: 18),

                        _buildChipGroup(
                          title: 'Age',
                          icon: Icons.cake,
                          options: _ageCategories,
                          selectedValue: _selectedAge,
                          onChanged: (v) => _selectedAge = v,
                        ),
                        const SizedBox(height: 18),

                        _buildChipGroup(
                          title: 'Blood Group',
                          icon: Icons.bloodtype,
                          options: _bloodGroups,
                          selectedValue: _selectedBloodGroup,
                          onChanged: (v) => _selectedBloodGroup = v,
                        ),
                        const SizedBox(height: 18),

                        _buildHealthChips(),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              backgroundColor: Colors.red.shade700,
                            ),
                            child: const Text(
                              'Submit Registration',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
