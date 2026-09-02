import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state_provider.dart';
import '../services/firestore_service.dart';
import 'widgets/app_drawer.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String whatsappNumber, [String? customMsg]) async {
    final cleanNum = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final message = customMsg ?? 'ഹലോ WorkConnect Kerala, എനിക്ക് ഒരു സഹായം വേണമായിരുന്നു.';
    final url = Uri.parse('https://wa.me/$cleanNum?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'WorkConnect Kerala - Customer Inquiry',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client for $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: appState.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: appState.isDarkMode ? const Color(0xFF070B14) : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appState.tr('Contact & Support', 'ഞങ്ങളുമായി ബന്ധപ്പെടുക'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              appState.tr('24x7 Customer Helpline', 'സഹായത്തിനും വിവരങ്ങൾക്കും'),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<ContactInfo>(
        stream: FirestoreService().getContactInfoStream(),
        builder: (context, snapshot) {
          final info = snapshot.data ?? ContactInfo();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4C81), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F4C81).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'asset/work connect logo.png',
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WorkConnect Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'തൊഴിലാളി ബുക്കിംഗിനും ജോലികൾക്കും ഏത് സമയത്തും വിളിക്കാം അല്ലെങ്കിൽ വാട്സ്ആപ്പ് ചെയ്യാം.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  appState.tr('Quick Connect', 'നേരിട്ട് ബന്ധപ്പെടാം'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appState.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. WhatsApp Button
                _buildActionTile(
                  icon: Icons.chat_rounded,
                  iconColor: Colors.white,
                  iconBg: const Color(0xFF22C55E),
                  title: appState.tr('WhatsApp Chat', 'വാട്സ്ആപ്പ് സന്ദേശം'),
                  subtitle: info.whatsapp,
                  badge: appState.tr('Fast Response', 'ഉടൻ മറുപടി'),
                  onTap: () => _openWhatsApp(info.whatsapp),
                  appState: appState,
                ),
                const SizedBox(height: 12),

                // 2. Call Admin Button
                _buildActionTile(
                  icon: Icons.call_rounded,
                  iconColor: Colors.white,
                  iconBg: const Color(0xFF0284C7),
                  title: appState.tr('Call Admin / Phone', 'നേരിട്ട് വിളിക്കാം'),
                  subtitle: info.phone,
                  badge: appState.tr('Helpline', 'സഹായ നമ്പർ'),
                  onTap: () => _makePhoneCall(info.phone),
                  appState: appState,
                ),
                const SizedBox(height: 12),

                // 3. Email Admin Button
                _buildActionTile(
                  icon: Icons.email_rounded,
                  iconColor: Colors.white,
                  iconBg: const Color(0xFF8B5CF6),
                  title: appState.tr('Email Support', 'ഇമെയിൽ സന്ദേശം'),
                  subtitle: info.email,
                  badge: appState.tr('Official Inquiry', 'വിവരങ്ങൾക്ക്'),
                  onTap: () => _sendEmail(info.email),
                  appState: appState,
                ),
                const SizedBox(height: 20),

                // Office & Hours Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: appState.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: appState.borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.schedule_rounded,
                        appState.tr('Working Hours', 'പ്രവർത്തന സമയം'),
                        info.workingHours,
                        const Color(0xFFF59E0B),
                        appState: appState,
                      ),
                      Divider(height: 24, color: appState.borderCol),
                      _buildInfoRow(
                        Icons.location_on_rounded,
                        appState.tr('Head Office', 'പ്രധാന ഓഫീസ്'),
                        info.address,
                        const Color(0xFFEF4444),
                        appState: appState,
                      ),
                      Divider(height: 24, color: appState.borderCol),
                      _buildInfoRow(
                        Icons.emergency_rounded,
                        appState.tr('Emergency Helpline', 'അടിയന്തര ഹെൽപ്പ് ലൈൻ'),
                        info.emergencyNumber,
                        const Color(0xFF10B981),
                        isAction: true,
                        onTap: () => _makePhoneCall(info.emergencyNumber),
                        appState: appState,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick WhatsApp Message Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appState.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: appState.borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Color(0xFF16A34A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.tr('Send Direct Message', 'വാട്സ്ആപ്പ് സന്ദേശം അയക്കാം'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: appState.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    appState.tr('Direct assistance on WhatsApp', 'ഞങ്ങൾ ഉടൻ മറുപടി നൽകും'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appState.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: appState.tr('Your Name', 'നിങ്ങളുടെ പേര്'),
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            filled: true,
                            fillColor: appState.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: appState.borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: appState.borderCol),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: appState.tr('How can we help you?', 'എന്ത് സഹായമാണ് വേണ്ടത്?'),
                            hintText: appState.tr('Worker requirement, Job details, questions...', 'തൊഴിലാളിയെ വേണം, ജോലി വിവരങ്ങൾ...'),
                            prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                            filled: true,
                            fillColor: appState.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: appState.borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: appState.borderCol),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter message' : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final text = 'ഹലോ WorkConnect Kerala,\n\nപേര്: ${_nameController.text.trim()}\nആവശ്യം: ${_messageController.text.trim()}';
                                _openWhatsApp(info.whatsapp, text);
                              }
                            },
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              appState.tr('Send via WhatsApp', 'വാട്സ്ആപ്പിലേക്ക് അയക്കാം'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appState.navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(top: BorderSide(color: appState.borderCol)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, appState.tr('Home', 'ഹോം'), false, () => context.go('/'), appState),
                _buildNavItem(Icons.engineering_outlined, appState.tr('Book Worker', 'ബുക്കിംഗ്'), false, () => context.go('/booking'), appState),
                _buildNavItem(Icons.work_outline_rounded, appState.tr('Jobs', 'ജോലികൾ'), false, () => context.go('/jobs'), appState),
                _buildNavItem(Icons.headset_mic_rounded, appState.tr('Contact', 'സഹായം'), true, () {}, appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap, AppStateProvider appState) {
    final activeColor = appState.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0F4C81);
    final inactiveColor = appState.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
    required AppStateProvider appState,
  }) {
    return Material(
      color: appState.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appState.borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconBg.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: appState.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconBg.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: iconBg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: appState.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: appState.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String detail,
    Color iconColor, {
    bool isAction = false,
    VoidCallback? onTap,
    required AppStateProvider appState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appState.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAction ? const Color(0xFF0F4C81) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            if (isAction)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.call_rounded, size: 16, color: Color(0xFF10B981)),
              ),
          ],
        ),
      ),
    );
  }
}
