import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Drawer(
      backgroundColor: appState.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            // ================= LUXURY HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appState.bannerBgStart,
                    appState.bannerBgEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'asset/work connect logo.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    appState.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    appState.appTagline,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ================= MENU LIST =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  // --- QUICK SWITCHES SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      appState.tr('PREFERENCES', 'ക്രമീകരണങ്ങൾ'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: appState.textSecondary,
                      ),
                    ),
                  ),

                  // 1. Language Toggle Tile
                  _buildMenuTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: appState.isMalayalam ? 'മലയാളം (സജീവം)' : 'English (Active)',
                    subtitle: appState.isMalayalam ? 'Switch to English' : 'മലയാളത്തിലേക്ക് മാറ്റുക',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        appState.isMalayalam ? 'EN' : 'മല',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () => appState.toggleLanguage(),
                    appState: appState,
                  ),

                  // 2. Dark / Light Mode Toggle Tile
                  _buildMenuTile(
                    icon: appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: appState.isDarkMode
                        ? appState.tr('Dark Mode', 'ഡാർക്ക് മോഡ്')
                        : appState.tr('Light Mode', 'ലൈറ്റ് മോഡ്'),
                    subtitle: appState.isDarkMode
                        ? appState.tr('Tap for Light theme', 'ലൈറ്റ് മോഡിലേക്ക് മാറ്റുക')
                        : appState.tr('Tap for Dark theme', 'ഡാർക്ക് മോഡിലേക്ക് മാറ്റുക'),
                    trailing: Switch.adaptive(
                      value: appState.isDarkMode,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (val) => appState.toggleTheme(),
                    ),
                    onTap: () => appState.toggleTheme(),
                    appState: appState,
                  ),

                  const SizedBox(height: 12),
                  Divider(color: appState.borderCol),
                  const SizedBox(height: 8),

                  // --- PAGES SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      appState.tr('EXPLORE SERVICES', 'സേവനങ്ങൾ'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: appState.textSecondary,
                      ),
                    ),
                  ),

                  // Home
                  _buildMenuTile(
                    icon: Icons.home_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: appState.tr('Home', 'ഹോം പേജ്'),
                    subtitle: appState.tr('Main dashboard & overview', 'പ്രധാന പേജ്'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/');
                    },
                    appState: appState,
                  ),

                  // Book a Worker
                  _buildMenuTile(
                    icon: Icons.engineering_rounded,
                    iconColor: const Color(0xFFF97316),
                    title: appState.tr('Book a Worker', 'തൊഴിലാളിയെ ബുക്ക് ചെയ്യുക'),
                    subtitle: appState.tr('Electricians, Plumbers, Masons...', 'ഇലക്ട്രീഷ്യൻ, പ്ലംബർ, ഡ്രൈവർ...'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/booking');
                    },
                    appState: appState,
                  ),

                  // Jobs Portal
                  _buildMenuTile(
                    icon: Icons.work_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: appState.tr('Jobs Portal', 'തൊഴിൽ പോർട്ടൽ'),
                    subtitle: appState.tr('Vacancies & Worker Registration', 'ഒഴിവുകളും തൊഴിലന്വേഷകരും'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/jobs');
                    },
                    appState: appState,
                  ),

                  // Contact Us
                  _buildMenuTile(
                    icon: Icons.headset_mic_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: appState.tr('Contact Support', 'സഹായത്തിന് വിളിക്കാം'),
                    subtitle: appState.tr('24x7 Helpline & WhatsApp', 'ഹെൽപ്പ് ലൈൻ & വാട്സ്ആപ്പ്'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/contact');
                    },
                    appState: appState,
                  ),

                  const SizedBox(height: 12),
                  Divider(color: appState.borderCol),
                  const SizedBox(height: 8),

                  // --- CONTACT SHORTCUTS ---
                  StreamBuilder<ContactInfo>(
                    stream: FirestoreService().getContactInfoStream(),
                    builder: (context, snapshot) {
                      final info = snapshot.data ?? ContactInfo();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              appState.tr('QUICK HELPLINE', 'നേരിട്ട് ബന്ധപ്പെടാം'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: appState.textSecondary,
                              ),
                            ),
                          ),
                          _buildMenuTile(
                            icon: Icons.chat_rounded,
                            iconColor: const Color(0xFF22C55E),
                            title: appState.tr('WhatsApp Helpline', 'വാട്സ്ആപ്പ് ഹെൽപ്പ് ലൈൻ'),
                            subtitle: info.whatsapp,
                            onTap: () {
                              Navigator.of(context).pop();
                              final phoneClean = info.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
                              _launchUrl('https://wa.me/$phoneClean?text=Hello%20WorkConnect%20Kerala');
                            },
                            appState: appState,
                          ),
                          _buildMenuTile(
                            icon: Icons.call_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: appState.tr('Direct Phone Call', 'നേരിട്ട് വിളിക്കാം'),
                            subtitle: info.phone,
                            onTap: () {
                              Navigator.of(context).pop();
                              final phoneClean = info.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                              _launchUrl('tel:$phoneClean');
                            },
                            appState: appState,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ================= FOOTER =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: appState.cardBg,
                border: Border(top: BorderSide(color: appState.borderCol)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    appState.tr('WorkConnect Kerala v2.0', 'വർക്ക് കണക്ട് v2.0'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: appState.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Kerala, India',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: appState.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    required AppStateProvider appState,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: appState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appState.borderCol),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: appState.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: appState.textSecondary,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appState.textSecondary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
