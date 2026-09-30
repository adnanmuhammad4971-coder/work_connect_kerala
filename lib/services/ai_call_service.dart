import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiCallRecord {
  final String id;
  final String phone;
  final String customerName;
  final String service;
  final String location;
  final String workersRequired;
  final String preferredDate;
  final String preferredTime;
  final String status; // 'calling', 'completed', 'failed', 'no_answer'
  final String interested; // 'yes', 'no', 'callback'
  final String callDuration;
  final String recordingUrl;
  final String customerResponse; // Transcribed from Gather
  final String language;
  final DateTime createdAt;

  AiCallRecord({
    required this.id,
    required this.phone,
    this.customerName = '',
    this.service = '',
    this.location = '',
    this.workersRequired = '',
    this.preferredDate = '',
    this.preferredTime = '',
    this.status = 'pending',
    this.interested = 'unknown',
    this.callDuration = '0',
    this.recordingUrl = '',
    this.customerResponse = '',
    this.language = 'Malayalam',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'customerName': customerName,
        'service': service,
        'location': location,
        'workersRequired': workersRequired,
        'preferredDate': preferredDate,
        'preferredTime': preferredTime,
        'status': status,
        'interested': interested,
        'callDuration': callDuration,
        'recordingUrl': recordingUrl,
        'customerResponse': customerResponse,
        'language': language,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AiCallRecord.fromMap(Map<String, dynamic> map, String id) {
    return AiCallRecord(
      id: id,
      phone: map['phone'] ?? '',
      customerName: map['customerName'] ?? '',
      service: map['service'] ?? '',
      location: map['location'] ?? '',
      workersRequired: map['workersRequired'] ?? '',
      preferredDate: map['preferredDate'] ?? '',
      preferredTime: map['preferredTime'] ?? '',
      status: map['status'] ?? 'pending',
      interested: map['interested'] ?? 'unknown',
      callDuration: map['callDuration'] ?? '0',
      recordingUrl: map['recordingUrl'] ?? '',
      customerResponse: map['customerResponse'] ?? map['transcript'] ?? '',
      language: map['language'] ?? 'Malayalam',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AiCallRecord copyWith({
    String? customerName,
    String? service,
    String? location,
    String? workersRequired,
    String? preferredDate,
    String? preferredTime,
    String? status,
    String? interested,
    String? callDuration,
    String? recordingUrl,
    String? customerResponse,
  }) {
    return AiCallRecord(
      id: id,
      phone: phone,
      customerName: customerName ?? this.customerName,
      service: service ?? this.service,
      location: location ?? this.location,
      workersRequired: workersRequired ?? this.workersRequired,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      status: status ?? this.status,
      interested: interested ?? this.interested,
      callDuration: callDuration ?? this.callDuration,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      customerResponse: customerResponse ?? this.customerResponse,
      language: language,
      createdAt: createdAt,
    );
  }
}

class AiCallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Render.com Backend URL ────────────────────────────────────────
  static const String _backendUrl = 'https://workconnect-ai-call.onrender.com';

  // ─── Firestore Methods ─────────────────────────────────────────────

  Future<String> createCallRecord(AiCallRecord record) async {
    final docRef = await _db.collection('ai_calls').add(record.toMap());
    return docRef.id;
  }

  Future<void> updateCallRecord(String callId, Map<String, dynamic> data) async {
    await _db.collection('ai_calls').doc(callId).update(data);
  }

  Stream<List<AiCallRecord>> getCallRecords() {
    return _db
        .collection('ai_calls')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AiCallRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteCallRecord(String callId) async {
    await _db.collection('ai_calls').doc(callId).delete();
  }

  // ─── WhatsApp AI Voice via Render.com Backend ──────────────────────
  
  Future<String> sendWhatsAppVoice({
    required String toNumber,
    required String callId,
    required String language,
    required String script,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/send-whatsapp-voice'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toNumber': toNumber,
        'callId': callId,
        'language': language,
        'script': script,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] != null) {
        throw Exception(jsonResponse['error']);
      }
      return jsonResponse['audioUrl'] ?? '';
    } else {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? 'Failed to send WhatsApp message');
    }
  }

  // ─── Call via Render.com Backend (avoids CORS) ────────────────────

  /// Initiates an outbound call via Render.com Express backend → Twilio.
  /// Returns the Twilio Call SID on success.
  Future<String> initiateCall({
    required String toNumber,
    required String callId,
    required String language,
    required String service,
    required String script,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/make-call'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toNumber': toNumber,
        'callId': callId,
        'language': language,
        'service': service,
        'script': script,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['sid'] as String? ?? '';
      }
      throw Exception(data['error'] ?? 'Call failed');
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Server error: ${response.statusCode}');
    }
  }

  // ─── AI Script Generator ───────────────────────────────────────────

  static String getMalayalamScript(String service) {
    final serviceText = service.isNotEmpty ? service : 'cleaning, construction, coconut climbing, event workers, general labour';
    return '''
നമസ്കാരം. Work Connect Kerala-ൽ നിന്നാണ് വിളിക്കുന്നത്.

കേരളത്തിലെ വിവിധ ജില്ലകളിൽ $serviceText
തുടങ്ങിയ services-ലേക്ക് workers ലഭ്യമാക്കുന്ന
ഒരു workforce service ആണ് Work Connect Kerala.

താങ്കൾക്ക് ഇപ്പോൾ ഏതെങ്കിലും worker service ആവശ്യമുണ്ടോ?
''';
  }

  static String getEnglishScript(String service) {
    final serviceText = service.isNotEmpty ? service : 'cleaning, construction, coconut climbing, event workers, general labour';
    return '''
Hello! This is Work Connect Kerala calling.

We provide skilled workers for $serviceText
and many more services across all districts of Kerala.

Do you currently need any worker service?
''';
  }

  // ─── Statistics ────────────────────────────────────────────────────

  Future<Map<String, int>> getCallStats() async {
    final snap = await _db.collection('ai_calls').get();
    int total = snap.docs.length;
    int interested = 0;
    int notInterested = 0;
    int callback = 0;
    int pending = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      switch (data['interested']) {
        case 'yes':
          interested++;
          break;
        case 'no':
          notInterested++;
          break;
        case 'callback':
          callback++;
          break;
        default:
          pending++;
      }
    }

    return {
      'total': total,
      'interested': interested,
      'notInterested': notInterested,
      'callback': callback,
      'pending': pending,
    };
  }
}
