import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _apiUrl =
      'https://bloodbridge-notifications-12k1520ez-rindika-renthleis-projects.vercel.app/api/send-notification';

  /// Sends notification to a single donor
  static Future<bool> sendSOSNotification({
    required String recipientToken,
    required String bloodGroup,
    required String district,
    String? note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': recipientToken,
          'title': '🆘 Urgent Blood Request',
          'body': 'Need $bloodGroup blood in $district urgently!',
          'data': {
            'type': 'sos',
            'bloodGroup': bloodGroup,
            'district': district,
            'note': note ?? '',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Sends notifications to multiple donors at once
  static Future<Map<String, dynamic>> sendSOSToMultipleDonors({
    required List<String> recipientTokens,
    required String bloodGroup,
    required String district,
    String? note,
  }) async {
    int successCount = 0;
    int failureCount = 0;

    print('📤 Sending to ${recipientTokens.length} donors...');

    for (String token in recipientTokens) {
      final success = await sendSOSNotification(
        recipientToken: token,
        bloodGroup: bloodGroup,
        district: district,
        note: note,
      );

      if (success) {
        successCount++;
      } else {
        failureCount++;
      }

      // Small delay to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Sent: $successCount | ❌ Failed: $failureCount');

    return {
      'success': successCount,
      'failed': failureCount,
      'total': recipientTokens.length,
    };
  }
}