import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state_provider.dart';
import '../services/firestore_service.dart';
import 'widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _searchServices = [
    {'name': 'Electrician', 'ml': 'ഇലക്ട്രീഷ്യൻ', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Plumber', 'ml': 'പ്ലംബർ', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF0284C7)},
    {'name': 'Driver', 'ml': 'ഡ്രൈവർ', 'icon': Icons.directions_car_filled_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'Mason', 'ml': 'മേസൻ / തേപ്പ്', 'icon': Icons.foundation_rounded, 'color': Color(0xFFEA580C)},
    {'name': 'Painter', 'ml': 'പെയിന്റർ', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Carpenter', 'ml': 'ആശാരി / കാർപെന്റർ', 'icon': Icons.carpenter_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Welder', 'ml': 'വെൽഡർ', 'icon': Icons.construction_rounded, 'color': Color(0xFF64748B)},
    {'name': 'Cleaning & Maid', 'ml': 'ക്ലീനിംഗ് & വീട്ടുസഹായം', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF10B981)},
    {'name': 'AC & Fridge Mechanic', 'ml': 'എസി & ഫ്രിഡ്ജ് മെക്കാനിക്', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'CCTV Technician', 'ml': 'സിസിടിവി ടെക്നീഷ്യൻ', 'icon': Icons.videocam_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Tiles & Granite', 'ml': 'ടൈൽ & ഗ്രാനൈറ്റ്', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF0D9488)},
    {'name': 'Coconut Climber', 'ml': 'മരംവെട്ട് & തെങ്ങ് കയറ്റം', 'icon': Icons.park_rounded, 'color': Color(0xFF16A34A)},
    {'name': 'Home Nurse & Caretaker', 'ml': 'ഹോം നഴ്സ് & പരിചരണം', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFE11D48)},
    {'name': 'Gardener', 'ml': 'തോട്ടം പണി & ഗാർഡനർ', 'icon': Icons.yard_rounded, 'color': Color(0xFF15803D)},
    {'name': 'Cook & Catering', 'ml': 'പാചകക്കാരൻ / കുക്ക്', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFD97706)},
    {'name': 'Delivery Partner', 'ml': 'ഡെലിവറി', 'icon': Icons.two_wheeler_rounded, 'color': Color(0xFF4F46E5)},
  ];

  final List<String> _keralaDistricts = [
    'Kozhikode',
    'Malappuram',
    'Ernakulam (Kochi)',
    'Thrissur',
    'Kannur',
    'Thiruvananthapuram',
    'Palakkad',
    'Kollam',
    'Alappuzha',
    'Kottayam',
    'Wayanad',
    'Kasaragod',
    'Idukki',
    'Pathanamthitta',
  ];

  @override
  void initState() {
    super.initState();
    _firestoreService.seedDefaultReviewsIfEmpty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddReviewDialog(BuildContext context) {
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    String selectedDistrict = 'Kozhikode';
    String selectedCategory = 'General Service';
    double selectedRating = 5.0;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Theme.of(context).cardColor,
            title: const Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rate & Review Service',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'നിങ്ങളുടെ അഭിപ്രായവും റേറ്റിംഗും രേഖപ്പെടുത്തുക:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    // Star Rating Selector
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final starValue = index + 1.0;
                            return InkWell(
                              onTap: () => setDialogState(() => selectedRating = starValue),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  selectedRating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFD97706),
                                  size: 32,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Your Name
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name / പേര്',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),

                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'District / ജില്ല',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _keralaDistricts.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedDistrict = val ?? 'Kozhikode'),
                    ),
                    const SizedBox(height: 12),

                    // Service Category
                    TextFormField(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Service Availed / സേവനം (Optional)',
                        prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) => selectedCategory = val.trim(),
                    ),
                    const SizedBox(height: 12),

                    // Review Comment
                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Review Feedback / അഭിപ്രായം',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please write a brief feedback' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel / റദ്ദാക്കുക', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);

                        final newRev = UserReview(
                          id: '',
                          userName: nameController.text.trim(),
                          district: selectedDistrict,
                          serviceCategory: selectedCategory.isNotEmpty ? selectedCategory : 'General Service',
                          rating: selectedRating,
                          comment: commentController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await _firestoreService.createReview(newRev);

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('നന്ദി! നിങ്ങളുടെ അഭിപ്രായം രേഖപ്പെടുത്തി. (Review submitted!)'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit Review'),
              ),
            ],
          );
        },
      ),
    );
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'asset/work connect logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.work_rounded, color: Color(0xFFD4AF37), size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appState.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    appState.appTagline,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF38BDF8), size: 22),
            tooltip: 'Support & Helpline',
            onPressed: () => context.go('/contact'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO BANNER & SEARCH
            _buildHeroBanner(context, appState),

            // 2. QUICK PRIMARY ACTIONS (Book Worker / Find Jobs)
            _buildPrimaryActions(context, appState),

            // 3. POPULAR CATEGORIES (Dynamic from Firestore)
            _buildCategorySection(context, appState),

            // 4. EMERGENCY & 24/7 HELPLINE
            _buildEmergencyHelpline(context, appState),

            // 5. LIVE STATS COUNTER
            _buildStatsSection(appState),

            // 6. WHY CHOOSE WORKCONNECT KERALA
            _buildWhyUsSection(appState),

            // 7. CUSTOMER TESTIMONIALS
            _buildTestimonialsSection(appState),

            // 8. FOOTER WITH QUICK LINKS & ADMIN LOGIN
            _buildFooter(context, appState),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appState.navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: appState.borderCol)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, appState.tr('Home', 'ഹോം'), true, () {}, appState),
                _buildNavItem(Icons.engineering_outlined, appState.tr('Book Worker', 'ബുക്കിംഗ്'), false, () => context.go('/booking'), appState),
                _buildNavItem(Icons.work_outline_rounded, appState.tr('Jobs Portal', 'ജോലികൾ'), false, () => context.go('/jobs'), appState),
                _buildNavItem(Icons.headset_mic_outlined, appState.tr('Contact Us', 'സഹായം'), false, () => context.go('/contact'), appState),
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

    return AnimatedPressCard(
      scaleDown: 0.92,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
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

  Widget _buildHeroBanner(BuildContext context, AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050B14),
            Color(0xFF0A192F),
            Color(0xFF0F2E4A),
            Color(0xFF0F4C81),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Pill Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      appState.tr('Kerala\'s #1 Verified Service Network', 'കേരളത്തിലെ വിശ്വസ്ത സേവന നെറ്റ്‌വർക്ക്'),
                      style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Hero Title
          Text(
            appState.tr(
              'Find Trusted Workers &\nJob Openings Across Kerala',
              'വിശ്വസ്തരായ തൊഴിലാളികളും\nതൊഴിൽ അവസരങ്ങളും ഒരുമിച്ച്',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.3,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            appState.tr(
              'Instant booking for Electrician, Plumber, Driver, Mason, Painter & more.',
              'ഇലക്ട്രീഷ്യൻ, പ്ലംബർ, ഡ്രൈവർ, മേസൻ തുടങ്ങി ഏത് സേവനവും നിങ്ങളുടെ വിരൽത്തുമ്പിൽ.',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // Interactive Luxury Themed Search Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C192E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: appState.tr('Search service (e.g. Electrician, Painter)...', 'സേവനം തിരയുക (ഉദാ: പ്ലംബർ, ഡ്രൈവർ)...'),
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            context.go('/booking?category=${Uri.encodeComponent(query.trim())}');
                          }
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Color(0xFF64748B), size: 20),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 2,
                      ),
                      onPressed: () {
                        final q = _searchController.text.trim();
                        if (q.isNotEmpty) {
                          context.go('/booking?category=${Uri.encodeComponent(q)}');
                        } else {
                          context.go('/booking');
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(
                        appState.tr('Find', 'തിരയുക'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Auto Suggestions Overlay Box (Themed)
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final filtered = _searchServices.where((s) {
                      final name = (s['name'] as String).toLowerCase();
                      final ml = (s['ml'] as String).toLowerCase();
                      final q = _searchQuery.toLowerCase();
                      return name.contains(q) || ml.contains(q);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A192F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          appState.tr('No exact match. Tap Find to request custom booking.', 'കൃത്യമായ വിഭാഗം കണ്ടെത്തിയില്ല. Find അമർത്തുക.'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      );
                    }

                    return Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A192F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: const Color(0xFF1E293B)),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final name = item['name'] as String;
                          final ml = item['ml'] as String;
                          final icon = item['icon'] as IconData;
                          final col = item['color'] as Color;

                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: col, size: 18),
                            ),
                            title: Text(
                              appState.isMalayalam ? '$ml ($name)' : '$name ($ml)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF38BDF8)),
                            onTap: () {
                              _searchController.text = name;
                              setState(() => _searchQuery = '');
                              context.go('/booking?category=${Uri.encodeComponent(name)}');
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Quick Popular Service Chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickSearchChip('⚡ Electrician', 'ഇലക്ട്രീഷ്യൻ', () => _selectServiceTag('Electrician')),
                _buildQuickSearchChip('💧 Plumber', 'പ്ലംബർ', () => _selectServiceTag('Plumber')),
                _buildQuickSearchChip('🚗 Driver', 'ഡ്രൈവർ', () => _selectServiceTag('Driver')),
                _buildQuickSearchChip('🧱 Mason', 'മേസൻ', () => _selectServiceTag('Mason')),
                _buildQuickSearchChip('🎨 Painter', 'പെയിന്റർ', () => _selectServiceTag('Painter')),
                _buildQuickSearchChip('❄️ AC Repair', 'എസി സർവീസ്', () => _selectServiceTag('AC & Fridge Mechanic')),
                _buildQuickSearchChip('🧹 Cleaning', 'ക്ലീനിംഗ്', () => _selectServiceTag('Cleaning & Maid')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectServiceTag(String serviceName) {
    _searchController.text = serviceName;
    setState(() => _searchQuery = '');
    context.go('/booking?category=${Uri.encodeComponent(serviceName)}');
  }

  Widget _buildQuickSearchChip(String enLabel, String mlLabel, VoidCallback onTap) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
          ),
          child: Text(
            appState.isMalayalam ? mlLabel : enLabel,
            style: const TextStyle(
              color: Color(0xFFFFE08A),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildBigCard(
              title: appState.tr('Book Worker', 'തൊഴിലാളിയെ ബുക്ക് ചെയ്യാം'),
              subtitle: appState.tr('Instant home & site service', 'തൊഴിലാളിയെ വേണം'),
              icon: Icons.person_search_rounded,
              gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
              badge: appState.tr('Instant Call', 'അതിവേഗ സേവനം'),
              onTap: () => context.go('/booking'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBigCard(
              title: appState.tr('Jobs Portal', 'തൊഴിൽ പോർട്ടൽ'),
              subtitle: appState.tr('Vacancies & Postings', 'ജോലി ഒഴിവുകൾ'),
              icon: Icons.work_history_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              badge: appState.tr('Direct Connect', 'നേരിട്ടുള്ള കണക്ഷൻ'),
              onTap: () => context.go('/jobs'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String badge,
    required VoidCallback onTap,
  }) {
    return AnimatedPressCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.tr('Popular Categories', 'പ്രധാന തൊഴിൽ വിഭാഗങ്ങൾ'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: appState.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      appState.tr('Choose a verified service category', 'തൊഴിൽ വിഭാഗങ്ങൾ തിരഞ്ഞെടുക്കാം'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: appState.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.go('/booking'),
                child: Text(
                  appState.tr('View All →', 'എല്ലാം കാണാം →'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appState.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<WorkerCategory>>(
          stream: _firestoreService.getCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? _firestoreService.keralaDefaultCategories;

            return SizedBox(
              height: 135,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final iconData = _getIconData(cat.icon);
                  final color = Color(cat.colorValue);

                  return Container(
                    width: 118,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedPressCard(
                      scaleDown: 0.94,
                      onTap: () {
                        context.go('/booking?category=${Uri.encodeComponent(cat.name)}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appState.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: appState.borderCol),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: color, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appState.formatCategory(cat.name),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: appState.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyHelpline(BuildContext context, AppStateProvider appState) {
    return StreamBuilder<ContactInfo>(
      stream: _firestoreService.getContactInfoStream(),
      builder: (context, snapshot) {
        final info = snapshot.data ?? ContactInfo();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF065F46)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF047857).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.tr('24x7 Customer Support Helpline', '24x7 കസ്റ്റമർ സപ്പോർട്ട് ഹെൽപ്പ്‌ലൈൻ'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📞 ${info.phone} • ${appState.tr("Call / WhatsApp anytime", "ഏത് സമയത്തും ബന്ധപ്പെടാം")}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF065F46),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${info.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: Text(
                        appState.tr('Call Now', 'വിളിക്കാം'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final wa = info.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
                        final uri = Uri.parse('https://wa.me/$wa');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(AppStateProvider appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appState.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('5,000+', appState.tr('Bookings', 'ബുക്കിംഗ്'), Icons.task_alt_rounded, const Color(0xFF10B981), appState),
          _buildDivider(appState),
          _buildStatItem('1,200+', appState.tr('Workers', 'തൊഴിലാളികൾ'), Icons.badge_rounded, const Color(0xFF0284C7), appState),
          _buildDivider(appState),
          _buildStatItem('14', appState.tr('Districts', 'ജില്ലകൾ'), Icons.map_rounded, const Color(0xFFF59E0B), appState),
        ],
      ),
    );
  }

  Widget _buildDivider(AppStateProvider appState) {
    return Container(
      height: 36,
      width: 1,
      color: appState.borderCol,
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon, Color color, AppStateProvider appState) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: appState.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyUsSection(AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appState.tr('Why WorkConnect Kerala?', 'എന്തുകൊണ്ട് വർക്ക് കണക്ട്?'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: appState.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('Quality service, fair wages, and verified experts', 'ഗുണനിലവാരമുള്ള സേവനവും വിശ്വസ്തതയും'),
            style: TextStyle(
              fontSize: 12,
              color: appState.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildFeatureCard(
            Icons.verified_user_rounded,
            appState.tr('100% Background Verified', '100% പരിശോധിച്ചുറപ്പിച്ചവർ'),
            appState.tr('Identity and records of all workers are thoroughly verified.', 'എല്ലാ തൊഴിലാളികളുടെയും തിരിച്ചറിയൽ രേഖകൾ പരിശോധിച്ച് ഉറപ്പുവരുത്തുന്നു.'),
            const Color(0xFF10B981),
            appState,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            Icons.monetization_on_rounded,
            appState.tr('Transparent & Fair Wages', 'ന്യായമായ കൂലിയും സുതാര്യതയും'),
            appState.tr('No hidden fees. Direct and fair wage estimation.', 'മറഞ്ഞിരിക്കുന്ന ചാർജുകളില്ല, കൃത്യമായ വേതനവും സുതാര്യതയും.'),
            const Color(0xFF0284C7),
            appState,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            Icons.pin_drop_rounded,
            appState.tr('GPS Auto Location', 'ജിപിഎസ് ലൊക്കേഷൻ ഫീച്ചർ'),
            appState.tr('Finds nearby available workers matching your exact spot.', 'നിങ്ങളുടെ കൃത്യമായ ലൊക്കേഷൻ കണ്ടെത്തി അടുത്തുള്ള തൊഴിലാളികളെ നൽകുന്നു.'),
            const Color(0xFFF59E0B),
            appState,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, Color color, AppStateProvider appState) {
    return AnimatedPressCard(
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appState.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appState.borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: appState.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: appState.textSecondary,
                      height: 1.3,
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

  Widget _buildTestimonialsSection(AppStateProvider appState) {
    return StreamBuilder<List<UserReview>>(
      stream: _firestoreService.getReviewsStream(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.tr('Customer Reviews', 'ഉപഭോക്താക്കൾ പറയുന്നത്'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appState.textPrimary,
                          ),
                        ),
                        Text(
                          appState.tr('What our clients say across Kerala', 'യഥാർത്ഥ അനുഭവങ്ങൾ'),
                          style: TextStyle(
                            fontSize: 11,
                            color: appState.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFFB45309),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showAddReviewDialog(context),
                    icon: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    label: Text(
                      appState.tr('+ Rate Us', '+ റേറ്റിംഗ് നൽകാം'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appState.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.borderCol),
                  ),
                  child: Center(
                    child: Text(
                      appState.tr('No reviews yet. Be the first to rate us!', 'റിവ്യൂകൾ ലഭ്യമല്ല. ആദ്യത്തെ റേറ്റിംഗ് നൽകൂ!'),
                      style: TextStyle(color: appState.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 145,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: reviews.length,
                    itemBuilder: (context, idx) {
                      final r = reviews[idx];
                      return Container(
                        width: 270,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: appState.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: appState.borderCol),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
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
                                    r.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: appState.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 2),
                                    Text(
                                      r.rating.toStringAsFixed(1),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: appState.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 12, color: Colors.blueGrey.shade400),
                                const SizedBox(width: 3),
                                Text(
                                  r.district,
                                  style: TextStyle(fontSize: 11, color: appState.textSecondary),
                                ),
                                if (r.serviceCategory != null && r.serviceCategory!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${appState.formatCategory(r.serviceCategory!)}',
                                    style: TextStyle(fontSize: 10.5, color: appState.primaryAccent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                r.comment,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: appState.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppStateProvider appState) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: appState.cardBg,
        border: Border(top: BorderSide(color: appState.borderCol)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    'asset/work connect logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.work_rounded, color: Color(0xFF0F4C81), size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                appState.appName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: appState.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appState.appTagline,
            style: TextStyle(fontSize: 11, color: appState.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => context.go('/booking'),
                child: Text(appState.tr('Bookings', 'ബുക്കിംഗ്'), style: TextStyle(fontSize: 12, color: appState.textSecondary)),
              ),
              Text('•', style: TextStyle(color: appState.textSecondary)),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: Text(appState.tr('Jobs', 'ജോലികൾ'), style: TextStyle(fontSize: 12, color: appState.textSecondary)),
              ),
              Text('•', style: TextStyle(color: appState.textSecondary)),
              TextButton(
                onPressed: () => context.go('/contact'),
                child: Text(appState.tr('Support', 'സഹായം'), style: TextStyle(fontSize: 12, color: appState.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} ${appState.appName}. All rights reserved.',
            style: TextStyle(fontSize: 10.5, color: appState.textMuted),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'electric_bolt':
      case 'electrician':
        return Icons.bolt_rounded;
      case 'plumbing':
      case 'plumber':
        return Icons.water_drop_rounded;
      case 'directions_car':
      case 'driver':
        return Icons.directions_car_filled_rounded;
      case 'foundation':
      case 'mason':
        return Icons.foundation_rounded;
      case 'format_paint':
      case 'painter':
        return Icons.format_paint_rounded;
      case 'carpenter':
        return Icons.carpenter_rounded;
      case 'construction':
      case 'welder':
        return Icons.construction_rounded;
      case 'cleaning_services':
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'pan_tool_alt':
      case 'helper':
        return Icons.pan_tool_alt_rounded;
      case 'ac_unit':
      case 'ac_mechanic':
        return Icons.ac_unit_rounded;
      case 'videocam':
      case 'cctv_technician':
        return Icons.videocam_rounded;
      case 'grid_view':
      case 'tile_layer':
        return Icons.grid_view_rounded;
      case 'park':
      case 'coconut_climber':
        return Icons.park_rounded;
      case 'medical_services':
      case 'home_nurse':
        return Icons.medical_services_rounded;
      case 'yard':
      case 'gardener':
        return Icons.yard_rounded;
      case 'build':
      case 'car_mechanic':
        return Icons.build_rounded;
      case 'restaurant':
      case 'cook':
        return Icons.restaurant_rounded;
      case 'two_wheeler':
      case 'delivery':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }
}

/// Interactive tactile animation card for buttons and tiles
class AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const AnimatedPressCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? widget.scaleDown : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
