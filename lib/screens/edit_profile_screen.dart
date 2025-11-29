import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ADD THIS

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const String routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedWeight;
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedBloodGroup;
  bool? _isBloodClear;

  File? _imageFile;
  String? _currentPhotoURL;
  bool _uploadingImage = false;
  bool _saving = false;

  final List<String> _mizoramDistricts = const [
    'Aizawl', 'Lunglei', 'Champhai', 'Kolasib', 'Mamit',
    'Serchhip', 'Lawngtlai', 'Siaha', 'Hnahthial', 'Khawzawl', 'Saitual'
  ];

  final List<String> _weightCategories = const [
    'below 50 kg', '50–55 kg', '55–60 kg', '60 kg or more'
  ];

  final List<String> _ageCategories = const [
    '18–20 years', '20–30 years', '30–40 years', '40–50 years', '50–60 years', 'above 60 years'
  ];

  final Map<String, IconData> _gendersWithIcons = const {
    'Male': Icons.male,
    'Female': Icons.female,
    'Other / Prefer not to say': Icons.transgender,
  };

  final List<String> _bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAuthUser();
    _loadDonorProfile();
  }

  void _loadAuthUser() {
    final user = _user;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _currentPhotoURL = user.photoURL;
    }
  }

  Future<void> _loadDonorProfile() async {
    final user = _user;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _phoneController.text = data['phone'] ?? '';
        _selectedDistrict = data['district'];
        _selectedWeight = data['weightCategory'];
        _selectedGender = data['gender'];
        _selectedAge = data['ageCategory'];
        _selectedBloodGroup = data['bloodGroup'];
        _isBloodClear = data['isBloodClear'];
        _currentPhotoURL = data['photoURL'] ?? _currentPhotoURL;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not load profile: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick image', isError: true);
      }
    }
  }

  void _showImageSourceDialog() {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBFE),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (isMobile)
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    title: 'Take Photo',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  title: isMobile ? 'Choose from Gallery' : 'Choose Image',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_currentPhotoURL != null || _imageFile != null)
                  _buildImageOption(
                    icon: Icons.delete_outline,
                    title: 'Remove Photo',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                        _currentPhotoURL = null;
                      });
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBFE),
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    final user = _user;
    if (user == null || _imageFile == null) return null;

    setState(() => _uploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      final uploadTask = await storageRef.putFile(_imageFile!);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to upload image', isError: true);
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ADD THIS FUNCTION - Get FCM Token
  Future<String?> _getFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        print('✅ FCM Token retrieved: ${fcmToken.substring(0, 20)}...');
        return fcmToken;
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) {
      _showSnackBar('You must be logged in', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null ||
        _selectedWeight == null ||
        _selectedGender == null ||
        _selectedAge == null ||
        _selectedBloodGroup == null ||
        _isBloodClear == null) {
      _showSnackBar('Please complete all fields', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      String? photoURL = _currentPhotoURL;
      if (_imageFile != null) {
        final uploadedURL = await _uploadImage();
        if (uploadedURL != null) photoURL = uploadedURL;
      }

      // GET FCM TOKEN - ADD THIS
      final fcmToken = await _getFCMToken();

      await user.updateDisplayName(_displayNameController.text.trim());
      await user.updatePhotoURL(photoURL);
      await user.reload();

      // Prepare data with FCM token
      final donorData = {
        'userId': user.uid,
        'userEmail': user.email,
        'name': _displayNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'district': _selectedDistrict,
        'weightCategory': _selectedWeight,
        'gender': _selectedGender,
        'ageCategory': _selectedAge,
        'bloodGroup': _selectedBloodGroup,
        'isBloodClear': _isBloodClear,
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ADD FCM TOKEN IF AVAILABLE
      if (fcmToken != null) {
        donorData['fcmToken'] = fcmToken;
      }

      await FirebaseFirestore.instance
          .collection('donors')
          .doc(user.uid)
          .set(donorData, SetOptions(merge: true));

      if (!mounted) return;
      _showSnackBar(
        'Profile updated successfully!${fcmToken != null ? " You'll receive emergency notifications." : ""}',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to save: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_displayNameController.text.isNotEmpty
        ? _displayNameController.text[0]
        : 'U').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFBFE),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Avatar (No Camera Icon)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBFE),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.red.shade50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_currentPhotoURL != null
                              ? NetworkImage(_currentPhotoURL!)
                              : null) as ImageProvider?,
                          child: (_imageFile == null && _currentPhotoURL == null)
                              ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayNameController.text.isEmpty
                          ? 'User Profile'
                          : _displayNameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form Sections
              _buildSection(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _displayNameController,
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v?.length ?? 0) < 10
                        ? 'Enter valid phone number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _selectedDistrict,
                    label: 'District',
                    icon: Icons.location_on_outlined,
                    items: _mizoramDistricts,
                    onChanged: (v) => setState(() => _selectedDistrict = v),
                  ),
                ],
              ),

              _buildSection(
                title: 'Donor Details',
                icon: Icons.bloodtype_outlined,
                children: [
                  _buildLabel('Blood Group'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _bloodGroups.map((bg) {
                      final isSelected = _selectedBloodGroup == bg;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBloodGroup = bg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                            )
                                : null,
                            color: isSelected ? null : const Color(0xFFFFFBFE),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : null,
                          ),
                          child: Text(
                            bg,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Weight Category'),
                  const SizedBox(height: 8),
                  ..._weightCategories.map((w) => _buildRadioTile(
                    title: w,
                    icon: Icons.monitor_weight_outlined,
                    value: w,
                    groupValue: _selectedWeight,
                    onChanged: (v) => setState(() => _selectedWeight = v),
                  )),
                  const SizedBox(height: 16),
                  _buildLabel('Gender'),
                  const SizedBox(height: 8),
                  ..._gendersWithIcons.entries.map((entry) => _buildRadioTile(
                    title: entry.key,
                    icon: entry.value,
                    value: entry.key,
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v),
                  )),
                  const SizedBox(height: 16),
                  _buildLabel('Age Category'),
                  const SizedBox(height: 8),
                  ..._ageCategories.map((a) => _buildRadioTile(
                    title: a,
                    icon: Icons.cake_outlined,
                    value: a,
                    groupValue: _selectedAge,
                    onChanged: (v) => setState(() => _selectedAge = v),
                  )),
                ],
              ),

              _buildSection(
                title: 'Donation Eligibility',
                icon: Icons.health_and_safety_outlined,
                children: [
                  _buildLabel('Are you currently fit to donate?'),
                  const SizedBox(height: 8),
                  _buildRadioTile(
                    title: 'Yes, I am fit to donate',
                    icon: Icons.check_circle_outline,
                    value: true,
                    groupValue: _isBloodClear,
                    onChanged: (v) => setState(() => _isBloodClear = v),
                  ),
                  _buildRadioTile(
                    title: 'No, not right now',
                    icon: Icons.cancel_outlined,
                    value: false,
                    groupValue: _isBloodClear,
                    onChanged: (v) => setState(() => _isBloodClear = v),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ensure your age, weight, and health meet eligibility criteria for blood donation.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving || _uploadingImage ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.red.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.red.shade600),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBFE),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade400),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade400),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required IconData icon,
    required T value,
    required T? groupValue,
    required void Function(T?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade50 : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.red.shade300
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<T>(
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.red.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.red.shade700 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.red.shade600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}