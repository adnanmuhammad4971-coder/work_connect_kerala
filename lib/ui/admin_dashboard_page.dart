import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/sms_notification_service.dart';
import 'ai_call_center_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const BookingsManagement(),
    const CategoriesManagement(),
    const JobApplicationsManagement(),
    const JobsManagement(),
    const WorkersManagement(),
    const AiCallCenterPage(),
    const SettingsManagement(),
  ];

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscured = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF0F4C81)),
                SizedBox(width: 8),
                Text('Change Admin Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter a new password for the administrator account.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => isObscured = !isObscured),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoading = true);
                          try {
                            await AuthService().updatePassword(newPasswordController.text.trim());
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password updated successfully!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update password: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WorkConnect Admin',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.2),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Control Center & Management',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 20),
            tooltip: 'View App / Home',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFBBF24), size: 20),
            tooltip: 'Change Password',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => _showChangePasswordDialog(context),
          ),
          if (!isMobile && user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  user.email ?? 'Admin',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'Logout',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                context.go('/admin/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: const Color(0xFF0F172A),
              selectedItemColor: const Color(0xFF38BDF8),
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 9,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
                BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Categories'),
                BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: 'Seekers'),
                BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), label: 'Jobs'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Workers'),
                BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI Calls'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
              ],
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              backgroundColor: const Color(0xFF0F172A),
              selectedIndex: _selectedIndex,
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              useIndicator: true,
              indicatorColor: const Color(0xFF1E293B),
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Bookings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text('Categories'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: Text('Job Seekers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.business_center_outlined),
                  selectedIcon: Icon(Icons.business_center),
                  label: Text('Job Posts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Workers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: Text('AI Calls'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD OVERVIEW
// ==========================================
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required String subtitle,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: FirestoreService().getBookings(),
      builder: (context, bookingSnap) {
        return StreamBuilder<List<JobApplication>>(
          stream: FirestoreService().getJobApplications(),
          builder: (context, appSnap) {
            return StreamBuilder<List<Job>>(
              stream: FirestoreService().getJobs(),
              builder: (context, jobSnap) {
                final bookings = bookingSnap.data ?? [];
                final applications = appSnap.data ?? [];
                final jobs = jobSnap.data ?? [];

                final totalBookings = bookings.length;
                final pendingBookings = bookings.where((b) => !b.isCustomerPaid).length;
                final settledBookings = bookings.where((b) => b.isCustomerPaid && b.isWorkerPaid).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Executive Dashboard',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Real-time performance metrics',
                                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Customer Site', style: TextStyle(fontSize: 13)),
                            onPressed: () => context.go('/'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _buildStatCard(
                            title: 'Total Bookings',
                            value: '$totalBookings',
                            icon: Icons.calendar_month,
                            gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            subtitle: '$pendingBookings pending actions',
                          ),
                          _buildStatCard(
                            title: 'Settled Bookings',
                            value: '$settledBookings',
                            icon: Icons.verified,
                            gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
                            subtitle: 'Fully settled',
                          ),
                          _buildStatCard(
                            title: 'Job Seekers',
                            value: '${applications.length}',
                            icon: Icons.badge,
                            gradientColors: const [Color(0xFFD97706), Color(0xFFB45309)],
                            subtitle: 'Candidates ready',
                          ),
                          _buildStatCard(
                            title: 'Job Postings',
                            value: '${jobs.length}',
                            icon: Icons.business,
                            gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            subtitle: 'Active listings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Manual Commission & Settlement Flow',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '1. Customer requests a worker on the main website.\n'
                              '2. In "Bookings", assign an available worker from your directory.\n'
                              '3. When finished, call customer, receive payment, click "Mark Customer Paid".\n'
                              '4. Transfer wage minus commission to worker, click "Mark Worker Paid".',
                              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 7. SETTINGS & CONTACT INFO MANAGEMENT
// ==========================================
class SettingsManagement extends StatefulWidget {
  const SettingsManagement({super.key});

  @override
  State<SettingsManagement> createState() => _SettingsManagementState();
}

class _SettingsManagementState extends State<SettingsManagement> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _appTaglineController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();

  // Location / District management
  final _newDistrictController = TextEditingController();
  bool _isAddingDistrict = false;

  // SMS Notification settings controllers
  final _adminSmsPhoneController = TextEditingController();
  final _smsApiKeyController = TextEditingController();
  final _smsSenderIdController = TextEditingController();
  final _smsCustomUrlController = TextEditingController();

  bool _enableSmsAlerts = true;
  String _smsGatewayProvider = 'fast2sms';
  bool _obscureApiKey = true;
  bool _isSaving = false;
  bool _isTestingSms = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _appNameController.dispose();
    _appTaglineController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _newDistrictController.dispose();
    _adminSmsPhoneController.dispose();
    _smsApiKeyController.dispose();
    _smsSenderIdController.dispose();
    _smsCustomUrlController.dispose();
    super.dispose();
  }

  void _populateFields(ContactInfo info) {
    if (!_isInitialized) {
      _appNameController.text = info.appName;
      _appTaglineController.text = info.appTagline;
      _phoneController.text = info.phone;
      _whatsappController.text = info.whatsapp;
      _emailController.text = info.email;
      _emergencyController.text = info.emergencyNumber;
      _addressController.text = info.address;
      _hoursController.text = info.workingHours;
      _adminSmsPhoneController.text = info.adminSmsNumber.isNotEmpty ? info.adminSmsNumber : info.phone;
      _enableSmsAlerts = info.enableSmsAlerts;
      _smsGatewayProvider = info.smsGatewayProvider;
      _smsApiKeyController.text = info.smsApiKey;
      _smsSenderIdController.text = info.smsSenderId;
      _smsCustomUrlController.text = info.smsCustomUrl;
      _isInitialized = true;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedInfo = ContactInfo(
        appName: _appNameController.text.trim().isNotEmpty ? _appNameController.text.trim() : 'WorkConnect Kerala',
        appTagline: _appTaglineController.text.trim().isNotEmpty ? _appTaglineController.text.trim() : 'Instant Worker Booking & Kerala Jobs Portal',
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        emergencyNumber: _emergencyController.text.trim(),
        address: _addressController.text.trim(),
        workingHours: _hoursController.text.trim(),
        adminSmsNumber: _adminSmsPhoneController.text.trim(),
        enableSmsAlerts: _enableSmsAlerts,
        smsGatewayProvider: _smsGatewayProvider,
        smsApiKey: _smsApiKeyController.text.trim(),
        smsSenderId: _smsSenderIdController.text.trim(),
        smsCustomUrl: _smsCustomUrlController.text.trim(),
      );

      await FirestoreService().updateContactInfo(updatedInfo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App Settings, Branding & Admin Alert configurations saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addLocation() async {
    final name = _newDistrictController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAddingDistrict = true);
    try {
      await FirestoreService().addDistrict(name);
      _newDistrictController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$name" added successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding location: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingDistrict = false);
    }
  }

  Future<void> _deleteLocation(String name) async {
    try {
      await FirestoreService().deleteDistrict(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$name" removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing location: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _resetDistricts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Locations?'),
        content: const Text('Do you want to reset the service locations list back to the standard 14 Kerala districts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirestoreService().resetDistrictsToDefault();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Locations reset to Kerala 14 Districts default')),
        );
      }
    }
  }

  Future<void> _testSmsNotification() async {
    final targetPhone = _adminSmsPhoneController.text.trim().isNotEmpty
        ? _adminSmsPhoneController.text.trim()
        : _phoneController.text.trim();

    if (targetPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Admin Phone Number first')),
      );
      return;
    }

    setState(() => _isTestingSms = true);

    try {
      final tempInfo = ContactInfo(
        phone: _phoneController.text.trim(),
        adminSmsNumber: targetPhone,
        enableSmsAlerts: _enableSmsAlerts,
        smsGatewayProvider: _smsGatewayProvider,
        smsApiKey: _smsApiKeyController.text.trim(),
        smsSenderId: _smsSenderIdController.text.trim(),
        smsCustomUrl: _smsCustomUrlController.text.trim(),
      );

      final result = await SmsNotificationService().sendTestSms(targetPhone, tempInfo);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: result.success ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(result.success ? 'SMS Status: Success' : 'SMS Notice'),
              ],
            ),
            content: Text(
              result.message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test SMS error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingSms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContactInfo>(
      stream: FirestoreService().getContactInfoStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _populateFields(snapshot.data!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.contact_phone_rounded, color: Color(0xFF38BDF8), size: 32),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Settings, Branding & Locations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Customize App Name, Service Locations/Districts, Contact details, and SMS alerts.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. APP BRANDING & NAME CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.branding_watermark_rounded, color: Color(0xFF6366F1), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'App Name & Branding (ആപ്പ് പേര് മാറ്റാം)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Change the display name and tagline of your application',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 14),

                          // App Name
                          TextFormField(
                            controller: _appNameController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Application Name (ആപ്പ് പേര്)',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: 'WorkConnect Kerala',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              helperText: 'e.g. WorkConnect Kerala, WorkConnect India, WorkConnect Gulf',
                              helperStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF6366F1)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // App Tagline
                          TextFormField(
                            controller: _appTaglineController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'App Tagline / Slogan (വിവരണം)',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: 'Instant Worker Booking & Kerala Jobs Portal',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.short_text_rounded, color: Color(0xFF8B5CF6)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. ULTRA-PREMIUM SERVICE LOCATIONS & DISTRICTS MANAGEMENT CARD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Luxury Card Top Gradient Bar
                            Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row with Icon and Cloud Badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF065F46), Color(0xFF047857)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF059669).withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Expanded(
                                                  child: Text(
                                                    'Service Locations & Districts',
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF0F172A),
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.cloud_sync_rounded, size: 13, color: Color(0xFF059669)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'REALTIME SYNC',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: 0.4,
                                                          color: Color(0xFF059669),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            const Text(
                                              'Add outside cities, states, or countries (e.g. Bengaluru, Dubai, Chennai, Coimbatore)',
                                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  const SizedBox(height: 16),

                                  // Separate Add Location Input & Add Button Container
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // 1. TextFormField
                                      TextFormField(
                                        controller: _newDistrictController,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Add New Location / District / City (പുതിയ സ്ഥലം)',
                                          labelStyle: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 13,
                                          ),
                                          hintText: 'e.g. Bengaluru, Dubai, Coimbatore, Chennai',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.pin_drop_rounded,
                                            color: Color(0xFF10B981),
                                            size: 22,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF10B981),
                                              width: 1.8,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 15,
                                          ),
                                        ),
                                        onFieldSubmitted: (_) => _addLocation(),
                                      ),

                                      const SizedBox(height: 10),

                                      // 2. Add Button
                                      SizedBox(
                                        height: 52,
                                        width: double.infinity,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF059669),
                                                Color(0xFF10B981),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 18),
                                            ),
                                            onPressed: _isAddingDistrict ? null : _addLocation,
                                            icon: _isAddingDistrict
                                                ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                                : const Icon(
                                              Icons.add_circle_rounded,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              'Add / ചേർക്കുക',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Quick 1-Tap Suggestions Bar
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Quick Add: ',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                                        ),
                                        ...['Bengaluru', 'Dubai', 'Chennai', 'Coimbatore', 'Mumbai', 'Kochi City'].map((suggestion) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: InkWell(
                                              onTap: () {
                                                _newDistrictController.text = suggestion;
                                                _addLocation();
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.add_rounded, size: 12, color: Color(0xFF059669)),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      suggestion,
                                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Live locations chips container
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: StreamBuilder<List<String>>(
                                      stream: FirestoreService().getDistrictsStream(),
                                      builder: (context, distSnap) {
                                        final districts = distSnap.data ?? FirestoreService().keralaDefaultDistricts;

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF10B981),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Active Service Locations (${districts.length})',
                                                    style: const TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: _resetDistricts,
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.restore_rounded, size: 14, color: Color(0xFF64748B)),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Reset Kerala 14',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF475569),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: districts.map((dist) {
                                                return Container(
                                                  padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.02),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF10B981)),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        dist,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () => _deleteLocation(dist),
                                                        borderRadius: BorderRadius.circular(20),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(3),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFEE2E2),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.close_rounded,
                                                            size: 13,
                                                            color: Color(0xFFEF4444),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. ADMIN DIRECT SMS NOTIFICATION SETTINGS CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.sms_rounded, color: Color(0xFF0284C7), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Booking SMS Alerts (അഡ്മിൻ SMS)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Send instant SMS to admin phone when a customer creates a booking',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _enableSmsAlerts,
                                activeColor: const Color(0xFF0284C7),
                                onChanged: (val) => setState(() => _enableSmsAlerts = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 14),

                          // Admin SMS Alert Number
                          TextFormField(
                            controller: _adminSmsPhoneController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Admin Mobile Number for SMS Alerts (അഡ്മിൻ നമ്പർ)',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: '+91 8129540062',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              helperText: 'SMS notifications for new bookings will be delivered to this number',
                              helperStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.phonelink_ring_rounded, color: Color(0xFF0284C7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gateway selector
                          DropdownButtonFormField<String>(
                            value: _smsGatewayProvider,
                            isExpanded: true,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'SMS Gateway Provider (SMS സർവീസ്)',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              prefixIcon: const Icon(Icons.router_rounded, color: Color(0xFF8B5CF6)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'fast2sms',
                                child: Text('Fast2SMS (Recommended for India / Quick SMS)', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF0F172A))),
                              ),
                              DropdownMenuItem(
                                value: 'twofactor',
                                child: Text('2Factor.in (Transactional SMS India)', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF0F172A))),
                              ),
                              DropdownMenuItem(
                                value: 'custom_api',
                                child: Text('Custom SMS HTTP Webhook / API', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF0F172A))),
                              ),
                              DropdownMenuItem(
                                value: 'direct_intent',
                                child: Text('Direct Device SMS Intent (Opens SMS app)', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF0F172A))),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _smsGatewayProvider = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // API Key field (for Fast2SMS, 2Factor, Custom API)
                          if (_smsGatewayProvider != 'direct_intent') ...[
                            TextFormField(
                              controller: _smsApiKeyController,
                              obscureText: _obscureApiKey,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'SMS Gateway API Key / Authorization Token',
                                labelStyle: const TextStyle(color: Color(0xFF475569)),
                                hintText: 'Enter API authorization key',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                helperText: _smsGatewayProvider == 'fast2sms'
                                    ? 'Get free/low-cost API key from fast2sms.com (Dev API / Bulk SMS)'
                                    : 'API Key from your SMS service provider dashboard',
                                helperStyle: const TextStyle(color: Color(0xFF64748B)),
                                prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFFF59E0B)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B)),
                                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Sender ID (for 2Factor)
                          if (_smsGatewayProvider == 'twofactor') ...[
                            TextFormField(
                              controller: _smsSenderIdController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Sender ID / Header (e.g. WKCONN)',
                                labelStyle: const TextStyle(color: Color(0xFF475569)),
                                hintText: 'WKCONN',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF10B981)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Custom URL (for custom_api)
                          if (_smsGatewayProvider == 'custom_api') ...[
                            TextFormField(
                              controller: _smsCustomUrlController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Custom Webhook / SMS API Endpoint URL',
                                labelStyle: const TextStyle(color: Color(0xFF475569)),
                                hintText: 'https://api.your-sms-service.com/send',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF06B6D4)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Test SMS Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0284C7),
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isTestingSms ? null : _testSmsNotification,
                              icon: _isTestingSms
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: Text(_isTestingSms ? 'Sending Test SMS...' : 'Send Test SMS / ടെസ്റ്റ് SMS'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Card with App Contact Form fields
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Support Channels (User App)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Customer Helpline / Phone Number',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: '+91 9876543210',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.call_rounded, color: Color(0xFF0284C7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // WhatsApp Number
                          TextFormField(
                            controller: _whatsappController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'WhatsApp Contact Number (With country code)',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: '919876543210',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              helperText: 'Enter without plus sign e.g. 919876543210',
                              helperStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.chat_rounded, color: Color(0xFF16A34A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'WhatsApp is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email Address
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Official Support Email',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: 'support@workconnectkerala.in',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF8B5CF6)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Emergency Number
                          TextFormField(
                            controller: _emergencyController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: '24x7 Emergency Contact Number',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: '+91 9876543210',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Divider(color: Color(0xFFF1F5F9), height: 32),

                          const Text(
                            'Office & Operations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Office Address
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Head Office Address',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: 'Mavoor Road, Kozhikode, Kerala - 673001',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFF59E0B)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Working Hours
                          TextFormField(
                            controller: _hoursController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Working Hours',
                              labelStyle: const TextStyle(color: Color(0xFF475569)),
                              hintText: 'Mon - Sun: 7:00 AM - 10:00 PM',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFF0D9488)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 26),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C81),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              onPressed: _isSaving ? null : _saveSettings,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_rounded, size: 20),
                              label: Text(
                                _isSaving ? 'Saving Changes...' : 'Save Settings / മാറ്റങ്ങൾ സേവ് ചെയ്യുക',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Customer Reviews Moderation Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Customer Reviews & Ratings',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => FirestoreService().seedDefaultReviewsIfEmpty(),
                                child: const Text('Seed Sample Reviews', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<UserReview>>(
                            stream: FirestoreService().getReviewsStream(),
                            builder: (context, revSnapshot) {
                              if (revSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                              }
                              final revs = revSnapshot.data ?? [];
                              if (revs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text('No reviews submitted yet.', style: TextStyle(color: Color(0xFF64748B))),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: revs.length,
                                separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final r = revs[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Row(
                                      children: [
                                        Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 2),
                                            Text('${r.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('📍 ${r.district}${r.serviceCategory != null ? " • ${r.serviceCategory}" : ""}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(r.comment, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      tooltip: 'Delete Review',
                                      onPressed: () async {
                                        await FirestoreService().deleteReview(r.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Review deleted')),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ==========================================
// 2. BOOKINGS MANAGEMENT
// ==========================================
class BookingsManagement extends StatelessWidget {
  const BookingsManagement({super.key});

  void _showAssignWorkerDialog(BuildContext context, Booking booking) {
    final controller = TextEditingController(text: booking.assignedWorkerId ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Worker to Booking #${booking.id.substring(booking.id.length > 6 ? booking.id.length - 6 : 0)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Required: ${booking.requiredWorkerCategory}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Worker Name / ID / Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                FirestoreService().assignWorkerToBooking(booking.id, controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Worker assigned successfully!')),
                );
              }
            },
            child: const Text('Assign Worker'),
          ),
        ],
      ),
    );
  }

  void _showEditBookingDialog(BuildContext context, Booking booking) {
    final nameCtrl = TextEditingController(text: booking.customerName);
    final phoneCtrl = TextEditingController(text: booking.customerPhone);
    final locationCtrl = TextEditingController(text: booking.location);
    final countCtrl = TextEditingController(text: booking.numberOfWorkers.toString());
    String status = booking.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Edit Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Customer Phone')),
                const SizedBox(height: 8),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 8),
                TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Workers Count')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                    DropdownMenuItem(value: 'Worker Assigned', child: Text('Worker Assigned')),
                    DropdownMenuItem(value: 'Work Started', child: Text('Work Started')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) => setModalState(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: () {
                FirestoreService().updateBooking(booking.id, {
                  'customerName': nameCtrl.text.trim(),
                  'customerPhone': phoneCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'numberOfWorkers': int.tryParse(countCtrl.text.trim()) ?? booking.numberOfWorkers,
                  'status': status,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking updated successfully!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBooking(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              FirestoreService().deleteBooking(bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Bookings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Review, assign workers, edit, and track settlements', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: FirestoreService().getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        const Text('No bookings received yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!;
                return ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final isSettled = booking.isCustomerPaid && booking.isWorkerPaid;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSettled ? Colors.green.shade200 : Colors.blueGrey.shade100,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        booking.requiredWorkerCategory,
                                        style: const TextStyle(
                                          color: Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        booking.status,
                                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                    tooltip: 'Edit Booking',
                                    onPressed: () => _showEditBookingDialog(context, booking),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: 'Delete Booking',
                                    onPressed: () => _confirmDeleteBooking(context, booking.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('👤 Customer: ${booking.customerName} (${booking.customerPhone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              InkWell(
                                onTap: () {
                                  final uri = Uri.parse('tel:${booking.customerPhone}');
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.call, size: 13, color: Colors.green.shade700),
                                      const SizedBox(width: 4),
                                      Text('Call', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('📍 Location: ${booking.location}', style: const TextStyle(fontSize: 13)),
                              InkWell(
                                onTap: () {
                                  final mapUrl = booking.mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(booking.location)}';
                                  launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF93C5FD)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, size: 13, color: Color(0xFF2563EB)),
                                      SizedBox(width: 4),
                                      Text('Open in Google Maps 🗺️', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('👥 Workers: ${booking.numberOfWorkers} | 📅 Date: ${booking.date.day}/${booking.date.month}/${booking.date.year} (${booking.time})', style: const TextStyle(fontSize: 13)),
                          Text('👷 Assigned: ${booking.assignedWorkerId ?? "None"}', style: TextStyle(color: booking.assignedWorkerId != null ? Colors.blue.shade900 : Colors.orange.shade900, fontWeight: FontWeight.w600, fontSize: 13)),
                          const Divider(height: 18),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                icon: const Icon(Icons.person_pin, size: 15),
                                label: Text(booking.assignedWorkerId == null ? 'Assign' : 'Reassign', style: const TextStyle(fontSize: 12)),
                                onPressed: () => _showAssignWorkerDialog(context, booking),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      backgroundColor: booking.isCustomerPaid ? const Color(0xFF059669) : const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: booking.isCustomerPaid
                                        ? null
                                        : () => FirestoreService().markCustomerPaid(booking.id),
                                    child: Text(booking.isCustomerPaid ? 'Cust Paid ✓' : 'Cust Paid', style: const TextStyle(fontSize: 12)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      backgroundColor: booking.isWorkerPaid ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: booking.isWorkerPaid
                                        ? null
                                        : () => FirestoreService().markWorkerPaid(booking.id),
                                    child: Text(booking.isWorkerPaid ? 'Worker Paid ✓' : 'Worker Paid', style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. CATEGORIES MANAGEMENT
// ==========================================
class CategoriesManagement extends StatelessWidget {
  const CategoriesManagement({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Trade Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Category Name (e.g. Driver, Plumber)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.handyman),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final categoryName = nameCtrl.text.trim();
                final categoryId = categoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                final newCat = WorkerCategory(
                  id: categoryId,
                  name: categoryName,
                  icon: 'handyman',
                  colorValue: 0xFF2563EB,
                );
                FirestoreService().createCategory(newCat);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$categoryName" added!')),
                );
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WorkerCategory category) {
    final nameCtrl = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                FirestoreService().updateCategory(category.id, {'name': nameCtrl.text.trim()});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category updated!')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, WorkerCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              FirestoreService().deleteCategory(category.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category "${category.name}" deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trade Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Add or edit customer categories', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    icon: const Icon(Icons.auto_fix_high, size: 15),
                    label: const Text('Sync Defaults', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      await FirestoreService().seedAllKeralaCategories();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('18 Kerala categories synchronized!')),
                        );
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddCategoryDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<WorkerCategory>>(
              stream: FirestoreService().getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 48, color: Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        const Text('No Categories Configured', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Load 18 Default Kerala Categories'),
                          onPressed: () => FirestoreService().seedAllKeralaCategories(),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 80,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(cat.colorValue).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.handyman, color: Color(cat.colorValue), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                            onPressed: () => _showEditCategoryDialog(context, cat),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteCategory(context, cat),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. JOB APPLICATIONS
// ==========================================
class JobApplicationsManagement extends StatelessWidget {
  const JobApplicationsManagement({super.key});

  void _updateApplicationStatus(BuildContext context, String id, String status) {
    FirestoreService().updateJobApplicationStatus(id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application marked as $status!')),
    );
  }

  void _confirmDeleteApplication(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job Application'),
        content: const Text('Are you sure you want to remove this applicant permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              FirestoreService().deleteJobApplication(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Seeker Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Candidate profiles from the /jobs portal', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<JobApplication>>(
              stream: FirestoreService().getJobApplications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 48, color: Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        const Text('No Job Applications Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final applications = snapshot.data!;
                return ListView.separated(
                  itemCount: applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    Color badgeColor = app.status == 'Approved'
                        ? Colors.green
                        : app.status == 'Rejected'
                            ? Colors.red
                            : app.status == 'Contacted'
                                ? Colors.blue
                                : Colors.orange;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  app.applicantName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      app.status,
                                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () => _confirmDeleteApplication(context, app.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text('📞 ${app.phone}', style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700)),
                          const SizedBox(height: 4),
                          Text('🛠️ Skills: ${app.skills}', style: const TextStyle(fontSize: 13)),
                          const Divider(height: 16),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                onPressed: () => _updateApplicationStatus(context, app.id, 'Contacted'),
                                child: const Text('Contacted', style: TextStyle(fontSize: 12)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () => _updateApplicationStatus(context, app.id, 'Approved'),
                                child: const Text('Approve', style: TextStyle(fontSize: 12)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () => _updateApplicationStatus(context, app.id, 'Reject'),
                                child: const Text('Reject', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. JOBS MANAGEMENT
// ==========================================
class JobsManagement extends StatelessWidget {
  const JobsManagement({super.key});

  void _showAddJobDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final employerCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final vacanciesCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Job Vacancy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
              const SizedBox(height: 8),
              TextField(controller: employerCtrl, decoration: const InputDecoration(labelText: 'Company / Employer')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location / City')),
              const SizedBox(height: 8),
              TextField(controller: vacanciesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vacancies')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                final newJob = Job(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  employerId: employerCtrl.text.trim(),
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  category: 'General',
                  location: locationCtrl.text.trim(),
                  vacancies: int.tryParse(vacanciesCtrl.text.trim()) ?? 1,
                  status: 'Approved',
                );
                FirestoreService().createJob(newJob);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job added & published!')),
                );
              }
            },
            child: const Text('Add Job'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to remove this job vacancy?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              FirestoreService().deleteJob(jobId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Employer Jobs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Approve or publish listings', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Job', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddJobDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Job>>(
              stream: FirestoreService().getJobs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_center_outlined, size: 48, color: Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        const Text('No Job Postings Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final jobs = snapshot.data!;
                return ListView.separated(
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final isApproved = job.status == 'Approved';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  job.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isApproved ? Colors.green.shade300 : Colors.amber.shade300),
                                    ),
                                    child: Text(
                                      job.status,
                                      style: TextStyle(
                                        color: isApproved ? Colors.green.shade800 : Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    onPressed: () => _confirmDeleteJob(context, job.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text('Employer: ${job.employerId}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          Text('📍 ${job.location} | 👥 Vacancies: ${job.vacancies}', style: const TextStyle(fontSize: 12)),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isApproved)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => FirestoreService().updateJobStatus(job.id, 'Approved'),
                                  child: const Text('Approve & Publish', style: TextStyle(fontSize: 12)),
                                ),
                              if (isApproved)
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                  onPressed: () => FirestoreService().updateJobStatus(job.id, 'Closed'),
                                  child: const Text('Close Vacancy', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. WORKERS MANAGEMENT
// ==========================================
class WorkersManagement extends StatelessWidget {
  const WorkersManagement({super.key});

  void _showAddWorkerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Electrician');
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Worker to Directory'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Trade Category (e.g. Mason, Driver, Plumber)')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location / District')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                final newWorker = Worker(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  isActive: true,
                  rating: 5.0,
                );
                FirestoreService().createWorker(newWorker);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Worker added!')),
                );
              }
            },
            child: const Text('Save Worker'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWorker(BuildContext context, String workerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker'),
        content: const Text('Are you sure you want to remove this worker from the directory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              FirestoreService().deleteWorker(workerId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Worker deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registered Workers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Skilled Kerala labourers', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Worker', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddWorkerDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Worker>>(
              stream: FirestoreService().getWorkers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.blueGrey.shade300),
                        const SizedBox(height: 12),
                        const Text('No Workers Added Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final workers = snapshot.data!;
                return ListView.separated(
                  itemCount: workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: const Icon(Icons.engineering, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        worker.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        worker.category,
                                        style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('📞 ${worker.phone} | 📍 ${worker.location}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: worker.isActive,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (_) => FirestoreService().toggleWorkerStatus(worker.id, worker.isActive),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () => _confirmDeleteWorker(context, worker.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
