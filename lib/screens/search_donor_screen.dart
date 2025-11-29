import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

// 🔴 Theme & Color Palette
const Color kPrimaryRed = Color(0xFFD32F2F);
const Color kLightBg = Color(0xFFFAFAFA);
const Color kDarkText = Color(0xFF212121);

class SearchDonorScreen extends StatefulWidget {
  const SearchDonorScreen({super.key});

  static const String routeName = '/search-donor';

  @override
  State<SearchDonorScreen> createState() => _SearchDonorScreenState();
}

class _SearchDonorScreenState extends State<SearchDonorScreen> {
  String? _selectedDistrict;
  String? _selectedBloodGroup;
  bool _isSending = false;

  final List<String> _mizoramDistricts = const [
    'Aizawl', 'Lunglei', 'Champhai', 'Kolasib', 'Mamit', 'Serchhip',
    'Lawngtlai', 'Siaha', 'Hnahthial', 'Khawzawl', 'Saitual',
  ];

  final List<String> _bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  // ------------------- MAIN SOS FUNCTION -------------------
  Future<void> _sendBroadcastSos() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    if (_selectedDistrict == null || _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select district and blood group.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      final sosDoc = await FirebaseFirestore.instance
          .collection('sos_requests')
          .add({
        'requesterId': user.uid,
        'requesterEmail': user.email,
        'requesterName': userName,
        'district': _selectedDistrict,
        'bloodGroup': _selectedBloodGroup,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final donorsSnapshot = await FirebaseFirestore.instance
          .collection('donors')
          .where('bloodGroup', isEqualTo: _selectedBloodGroup)
          .where('district', isEqualTo: _selectedDistrict)
          .get();

      if (donorsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No donors found in this area.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isSending = false);
        return;
      }

      List<String> tokens = [];
      int chatsCreated = 0;

      for (var donorDoc in donorsSnapshot.docs) {
        final donorData = donorDoc.data();
        final donorId = donorData['userId'];

        if (donorId == user.uid) continue;

        final donorName = donorData['name'] ?? "Donor";
        final fcmToken = donorData['fcmToken'];

        final chatId = _createChatId(user.uid, donorId);

        final existingChat = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();

        if (!existingChat.exists) {
          await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
            'participants': [user.uid, donorId],
            'participantNames': {user.uid: userName, donorId: donorName},
            'lastMessage': '🆘 SOS: Need $_selectedBloodGroup blood',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCount': {user.uid: 0, donorId: 1},
            'createdAt': FieldValue.serverTimestamp(),
            'requesterId': user.uid,
            'donorId': donorId,
            'sosId': sosDoc.id,
          });

          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .add({
            'text':
            '🆘 EMERGENCY! Need $_selectedBloodGroup blood in $_selectedDistrict. Can you help?',
            'senderId': user.uid,
            'senderName': userName,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'sos',
            'isRead': false,
          });

          chatsCreated++;
        }

        if (fcmToken != null && fcmToken.isNotEmpty) {
          tokens.add(fcmToken);
        }
      }

      if (tokens.isNotEmpty) {
        await NotificationService.sendSOSToMultipleDonors(
          recipientTokens: tokens,
          bloodGroup: _selectedBloodGroup!,
          district: _selectedDistrict!,
          note: '',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚑 SOS sent to $chatsCreated donors. Check chat."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("❌ SOS ERROR: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _createChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return "chat_${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _selectedDistrict != null && _selectedBloodGroup != null;

    return Scaffold(
      backgroundColor: const Color(0xFF4A0000), // Deep dark red full background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A0000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Search Donor & Send SOS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 10),
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kPrimaryRed.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.crisis_alert_rounded,
                              color: kPrimaryRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "URGENT SOS REQUEST",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text("Select District:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_rounded,
                              color: kPrimaryRed),
                        ),
                        items: _mizoramDistricts
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedDistrict = v),
                      ),

                      const SizedBox(height: 22),

                      const Text("Choose Blood Group:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _bloodGroups.map((bg) {
                          final selected = _selectedBloodGroup == bg;
                          return ChoiceChip(
                            label: Text(
                              bg,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.black,
                              ),
                            ),
                            selected: selected,
                            selectedColor: kPrimaryRed,
                            onSelected: (_) => setState(() {
                              _selectedBloodGroup = bg;
                            }),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (!_isSending && canSend)
                              ? _sendBroadcastSos
                              : null,
                          icon: _isSending
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.campaign_outlined),
                          label: Text(
                            _isSending
                                ? "CREATING CHATS..."
                                : "SEND SOS & CREATE CHATS",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
