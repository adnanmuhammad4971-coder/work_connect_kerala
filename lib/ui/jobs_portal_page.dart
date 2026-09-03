import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state_provider.dart';
import '../services/firestore_service.dart';
import 'widgets/app_drawer.dart';

class JobsPortalPage extends StatelessWidget {
  const JobsPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: appState.scaffoldBg,
        drawer: const AppDrawer(),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: appState.isDarkMode ? const Color(0xFF070B14) : const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.go('/'),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appState.tr('Jobs Portal', 'തൊഴിൽ പോർട്ടൽ'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                appState.tr('Direct Kerala Vacancies', 'തൊഴിൽ അവസരങ്ങൾ & പോസ്റ്റിംഗ്'),
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
          bottom: TabBar(
            indicatorColor: const Color(0xFF38BDF8),
            indicatorWeight: 3,
            labelColor: const Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            tabs: [
              Tab(icon: const Icon(Icons.search_rounded, size: 16), text: appState.tr('Vacancies', 'ഒഴിവുകൾ')),
              Tab(icon: const Icon(Icons.person_add_rounded, size: 16), text: appState.tr('Job Seeker', 'തൊഴിലന്വേഷകൻ')),
              Tab(icon: const Icon(Icons.post_add_rounded, size: 16), text: appState.tr('Post Job', 'ജോലി നൽകാം')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BrowseJobsTab(),
            JobSeekerForm(),
            EmployerForm(),
          ],
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
                  _buildNavItem(context, Icons.home_outlined, appState.tr('Home', 'ഹോം'), false, () => context.go('/'), appState),
                  _buildNavItem(context, Icons.engineering_outlined, appState.tr('Book Worker', 'ബുക്കിംഗ്'), false, () => context.go('/booking'), appState),
                  _buildNavItem(context, Icons.work_rounded, appState.tr('Jobs Portal', 'ജോലികൾ'), true, () {}, appState),
                  _buildNavItem(context, Icons.headset_mic_outlined, appState.tr('Contact Us', 'സഹായം'), false, () => context.go('/contact'), appState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap, AppStateProvider appState) {
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
}

// ==========================================
// 1. BROWSE JOBS TAB (WITH FILTERS)
// ==========================================
class BrowseJobsTab extends StatefulWidget {
  const BrowseJobsTab({super.key});

  @override
  State<BrowseJobsTab> createState() => _BrowseJobsTabState();
}

class _BrowseJobsTabState extends State<BrowseJobsTab> {
  late final Stream<List<Job>> _jobsStream;
  late final Stream<List<WorkerCategory>> _categoriesStream;
  late final Stream<List<String>> _districtsStream;
  StreamSubscription? _catSub;
  StreamSubscription? _distSub;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDistrict = 'All';

  List<String> _districts = ['All'];
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _jobsStream = FirestoreService().getJobs();
    _categoriesStream = FirestoreService().getCategories();
    _districtsStream = FirestoreService().getDistrictsStream();

    // Dynamically fetch and sync categories from Firebase
    _catSub = _categoriesStream.listen((categories) {
      if (mounted) {
        final catList = ['All', ...categories.map((c) => c.name).toSet()];
        setState(() {
          _categories = catList;
        });
      }
    });

    // Dynamically fetch and sync districts from Firebase
    _distSub = _districtsStream.listen((districts) {
      if (mounted) {
        final distList = ['All', ...districts.toSet()];
        setState(() {
          _districts = distList;
        });
      }
    });
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _distSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return StreamBuilder<List<Job>>(
      stream: _jobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
        }
        var jobs = (snapshot.data ?? []).where((j) => j.status == 'Approved' || j.status == 'Open').toList();

        // Apply search query filter
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          jobs = jobs.where((j) {
            return j.title.toLowerCase().contains(q) ||
                j.employerId.toLowerCase().contains(q) ||
                j.location.toLowerCase().contains(q) ||
                j.description.toLowerCase().contains(q);
          }).toList();
        }

        // Apply category filter
        if (_selectedCategory != 'All') {
          final targetClean = _selectedCategory.split('(').first.trim().toLowerCase();
          jobs = jobs.where((j) {
            final cat = j.category.toLowerCase();
            final title = j.title.toLowerCase();
            final selected = _selectedCategory.toLowerCase();
            return cat.contains(selected) ||
                cat.contains(targetClean) ||
                title.contains(targetClean);
          }).toList();
        }

        // Apply district filter
        if (_selectedDistrict != 'All') {
          jobs = jobs.where((j) {
            return j.location.toLowerCase().contains(_selectedDistrict.toLowerCase());
          }).toList();
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appState.bannerBgStart,
                          appState.bannerBgEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.work_outline_rounded, size: 28, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('Kerala Direct Job Vacancies', 'കേരള തൊഴിൽ അവസരങ്ങൾ'),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                appState.tr('Direct openings from verified employers across 14 districts.', 'കമ്പനികളിൽ നിന്നും കോൺട്രാക്ടർമാരിൽ നിന്നും നേരിട്ടുള്ള തൊഴിലുകൾ.'),
                                style: TextStyle(fontSize: 12.5, color: Colors.blueGrey.shade300),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: appState.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: appState.borderCol),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: appState.tr('Search job title, company, or place...', 'തൊഴിൽ, സ്ഥലം, കമ്പനി തിരയുക...'),
                        hintStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: appState.primaryAccent),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final label = cat == 'All' ? appState.tr('All Categories', 'എല്ലാ വിഭാഗവും') : appState.formatCategory(cat);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = cat);
                            },
                            selectedColor: const Color(0xFF0284C7),
                            backgroundColor: appState.inputBg,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : appState.textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : appState.borderCol,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // District Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _districts.map((dist) {
                        final isSelected = _selectedDistrict == dist;
                        final label = dist == 'All' ? appState.tr('All Districts', 'എല്ലാ ജില്ലയും') : dist;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedDistrict = selected ? dist : 'All');
                            },
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF10B981),
                            backgroundColor: appState.inputBg,
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF10B981) : appState.textSecondary,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF10B981) : appState.borderCol,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Results Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${jobs.length} ${appState.tr('Vacancies Available', 'തൊഴിൽ ഒഴിവുകൾ')}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: appState.textSecondary),
                      ),
                      if (_selectedCategory != 'All' || _selectedDistrict != 'All' || _searchQuery.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedDistrict = 'All';
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: Text(appState.tr('Reset Filters', 'ഫിൽട്ടർ ഒഴിവാക്കുക'), style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (jobs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: appState.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: appState.borderCol),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.work_off_outlined, size: 48, color: appState.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            appState.tr('No Matching Vacancies Found', 'അനുയോജ്യമായ ഒഴിവുകൾ കണ്ടെത്താനായില്ല'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appState.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            appState.tr('Submit your profile in the "Job Seeker" tab and employers will contact you!', 'നിങ്ങളുടെ വിവരങ്ങൾ "തൊഴിലന്വേഷകൻ" ടാബിൽ ചേർക്കൂ, കമ്പനികൾ ബന്ധപ്പെടും!'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: appState.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ...jobs.map((job) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: appState.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: appState.borderCol),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: appState.isDarkMode ? 0.2 : 0.02),
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
                                  job.title,
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: appState.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  '${job.vacancies} ${appState.tr('Vacancies', 'ഒഴിവുകൾ')}',
                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.apartment_rounded, size: 15, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${appState.tr('Company', 'കമ്പനി')}: ${job.employerId}',
                                  style: TextStyle(color: appState.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Text(
                                '${appState.tr('Location', 'സ്ഥലം')}: ${job.location}',
                                style: TextStyle(fontSize: 13, color: appState.textSecondary),
                              ),
                            ],
                          ),
                          if (job.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: appState.inputBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: appState.borderCol),
                              ),
                              child: Text(
                                job.description,
                                style: TextStyle(color: appState.textPrimary, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 2. JOB SEEKER FORM
// ==========================================
class JobSeekerForm extends StatefulWidget {
  const JobSeekerForm({super.key});

  @override
  State<JobSeekerForm> createState() => _JobSeekerFormState();
}

class _JobSeekerFormState extends State<JobSeekerForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _skills = '';
  bool _isSubmitting = false;

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final applicationId = DateTime.now().millisecondsSinceEpoch.toString();
      final newApp = JobApplication(
        id: applicationId,
        jobId: 'general_application',
        applicantName: _name.trim(),
        phone: _phone.trim(),
        skills: _skills.trim(),
        status: 'Pending',
      );

      await FirestoreService().createJobApplication(newApp);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Application Submitted!')),
              ],
            ),
            content: const Text(
              'Your profile has been saved. When matching job opportunities arrive, our team will call you directly!',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _formKey.currentState!.reset();
                },
                child: const Text('Great'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 20.0, vertical: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            elevation: 0,
            color: appState.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: appState.borderCol),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('Register as a Job Seeker', 'തൊഴിലന്വേഷകനായി രജിസ്റ്റർ ചെയ്യാം'),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appState.textPrimary),
                              ),
                              Text(
                                appState.tr('Get connected directly with Kerala employers', 'കേരളത്തിലെ തൊഴിൽദാതാക്കളുമായി ബന്ധപ്പെടാം'),
                                style: TextStyle(fontSize: 12, color: appState.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32, color: appState.borderCol),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Your Full Name', 'നിങ്ങളുടെ പേര്'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      onSaved: (v) => _name = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Phone / WhatsApp Number', 'ഫോൺ / വാട്സ്ആപ്പ് നമ്പർ'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                      onSaved: (v) => _phone = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Skills / Trade (e.g. Electrician, Driver, Mason, Plumber)', 'തൊഴിൽ പ്രാവീണ്യം (ഇലക്ട്രീഷ്യൻ, ഡ്രൈവർ...)'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.handyman_outlined, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your skills' : null,
                      onSaved: (v) => _skills = v ?? '',
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : _submitApplication,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(appState.tr('Submit Application', 'അപേക്ഷ സമർപ്പിക്കാം'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. EMPLOYER JOB POSTING FORM
// ==========================================
class EmployerForm extends StatefulWidget {
  const EmployerForm({super.key});

  @override
  State<EmployerForm> createState() => _EmployerFormState();
}

class _EmployerFormState extends State<EmployerForm> {
  final _formKey = GlobalKey<FormState>();
  String _companyName = '';
  String _contactPerson = '';
  String _phone = '';
  String _jobTitle = '';
  String _location = '';
  String _vacancies = '1';
  String _description = '';
  bool _isSubmitting = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final jobId = DateTime.now().millisecondsSinceEpoch.toString();
      final newJob = Job(
        id: jobId,
        employerId: '$_companyName ($_contactPerson - $_phone)',
        title: _jobTitle.trim(),
        description: _description.trim(),
        category: 'General',
        location: _location.trim(),
        vacancies: int.tryParse(_vacancies.trim()) ?? 1,
        status: 'Open',
      );

      await FirestoreService().createJob(newJob);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Job Vacancy Posted!')),
              ],
            ),
            content: const Text(
              'Your listing is submitted! Our admin team will verify and publish it on the vacancy portal.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _formKey.currentState!.reset();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 20.0, vertical: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            elevation: 0,
            color: appState.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: appState.borderCol),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('Post a Job Vacancy', 'തൊഴിൽ ഒഴിവ് പോസ്റ്റ് ചെയ്യാം'),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appState.textPrimary),
                              ),
                              Text(
                                appState.tr('Publish openings to reach candidates in Kerala', 'കേരളത്തിലെ മികച്ച തൊഴിലാളികളെ കണ്ടെത്താം'),
                                style: TextStyle(fontSize: 12, color: appState.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32, color: appState.borderCol),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Company / Business Name', 'കമ്പനി / സ്ഥാപനത്തിന്റെ പേര്'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter company name' : null,
                      onSaved: (v) => _companyName = v ?? '',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Contact Person Name', 'കോൺടാക്റ്റ് വ്യക്തിയുടെ പേര്'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter contact person' : null,
                      onSaved: (v) => _contactPerson = v ?? '',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Contact Phone / WhatsApp', 'ഫോൺ / വാട്സ്ആപ്പ്'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
                      onSaved: (v) => _phone = v ?? '',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            style: TextStyle(color: appState.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: appState.tr('Job Role / Title', 'തൊഴിൽ തസ്തിക'),
                              labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                              prefixIcon: const Icon(Icons.work_outline_rounded, color: Color(0xFF38BDF8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                              filled: true,
                              fillColor: appState.inputBg,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter job title' : null,
                            onSaved: (v) => _jobTitle = v ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            style: TextStyle(color: appState.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: appState.tr('Vacancies', 'ഒഴിവുകൾ'),
                              labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                              prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFF38BDF8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                              filled: true,
                              fillColor: appState.inputBg,
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: '1',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            onSaved: (v) => _vacancies = v ?? '1',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Location / District in Kerala', 'സ്ഥലം / ജില്ല'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter location' : null,
                      onSaved: (v) => _location = v ?? '',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      style: TextStyle(color: appState.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: appState.tr('Job Requirements / Description', 'വിശദാംശങ്ങൾ / യോഗ്യത'),
                        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF38BDF8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: appState.borderCol)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                        filled: true,
                        fillColor: appState.inputBg,
                      ),
                      maxLines: 2,
                      onSaved: (v) => _description = v ?? '',
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : _submitJob,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(appState.tr('Publish Vacancy', 'ഒഴിവ് പ്രസിദ്ധീകരിക്കാം'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
