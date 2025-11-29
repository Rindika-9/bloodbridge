import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// SCREENS
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_donor_screen.dart';
import 'screens/search_donor_screen.dart';
import 'screens/chat_screen.dart'; // Your new chat screen
import 'screens/info_screen.dart';
import 'screens/about_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';

/// 🔔 Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔕 Background message received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBp3q76gm2Sx4AwDM1TVkSFfgpc9DVG5v0",
        authDomain: "bloodbridge-64e8f.firebaseapp.com",
        projectId: "bloodbridge-64e8f",
        storageBucket: "bloodbridge-64e8f.appspot.com",
        messagingSenderId: "403336865210",
        appId: "1:403336865210:web:9c6884accd9b4116dba983",
        measurementId: "G-NZ1F95HNCW",
      ),
    );
  } else {
    await Firebase.initializeApp();

    // 🔔 Enable background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🔔 Request notification permissions (Android/iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔑 Get device token
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("📱 FCM Token: $token");

    // 🔔 Save FCM token to Firestore when user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    });

    // 🔔 Listen for messages when app is foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message: ${message.notification?.title}");
      // You can show a local notification or dialog here
    });

    // 🔔 Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📱 App opened from notification: ${message.data}");
      // Navigate to chat or relevant screen
    });
  }

  runApp(const BloodBridgeApp());
}

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // First screen shown
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        RegisterDonorScreen.routeName: (context) => const RegisterDonorScreen(),
        SearchDonorScreen.routeName: (context) => const SearchDonorScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(), // ✅ Chat screen
        InfoScreen.routeName: (context) => const InfoScreen(),
        AboutScreen.routeName: (context) => const AboutScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        EditProfileScreen.routeName: (context) => const EditProfileScreen(),
      },
    );
  }
}