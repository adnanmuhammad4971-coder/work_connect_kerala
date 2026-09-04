import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class SmsNotificationService {
  static final SmsNotificationService _instance = SmsNotificationService._internal();
  factory SmsNotificationService() => _instance;
  SmsNotificationService._internal();

  /// Formats the booking details into a clean, readable SMS body
  String formatBookingSmsText(Booking booking) {
    final shortId = booking.id.length > 6 ? booking.id.substring(booking.id.length - 6) : booking.id;
    final dateStr = '${booking.date.day}/${booking.date.month}/${booking.date.year}';
    
    return '🔔 WorkConnect Booking #$shortId\n'
        '• Category: ${booking.requiredWorkerCategory}\n'
        '• Customer: ${booking.customerName} (${booking.customerPhone})\n'
        '• Location: ${booking.location}\n'
        '• Date/Time: $dateStr at ${booking.time}\n'
        '• Workers: ${booking.numberOfWorkers}\n'
        '• Maps: ${booking.mapsUrl}';
  }

  /// Cleans a phone number for SMS sending (removes non-digits, keeps 10-digit Indian numbers or full international format)
  String cleanPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return digits; // standard Indian 10 digits
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2); // remove leading 91 for Indian gateways if needed
    }
    return digits;
  }

  /// Sends an automated SMS notification to the admin based on ContactInfo settings
  Future<SmsResult> sendBookingSmsNotification(Booking booking, ContactInfo contactInfo) async {
    if (!contactInfo.enableSmsAlerts) {
      debugPrint('[SmsNotification] SMS alerts are disabled in settings.');
      return SmsResult(success: false, message: 'SMS alerts are disabled in settings');
    }

    final targetPhone = contactInfo.adminSmsNumber.isNotEmpty
        ? contactInfo.adminSmsNumber
        : contactInfo.phone;

    if (targetPhone.isEmpty) {
      debugPrint('[SmsNotification] Admin phone number is not configured.');
      return SmsResult(success: false, message: 'Admin phone number is not configured');
    }

    final smsText = formatBookingSmsText(booking);
    return await _dispatchSms(
      targetPhone: targetPhone,
      message: smsText,
      contactInfo: contactInfo,
    );
  }

  /// Sends a test SMS to verify the gateway configuration
  Future<SmsResult> sendTestSms(String targetPhone, ContactInfo contactInfo) async {
    final testMsg = '🔔 WorkConnect Kerala: This is a test SMS alert. Admin notifications are active for $targetPhone!';
    return await _dispatchSms(
      targetPhone: targetPhone,
      message: testMsg,
      contactInfo: contactInfo,
    );
  }

  /// Dispatches the SMS via the configured gateway or HTTP API
  Future<SmsResult> _dispatchSms({
    required String targetPhone,
    required String message,
    required ContactInfo contactInfo,
  }) async {
    final provider = contactInfo.smsGatewayProvider.toLowerCase().trim();
    final apiKey = contactInfo.smsApiKey.trim();
    final cleanPhone = cleanPhoneNumber(targetPhone);

    debugPrint('[SmsNotification] Dispatching SMS to $cleanPhone using provider: $provider');

    try {
      if (provider == 'fast2sms') {
        return await _sendFast2Sms(cleanPhone, message, apiKey);
      } else if (provider == 'twofactor') {
        return await _send2FactorSms(cleanPhone, message, apiKey, contactInfo.smsSenderId);
      } else if (provider == 'custom_api') {
        return await _sendCustomHttpSms(cleanPhone, message, contactInfo.smsCustomUrl, apiKey);
      } else if (provider == 'direct_intent') {
        final opened = await launchDirectSms(targetPhone, message);
        return SmsResult(
          success: opened,
          message: opened ? 'Device SMS app launched' : 'Could not launch SMS app',
        );
      } else {
        // Fallback default: Try Fast2SMS if API key is present, otherwise direct intent
        if (apiKey.isNotEmpty) {
          return await _sendFast2Sms(cleanPhone, message, apiKey);
        }
        return SmsResult(
          success: true,
          message: 'SMS queued. Please configure SMS Gateway API key in Admin Settings.',
        );
      }
    } catch (e, stack) {
      debugPrint('[SmsNotification] Error sending SMS: $e\n$stack');
      return SmsResult(success: false, message: 'SMS dispatch failed: $e');
    }
  }

  String _extractFast2SmsMessage(dynamic rawMsg) {
    if (rawMsg is List) {
      return rawMsg.map((e) => e.toString()).join(', ');
    } else if (rawMsg is String) {
      return rawMsg;
    } else if (rawMsg != null) {
      return rawMsg.toString();
    }
    return 'SMS processed';
  }

  /// Fast2SMS Gateway (Quick SMS / Bulk SMS API)
  Future<SmsResult> _sendFast2Sms(String phone, String message, String apiKey) async {
    if (apiKey.isEmpty) {
      return SmsResult(
        success: false,
        message: 'Fast2SMS API Key is missing. Please add it in Admin Settings.',
      );
    }

    final directUrl = Uri.parse('https://www.fast2sms.com/dev/bulkV2');
    final queryUrl = Uri.parse(
      'https://www.fast2sms.com/dev/bulkV2?authorization=${Uri.encodeComponent(apiKey)}&route=q&message=${Uri.encodeComponent(message)}&language=english&flash=0&numbers=$phone',
    );

    // 1. If not web, try direct POST first
    if (!kIsWeb) {
      try {
        final response = await http.post(
          directUrl,
          headers: {
            'authorization': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'route': 'q',
            'message': message,
            'language': 'english',
            'flash': 0,
            'numbers': phone,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final returnStatus = data['return'] == true;
          final msg = _extractFast2SmsMessage(data['message']);
          return SmsResult(success: returnStatus, message: msg);
        } else {
          return SmsResult(
            success: false,
            message: 'Fast2SMS error (${response.statusCode}): ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('[SmsNotification] Direct POST failed: $e. Trying fallback...');
      }
    }

    // 2. Web or fallback: Try GET via CORS proxy if needed
    try {
      final webProxyUrl = Uri.parse(
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(queryUrl.toString())}',
      );

      final response = await http.get(kIsWeb ? webProxyUrl : queryUrl).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final returnStatus = data['return'] == true;
        final msg = _extractFast2SmsMessage(data['message']);
        return SmsResult(success: returnStatus, message: msg);
      } else {
        // Try direct GET as second fallback
        final directGetResp = await http.get(queryUrl).timeout(const Duration(seconds: 15));
        if (directGetResp.statusCode == 200) {
          final data = jsonDecode(directGetResp.body);
          final returnStatus = data['return'] == true;
          final msg = _extractFast2SmsMessage(data['message']);
          return SmsResult(success: returnStatus, message: msg);
        }
        return SmsResult(
          success: false,
          message: 'Fast2SMS response (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[SmsNotification] Fast2SMS Web error: $e');
      return SmsResult(
        success: false,
        message: 'Fast2SMS dispatch error: $e',
      );
    }
  }

  /// 2Factor SMS Gateway
  Future<SmsResult> _send2FactorSms(String phone, String message, String apiKey, String senderId) async {
    if (apiKey.isEmpty) {
      return SmsResult(
        success: false,
        message: '2Factor API Key is missing. Please add it in Admin Settings.',
      );
    }

    final sid = senderId.isNotEmpty ? senderId : 'WKCONN';
    final url = Uri.parse('https://2factor.in/v1/API/V1/$apiKey/ADDON_SERVICES/SEND/PSMS');
    final response = await http.post(
      url,
      body: {
        'From': sid,
        'To': phone,
        'Msg': message,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return SmsResult(success: true, message: '2Factor SMS sent successfully: ${response.body}');
    } else {
      return SmsResult(success: false, message: '2Factor error (${response.statusCode}): ${response.body}');
    }
  }

  /// Custom Webhook / HTTP SMS API
  Future<SmsResult> _sendCustomHttpSms(String phone, String message, String customUrl, String apiKey) async {
    if (customUrl.isEmpty) {
      return SmsResult(success: false, message: 'Custom SMS URL endpoint is not configured.');
    }

    final url = Uri.parse(customUrl);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'phone': phone,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 15));

    return SmsResult(
      success: response.statusCode >= 200 && response.statusCode < 300,
      message: 'Custom API status: ${response.statusCode}',
    );
  }

  /// Direct Device SMS launcher (Intent fallback)
  Future<bool> launchDirectSms(String phoneNumber, String message) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(
      scheme: 'sms',
      path: clean,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}

class SmsResult {
  final bool success;
  final String message;

  SmsResult({required this.success, required this.message});
}
