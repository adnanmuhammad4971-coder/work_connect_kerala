import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_call_service.dart';

class AiCallCenterPage extends StatefulWidget {
  const AiCallCenterPage({super.key});

  @override
  State<AiCallCenterPage> createState() => _AiCallCenterPageState();
}

class _AiCallCenterPageState extends State<AiCallCenterPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _scriptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _callService = AiCallService();

  String _selectedService = 'All Services';
  String _selectedLanguage = 'Malayalam';
  bool _isLoading = false;
  bool _isCalling = false;
  String? _activeCallId;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _services = [
    'All Services',
    'Cleaning & Housemaid',
    'Construction Worker',
    'Coconut Climbing',
    'Event Workers',
    'General Labour',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Home Nurse',
    'Driver',
    'Cook & Catering',
    'Gardener',
  ];

  @override
  void initState() {
    super.initState();
    _scriptController.text = '''Namaskaram. Work Connect Kerala il ninnum vilikkunnath.
Kerala vil cleaning, construction thudangiya services
labhyamakkunna oru workforce service aanu njangalude.
Thangalku ethenkilum worker service aavashyamundo?''';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phoneController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _startAiCall() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final service = _selectedService == 'All Services' ? '' : _selectedService;

      // Create Firestore record first
      final record = AiCallRecord(
        id: '',
        phone: phone,
        service: service,
        language: _selectedLanguage,
        status: 'calling',
        createdAt: DateTime.now(),
      );

      final callId = await _callService.createCallRecord(record);
      setState(() => _activeCallId = callId);

      // Initiate Twilio call
      await _callService.initiateCall(
        toNumber: phone,
        callId: callId,
        language: _selectedLanguage,
        service: service,
        script: _scriptController.text,
      );

      setState(() {
        _isCalling = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.phone_in_talk, color: Colors.white),
                const SizedBox(width: 10),
                Text('AI Call initiated to $phone'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _isWhatsAppLoading = false;

  Future<void> _sendWhatsAppAiVoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isWhatsAppLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final service = _selectedService == 'All Services' ? '' : _selectedService;
      final script = _scriptController.text.trim();

      if (script.isEmpty) {
        throw Exception('Please enter the AI Script to convert to WhatsApp voice.');
      }

      // Create Firestore record first (WhatsApp Voice)
      final record = AiCallRecord(
        id: '',
        phone: phone,
        service: service,
        language: _selectedLanguage,
        status: 'whatsapp_voice_sent',
        createdAt: DateTime.now(),
      );

      final callId = await _callService.createCallRecord(record);

      await _callService.sendWhatsAppVoice(
        toNumber: phone,
        callId: callId,
        language: _selectedLanguage,
        script: script,
      );

      setState(() {
        _isWhatsAppLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.chat, color: Colors.white),
                const SizedBox(width: 10),
                Text('WhatsApp Voice Message sent to $phone'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isWhatsAppLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _stopCall() async {
    if (_activeCallId != null) {
      await _callService.updateCallRecord(_activeCallId!, {
        'status': 'completed',
        'interested': 'unknown',
      });
    }
    setState(() {
      _isCalling = false;
      _activeCallId = null;
      _phoneController.clear();
    });
  }

  void _showUpdateCallDialog(AiCallRecord record) {
    String selectedInterested = record.interested;
    final nameCtrl = TextEditingController(text: record.customerName);
    final serviceCtrl = TextEditingController(text: record.service);
    final locationCtrl = TextEditingController(text: record.location);
    final workersCtrl = TextEditingController(text: record.workersRequired);
    final dateCtrl = TextEditingController(text: record.preferredDate);
    final timeCtrl = TextEditingController(text: record.preferredTime);
    final customerResponseCtrl = TextEditingController(text: record.customerResponse);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Text(
                'Update Call: ${record.phone}',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status selection
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Customer Interest',
                        style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _interestChip('yes', '🟢 Interested', selectedInterested,
                          (v) => setDialogState(() => selectedInterested = v)),
                      const SizedBox(width: 8),
                      _interestChip('no', '⚪ Not Interested', selectedInterested,
                          (v) => setDialogState(() => selectedInterested = v)),
                      const SizedBox(width: 8),
                      _interestChip('callback', '🔵 Callback', selectedInterested,
                          (v) => setDialogState(() => selectedInterested = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _dialogField(nameCtrl, 'Customer Name', Icons.person_outline),
                  const SizedBox(height: 10),
                  _dialogField(serviceCtrl, 'Service Required', Icons.work_outline),
                  const SizedBox(height: 10),
                  _dialogField(locationCtrl, 'Location', Icons.location_on_outlined),
                  const SizedBox(height: 10),
                  _dialogField(workersCtrl, 'Workers Required', Icons.people_outline),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _dialogField(dateCtrl, 'Date', Icons.calendar_today)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _dialogField(timeCtrl, 'Time', Icons.access_time)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dialogField(customerResponseCtrl, 'Customer Response / Notes',
                      Icons.notes_outlined,
                      maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _callService.updateCallRecord(record.id, {
                  'customerName': nameCtrl.text.trim(),
                  'service': serviceCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'workersRequired': workersCtrl.text.trim(),
                  'preferredDate': dateCtrl.text.trim(),
                  'preferredTime': timeCtrl.text.trim(),
                  'customerResponse': customerResponseCtrl.text.trim(),
                  'interested': selectedInterested,
                  'status': 'completed',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Call record updated!'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _interestChip(String value, String label, String selected,
      Function(String) onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF818CF8)
                : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────
          _buildHeader(),
          // ─── Body ────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel — call form
                SizedBox(
                  width: 340,
                  child: _buildCallPanel(),
                ),
                // Right panel — call history
                Expanded(child: _buildCallHistory()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Call Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Work Connect Kerala — Automated Outbound Calling',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // Stats row
          StreamBuilder<List<AiCallRecord>>(
            stream: _callService.getCallRecords(),
            builder: (ctx, snap) {
              final calls = snap.data ?? [];
              final total = calls.length;
              final interested =
                  calls.where((c) => c.interested == 'yes').length;
              return Row(
                children: [
                  _headerStat('Total Calls', '$total', const Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  _headerStat(
                      'Interested', '$interested', const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _headerStat(
                    'Conversion',
                    total > 0
                        ? '${((interested / total) * 100).toStringAsFixed(0)}%'
                        : '0%',
                    const Color(0xFFFBBF24),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
              style:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCallPanel() {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Color(0xFF334155))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calling animation
              if (_isCalling) _buildCallingIndicator(),
              if (!_isCalling) ...[
                const Text(
                  '☎ Start AI Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter customer details to initiate',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Phone Number
                _buildLabel('Customer Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: '98XXXXXXXX',
                    hintStyle: const TextStyle(
                        color: Color(0xFF475569), letterSpacing: 1),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone number required';
                    if (v.length != 10) return 'Enter valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Service dropdown
                _buildLabel('Service'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedService,
                  items: _services,
                  icon: Icons.work_outline,
                  onChanged: (v) => setState(() => _selectedService = v!),
                ),
                const SizedBox(height: 16),
                // Language
                _buildLabel('Language'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _langChip('Malayalam', '🇮🇳'),
                    const SizedBox(width: 10),
                    _langChip('English', '🇬🇧'),
                  ],
                ),
                const SizedBox(height: 20),
                // Script editor
                _buildLabel('AI Script (Edit what the AI will say)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scriptController,
                  maxLines: 5,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                // Error
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Start Call Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.phone_rounded, size: 20),
                    label: Text(
                      _isLoading ? 'Initiating Call...' : '☎  START AI CALL',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor:
                          const Color(0xFF6366F1).withOpacity(0.5),
                    ),
                    onPressed: _isLoading ? null : _startAiCall,
                  ),
                ),
                const SizedBox(height: 12),
                // Send WhatsApp Voice Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isWhatsAppLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.chat_bubble_rounded, size: 20),
                    label: Text(
                      _isWhatsAppLoading ? 'Sending...' : '🟢 SEND FREE WHATSAPP AI VOICE',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                    ),
                    onPressed: (_isLoading || _isWhatsAppLoading) ? null : _sendWhatsAppAiVoice,
                  ),
                ),
                const SizedBox(height: 12),
                // Twilio setup notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFBBF24).withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Twilio credentials required. Configure in ai_call_service.dart',
                          style: TextStyle(
                              color: Color(0xFFFBBF24), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallingIndicator() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.phone_in_talk_rounded,
                  color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '+91 ${_phoneController.text}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI is calling...',
            style: TextStyle(color: Color(0xFF10B981), fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Work Connect Kerala service explanation',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.call_end_rounded),
            label: const Text('Mark as Done',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _stopCall,
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistory() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Recent Calls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StreamBuilder<List<AiCallRecord>>(
                    stream: _callService.getCallRecords(),
                    builder: (ctx, snap) {
                      return Text(
                        '${snap.data?.length ?? 0} calls',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AiCallRecord>>(
              stream: _callService.getCallRecords(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6366F1)),
                  );
                }
                final calls = snap.data ?? [];
                if (calls.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_missed_outlined,
                            color: Colors.white.withOpacity(0.1), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No calls yet',
                          style: TextStyle(
                              color: Color(0xFF475569), fontSize: 16),
                        ),
                        const Text(
                          'Start an AI call to see records here',
                          style: TextStyle(
                              color: Color(0xFF334155), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: calls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _buildCallCard(calls[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallCard(AiCallRecord record) {
    final interestColor = {
      'yes': const Color(0xFF10B981),
      'no': const Color(0xFF64748B),
      'callback': const Color(0xFF3B82F6),
      'unknown': const Color(0xFFFBBF24),
    }[record.interested] ?? const Color(0xFF64748B);

    final interestLabel = {
      'yes': '🟢 Interested',
      'no': '⚪ Not Interested',
      'callback': '🔵 Callback',
      'unknown': '🟡 Pending',
    }[record.interested] ?? '⚪ Unknown';

    final statusColor = {
      'calling': const Color(0xFF10B981),
      'completed': const Color(0xFF6366F1),
      'failed': const Color(0xFFEF4444),
      'no_answer': const Color(0xFF64748B),
      'pending': const Color(0xFFFBBF24),
    }[record.status] ?? const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showUpdateCallDialog(record),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Phone icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: interestColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone_outlined,
                      color: interestColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '+91 ${record.phone}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (record.customerName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${record.customerName})',
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (record.service.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                record.service,
                                style: const TextStyle(
                                    color: Color(0xFF818CF8), fontSize: 10),
                              ),
                            ),
                          if (record.location.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.location_on_outlined,
                                color: Color(0xFF64748B), size: 12),
                            Text(
                              record.location,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      if (record.customerResponse.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.record_voice_over, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text('Customer Response', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record.customerResponse,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: interestColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        interestLabel,
                        style: TextStyle(
                            color: interestColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.status,
                          style: TextStyle(
                              color: statusColor.withOpacity(0.8),
                              fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record.language == 'Malayalam' ? '🇮🇳' : '🇬🇧',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(record.createdAt),
                      style: const TextStyle(
                          color: Color(0xFF475569), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFF475569), size: 18),
                  onPressed: () async {
                    await _callService.deleteCallRecord(record.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.expand_more, color: Color(0xFF475569)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(icon, color: const Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 8),
                        Text(s),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _langChip(String lang, String flag) {
    final isSelected = _selectedLanguage == lang;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
              : null,
          color: isSelected ? null : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFF334155),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
