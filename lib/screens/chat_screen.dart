import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? selectedChatId;
  TextEditingController messageController = TextEditingController();
  bool showLocationMenu = false;
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  /// Get other participant's name from chat
  Future<String> _getOtherParticipantName(
      Map<String, dynamic> chatData) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final participants = List<String>.from(chatData['participants']);
    final otherUserId =
    participants.firstWhere((id) => id != currentUserId);

    final participantNames =
    chatData['participantNames'] as Map<String, dynamic>?;
    if (participantNames != null &&
        participantNames.containsKey(otherUserId)) {
      return participantNames[otherUserId];
    }
    return 'Donor';
  }

  /// 💬 Send text message
  Future<void> handleSendMessage() async {
    if (messageController.text.trim().isEmpty || selectedChatId == null) {
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final messageText = messageController.text.trim();
    messageController.clear();

    try {
      // Get sender name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName = userDoc.data()?['name'] ?? 'User';

      // Get chat data to find recipient
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .get();
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final recipientId =
      participants.firstWhere((id) => id != currentUserId);

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUserId,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
      });

      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  /// 📸 Send image
  Future<void> handleImageSelect() async {
    if (selectedChatId == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => isUploading = true);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      String downloadUrl;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final uploadTask = await storageRef.putData(bytes);
        downloadUrl = await uploadTask.ref.getDownloadURL();
      } else {
        final uploadTask = await storageRef.putFile(File(image.path));
        downloadUrl = await uploadTask.ref.getDownloadURL();
      }

      // Send image message
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName = userDoc.data()?['name'] ?? 'User';

      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .get();
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final recipientId =
      participants.firstWhere((id) => id != currentUserId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .collection('messages')
          .add({
        'text': '',
        'imageUrl': downloadUrl,
        'senderId': currentUserId,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  /// 📍 Mark location
  Future<void> handleMarkLocation() async {
    setState(() => showLocationMenu = false);

    if (selectedChatId == null) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName = userDoc.data()?['name'] ?? 'User';

      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .get();
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final recipientId =
      participants.firstWhere((id) => id != currentUserId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .collection('messages')
          .add({
        'text': '📍 Location: Aizawl, Manipur',
        'senderId': currentUserId,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'location',
        'isRead': false,
        'locationData': {
          'lat': 23.7271,
          'lng': 92.7176,
          'name': 'Aizawl, Manipur',
        },
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .update({
        'lastMessage': '📍 Location',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send location: $e')),
      );
    }
  }

  /// 🔴 Share live location
  Future<void> handleLiveLocation() async {
    setState(() => showLocationMenu = false);

    if (selectedChatId == null) return;

    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location permissions are permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName = userDoc.data()?['name'] ?? 'User';

      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .get();
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final recipientId =
      participants.firstWhere((id) => id != currentUserId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .collection('messages')
          .add({
        'text':
        '🔴 Live Location: https://maps.google.com/?q=${position.latitude},${position.longitude}',
        'senderId': currentUserId,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'liveLocation',
        'isRead': false,
        'locationData': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .update({
        'lastMessage': '🔴 Live Location',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  /// 🗑️ Clear chat messages
  Future<void> handleClearChat() async {
    if (selectedChatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages'),
        content: const Text('Clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(selectedChatId)
            .collection('messages')
            .get();

        for (var doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(selectedChatId)
            .update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Messages cleared')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear messages: $e')),
        );
      }
    }
  }

  /// 🗑️ Delete entire chat
  Future<void> handleDeleteChat() async {
    if (selectedChatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Delete this entire chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete all messages
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(selectedChatId)
            .collection('messages')
            .get();

        for (var doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(selectedChatId)
            .delete();

        setState(() => selectedChatId = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedChatId != null) {
      return _buildChatView();
    }
    return _buildChatListView();
  }

  /// 💬 Individual chat view
  Widget _buildChatView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(selectedChatId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF4C0519),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chatData =
        chatSnapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: const Color(0xFF4C0519),
          appBar: AppBar(
            backgroundColor: const Color(0xFF881337),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                final chatId = selectedChatId; // keep old value
                setState(() => selectedChatId = null);

                if (chatId != null) {
                  final currentUserId =
                      FirebaseAuth.instance.currentUser!.uid;
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .update({'unreadCount.$currentUserId': 0});
                }
              },
            ),
            title: FutureBuilder<String>(
              future: _getOtherParticipantName(chatData),
              builder: (context, snapshot) {
                return Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFFDA4AF),
                      child: Icon(Icons.person, color: Color(0xFF881337)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data ?? 'Donor',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFFDA4AF)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'clear') handleClearChat();
                  if (value == 'delete') handleDeleteChat();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Clear Messages'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Chat',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: Container(
                  color: const Color(0xFFFFF1F2),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(selectedChatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message,
                                  size: 48,
                                  color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text(
                                'No messages yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final msgDoc = snapshot.data!.docs[index];
                          final msgData =
                          msgDoc.data() as Map<String, dynamic>;
                          final currentUserId =
                              FirebaseAuth.instance.currentUser!.uid;
                          final isMe =
                              msgData['senderId'] == currentUserId;
                          final messageType =
                              msgData['type'] ?? 'text';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin:
                              const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width *
                                    0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFEF4444)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Image message
                                  if (messageType == 'image' &&
                                      msgData['imageUrl'] != null)
                                    ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      child: Image.network(
                                        msgData['imageUrl'],
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context,
                                            child, progress) {
                                          if (progress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child:
                                            CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    ),

                                  // Location icon
                                  if (messageType == 'location')
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Location Shared',
                                            style: TextStyle(
                                              fontWeight:
                                              FontWeight.bold,
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Live location icon
                                  if (messageType == 'liveLocation')
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.navigation,
                                          size: 16,
                                          color: isMe
                                              ? Colors.red[200]
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Live Location',
                                            style: TextStyle(
                                              fontWeight:
                                              FontWeight.bold,
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Text content
                                  if (msgData['text'] != null &&
                                      msgData['text']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      msgData['text'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),

                                  const SizedBox(height: 4),

                                  // Timestamp
                                  Text(
                                    msgData['timestamp'] != null
                                        ? _formatTimestamp(
                                        msgData['timestamp'])
                                        : 'Sending...',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.red[100]
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Input area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Image button
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.red),
                        onPressed:
                        isUploading ? null : handleImageSelect,
                      ),

                      // Location button with menu
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.location_on,
                                color: Colors.red),
                            onPressed: () => setState(
                                    () => showLocationMenu =
                                !showLocationMenu),
                          ),
                          if (showLocationMenu)
                            Positioned(
                              bottom: 50,
                              left: 0,
                              child: Material(
                                elevation: 8,
                                borderRadius:
                                BorderRadius.circular(8),
                                child: Container(
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        dense: true,
                                        leading: const Icon(
                                            Icons.location_on,
                                            size: 18),
                                        title: const Text(
                                          'Mark Location',
                                          style:
                                          TextStyle(fontSize: 14),
                                        ),
                                        onTap: handleMarkLocation,
                                      ),
                                      ListTile(
                                        dense: true,
                                        leading: const Icon(
                                            Icons.navigation,
                                            size: 18),
                                        title: const Text(
                                          'Share Live Location',
                                          style:
                                          TextStyle(fontSize: 14),
                                        ),
                                        onTap: handleLiveLocation,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Text input
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                              const BorderSide(color: Colors.grey),
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => handleSendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send button
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.red,
                        child: isUploading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        onPressed: handleSendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📋 Chat list view
  Widget _buildChatListView() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF4C0519),
        body: Center(
          child: Text(
            'Please log in to view chats',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    print('📱 Chat Screen: Listening for chats for user: $currentUserId');

    return Scaffold(
      backgroundColor: const Color(0xFF4C0519),
      appBar: AppBar(
        backgroundColor: const Color(0xFF881337),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFDA4AF),
              child:
              Icon(Icons.message, color: Color(0xFF881337)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'BloodBridge Chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Community support for blood donation',
                    style:
                    TextStyle(fontSize: 12, color: Color(0xFFFDA4AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
              print('🔄 Manual refresh triggered');
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFFFF1F2),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            print('📊 StreamBuilder state: ${snapshot.connectionState}');

            if (snapshot.hasError) {
              print('❌ StreamBuilder error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading chats',
                      style:
                      TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              print('⏳ Waiting for initial chat data...');
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              print('⚠️  No data received from Firestore');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No data from Firestore',
                        style:
                        TextStyle(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              );
            }

            final chatDocs = snapshot.data!.docs;
            print('✅ Received ${chatDocs.length} chat(s) from Firestore');

            if (chatDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No chats yet',
                        style:
                        TextStyle(color: Colors.grey, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      'SOS requests will appear here',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {});
                        print('🔄 Refresh button pressed');
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Sort by lastMessageTime manually (since orderBy might fail without index)
            final sortedDocs = chatDocs.toList()
              ..sort((a, b) {
                final aTime = (a.data()
                as Map<String, dynamic>)['lastMessageTime']
                as Timestamp?;
                final bTime = (b.data()
                as Map<String, dynamic>)['lastMessageTime']
                as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

            return ListView.builder(
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final chatDoc = sortedDocs[index];
                final chatData =
                chatDoc.data() as Map<String, dynamic>;
                final chatId = chatDoc.id;

                print('   Chat $index: $chatId');

                final participants =
                List<String>.from(chatData['participants'] ?? []);
                final otherUserId = participants.firstWhere(
                      (id) => id != currentUserId,
                  orElse: () => 'unknown',
                );

                final participantNames =
                chatData['participantNames']
                as Map<String, dynamic>?;
                final otherUserName =
                    participantNames?[otherUserId] ?? 'Donor';

                final unreadCount =
                    (chatData['unreadCount']
                    as Map<String, dynamic>?)?[currentUserId] ??
                        0;

                return ListTile(
                  onTap: () {
                    setState(() => selectedChatId = chatId);
                    // Mark as read
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .update(
                        {'unreadCount.$currentUserId': 0});
                  },
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444),
                    child: Text(
                      otherUserName
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    otherUserName,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chatData['lastMessage'] ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (chatData['lastMessageTime'] != null)
                        Text(
                          _formatTimestamp(
                              chatData['lastMessageTime']),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Format Firestore timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        final hour =
        dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
        final period = dateTime.hour >= 12 ? 'PM' : 'AM';
        return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
