import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state_provider.dart';
import '../services/firestore_service.dart';
import 'widgets/app_drawer.dart';

class WorkerBookingPage extends StatefulWidget {
  final String? initialCategory;
  const WorkerBookingPage({super.key, this.initialCategory});

  @override
  State<WorkerBookingPage> createState() => _WorkerBookingPageState();
}

class _WorkerBookingPageState extends State<WorkerBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedCategory = 'Electrician (ഇലക്ട്രീഷ്യൻ)';
  String _selectedDistrict = 'Kozhikode';
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _numberOfWorkers = 1;
  bool _isSubmitting = false;
  bool _isLocating = false;
  String? _gpsCoordinates;
  String? _mapsUrl;

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

  final List<Map<String, dynamic>> _fallbackCategories = [
    {'name': 'Electrician (ഇലക്ട്രീഷ്യൻ)', 'icon': Icons.bolt_rounded, 'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)]},
    {'name': 'Plumber (പ്ലംബർ)', 'icon': Icons.water_drop_rounded, 'gradient': [Color(0xFF0284C7), Color(0xFF0369A1)]},
    {'name': 'Driver (ഡ്രൈവർ)', 'icon': Icons.directions_car_filled_rounded, 'gradient': [Color(0xFF06B6D4), Color(0xFF0891B2)]},
    {'name': 'Mason (മേസൻ / തേപ്പ്)', 'icon': Icons.foundation_rounded, 'gradient': [Color(0xFFEA580C), Color(0xFFC2410C)]},
    {'name': 'Painter (പെയിന്റർ)', 'icon': Icons.format_paint_rounded, 'gradient': [Color(0xFFEC4899), Color(0xFFBE185D)]},
    {'name': 'Carpenter (ആശാരി / കാർപെന്റർ)', 'icon': Icons.carpenter_rounded, 'gradient': [Color(0xFF8B5CF6), Color(0xFF6D28D9)]},
    {'name': 'Welder (വെൽഡർ)', 'icon': Icons.construction_rounded, 'gradient': [Color(0xFF64748B), Color(0xFF475569)]},
    {'name': 'Cleaning & Housemaid', 'icon': Icons.cleaning_services_rounded, 'gradient': [Color(0xFF10B981), Color(0xFF059669)]},
    {'name': 'Helper (ഹെൽപ്പർ / ചുമട്ടുതൊഴിലാളി)', 'icon': Icons.pan_tool_alt_rounded, 'gradient': [Color(0xFFF97316), Color(0xFFEA580C)]},
    {'name': 'AC & Fridge Mechanic', 'icon': Icons.ac_unit_rounded, 'gradient': [Color(0xFF3B82F6), Color(0xFF1D4ED8)]},
    {'name': 'CCTV Technician', 'icon': Icons.videocam_rounded, 'gradient': [Color(0xFF6366F1), Color(0xFF4338CA)]},
    {'name': 'Tiles & Granite', 'icon': Icons.grid_view_rounded, 'gradient': [Color(0xFF0D9488), Color(0xFF0F766E)]},
    {'name': 'Coconut Climber (മരംവെട്ട്)', 'icon': Icons.park_rounded, 'gradient': [Color(0xFF16A34A), Color(0xFF15803D)]},
    {'name': 'Home Nurse & Caretaker', 'icon': Icons.medical_services_rounded, 'gradient': [Color(0xFFE11D48), Color(0xFFBE123C)]},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      final query = widget.initialCategory!.trim().toLowerCase();
      final matched = _fallbackCategories.firstWhere(
        (c) {
          final name = (c['name'] as String).toLowerCase();
          return name.contains(query) || query.contains(name.split('(').first.trim().toLowerCase());
        },
        orElse: () => {'name': widget.initialCategory!},
      );
      _selectedCategory = matched['name'] as String;
    }
    FirestoreService().seedDefaultCategoriesIfEmpty();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentGpsLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location on your phone.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied. Please enable in Settings.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      String detectedAddress = '';
      try {
        final geocoding = Geocoding();
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? '';
          final subLocality = place.subLocality ?? '';
          final locality = place.locality ?? '';
          final subAdmin = place.subAdministrativeArea ?? '';
          final district = place.administrativeArea ?? '';

          detectedAddress = [street, subLocality, locality, subAdmin, district]
              .where((s) => s.isNotEmpty)
              .toSet()
              .join(', ');

          // Auto select matching district if found
          for (var d in _keralaDistricts) {
            if (district.toLowerCase().contains(d.toLowerCase()) ||
                subAdmin.toLowerCase().contains(d.toLowerCase()) ||
                locality.toLowerCase().contains(d.toLowerCase())) {
              _selectedDistrict = d;
              break;
            }
          }
        }
      } catch (_) {
        detectedAddress = 'Live Location ($lat, $lng)';
      }

      setState(() {
        _gpsCoordinates = '$lat, $lng';
        _mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        _locationController.text = detectedAddress.isNotEmpty ? detectedAddress : 'GPS Pin: $lat, $lng';
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF0F172A),
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📍 Live GPS Detected: ${_locationController.text}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch GPS: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Preferred Date and Time')),
      );
      return;
    }

    final gpsFinal = _gpsCoordinates ?? '';
    final mapsFinal = _mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$_selectedDistrict, ${_locationController.text.trim()}")}';
    final fullLocation = '$_selectedDistrict - ${_locationController.text.trim()}';

    setState(() => _isSubmitting = true);

    try {
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      final newBooking = Booking(
        id: bookingId,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        requiredWorkerCategory: _selectedCategory,
        date: _selectedDate!,
        time: _selectedTime!.format(context),
        location: fullLocation,
        gpsCoordinates: gpsFinal,
        mapsUrl: mapsFinal,
        numberOfWorkers: _numberOfWorkers,
        status: 'New',
      );

      await FirestoreService().createBooking(newBooking);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Booking Received!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you, ${_nameController.text.trim()}! We have received your request for $_selectedCategory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fullLocation,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                        if (gpsFinal.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'GPS: $gpsFinal (Maps Active)',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • ${_selectedTime!.format(context)}',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _nameController.clear();
                        _phoneController.clear();
                        _locationController.clear();
                        setState(() {
                          _selectedDate = DateTime.now();
                          _selectedTime = const TimeOfDay(hour: 9, minute: 0);
                          _gpsCoordinates = null;
                          _mapsUrl = null;
                        });
                      },
                      child: const Text('Done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
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
              appState.tr('Book a Worker', 'തൊഴിലാളിയെ ബുക്ക് ചെയ്യുക'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              appState.tr('Instant Service Across Kerala', 'കേരള തൊഴിൽ സേവനം'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= LUXURY HERO BANNER =================
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 36, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appState.bannerBgStart,
                    appState.bannerBgEnd,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          appState.tr('100% Background Verified Workers', '100% പരിശോധിച്ചുറപ്പിച്ച തൊഴിലാളികൾ'),
                          style: const TextStyle(color: Color(0xFFBAE6FD), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appState.tr('Find Skilled Workers in 2 Minutes', 'വിദഗ്ദ്ധ തൊഴിലാളികളെ വേഗത്തിൽ കണ്ടെത്താം'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appState.tr(
                      'Book Electricians, Plumbers, Drivers, Masons, and Painters across Kerala.',
                      'ഇലക്ട്രീഷ്യൻ, പ്ലംബർ, ഡ്രൈവർ, പെയിന്റർ, ആശാരി തുടങ്ങി ഏത് സേവനത്തിനും ഉടൻ ബുക്ക് ചെയ്യാം.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade200, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHeroBadge(Icons.star_rounded, appState.tr('4.9/5 Rated', '4.9/5 റേറ്റിംഗ്'), const Color(0xFFF59E0B)),
                      _buildHeroBadge(Icons.timer_outlined, appState.tr('15-Min Quick Dispatch', '15 മിനിറ്റിൽ പ്രതികരണം'), const Color(0xFF38BDF8)),
                    ],
                  ),
                ],
              ),
            ),

            // ================= MAIN FORM CONTAINER =================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 20.0, vertical: 20.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    elevation: 0,
                    color: appState.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: appState.borderCol, width: 1),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.category_rounded, color: Color(0xFF2563EB), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.tr('Choose Required Trade Service', 'തൊഴിൽ വിഭാഗം തിരഞ്ഞെടുക്കുക'),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appState.textPrimary),
                                      ),
                                      Text(
                                        appState.tr('Select the type of worker you need', 'നിങ്ങൾക്ക് ആവശ്യമുള്ള തൊഴിലാളിയെ തിരഞ്ഞെടുക്കുക'),
                                        style: TextStyle(fontSize: 11.5, color: appState.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // DYNAMIC FIRESTORE CATEGORIES
                            StreamBuilder<List<WorkerCategory>>(
                              stream: FirestoreService().getCategories(),
                              builder: (context, snapshot) {
                                final dbCategories = snapshot.data ?? [];
                                final categoryList = dbCategories.isNotEmpty
                                    ? dbCategories.map((c) => {
                                          'name': c.name,
                                          'gradient': [Color(c.colorValue), Color(c.colorValue).withValues(alpha: 0.8)],
                                          'icon': Icons.handyman_rounded,
                                        }).toList()
                                    : _fallbackCategories;

                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: categoryList.map((cat) {
                                    final catName = cat['name'] as String;
                                    final isSelected = _selectedCategory == catName;
                                    final gradient = cat['gradient'] as List<Color>;
                                    final icon = cat['icon'] as IconData;

                                    return InkWell(
                                      onTap: () => setState(() => _selectedCategory = catName),
                                      borderRadius: BorderRadius.circular(10),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(colors: gradient)
                                              : null,
                                          color: isSelected ? null : appState.inputBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? Colors.transparent : appState.borderCol,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: gradient.first.withValues(alpha: 0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: gradient),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(icon, size: 13, color: Colors.white),
                                            ),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: screenWidth > 400 ? 250 : 200),
                                              child: Text(
                                                appState.formatCategory(catName),
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : appState.textPrimary,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 11.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            Divider(height: 32, color: appState.borderCol),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF2563EB), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.tr('Location & Contact Details', 'സ്ഥലവും ഫോൺ നമ്പറും'),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appState.textPrimary),
                                      ),
                                      Text(
                                        appState.tr('Enter your address for direct worker arrival', 'തൊഴിലാളി എത്തുന്നതിനുള്ള വിലാസം നൽകുക'),
                                        style: TextStyle(fontSize: 11.5, color: appState.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (isMobile) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: appState.tr('Your Full Name', 'നിങ്ങളുടെ പൂർണ്ണ പേര്'),
                                icon: Icons.person_outline_rounded,
                                appState: appState,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _phoneController,
                                label: appState.tr('Phone / WhatsApp Number', 'ഫോൺ / വാട്സ്ആപ്പ് നമ്പർ'),
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                appState: appState,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _nameController,
                                      label: appState.tr('Your Full Name', 'നിങ്ങളുടെ പൂർണ്ണ പേര്'),
                                      icon: Icons.person_outline_rounded,
                                      appState: appState,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _phoneController,
                                      label: appState.tr('Phone / WhatsApp Number', 'ഫോൺ / വാട്സ്ആപ്പ് നമ്പർ'),
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      appState: appState,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),

                            // KERALA DISTRICT SELECTOR
                            DropdownButtonFormField<String>(
                              value: _selectedDistrict,
                              isExpanded: true,
                              dropdownColor: appState.cardBg,
                              style: TextStyle(color: appState.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: appState.tr('Select Kerala District', 'ജില്ല തിരഞ്ഞെടുക്കുക'),
                                labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                                prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF2563EB), size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
                                filled: true,
                                fillColor: appState.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _keralaDistricts.map((district) {
                                return DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(
                                    district,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: appState.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedDistrict = val);
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            // REAL GPS LIVE LOCATION BUTTON & CARD
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _gpsCoordinates != null
                                    ? (appState.isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                                    : appState.inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _gpsCoordinates != null ? const Color(0xFF10B981) : appState.borderCol,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _gpsCoordinates != null
                                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                          : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _gpsCoordinates != null ? Icons.gps_fixed_rounded : Icons.my_location_rounded,
                                      color: _gpsCoordinates != null ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _gpsCoordinates != null
                                              ? appState.tr('📍 Live GPS Attached', '📍 GPS ലൊക്കേഷൻ ചേർത്തു')
                                              : appState.tr('Use Live GPS Location', 'ലൈവ് GPS ലൊക്കേഷൻ എടുക്കാം'),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: _gpsCoordinates != null
                                                ? (appState.isDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF166534))
                                                : appState.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _gpsCoordinates != null
                                              ? 'Real GPS: $_gpsCoordinates'
                                              : appState.tr('Tap to fetch where you are standing', 'നിങ്ങൾ നിൽക്കുന്ന സ്ഥലം കണ്ടെത്താൻ ടാപ്പ് ചെയ്യുക'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _gpsCoordinates != null
                                                ? (appState.isDarkMode ? const Color(0xFFA7F3D0) : const Color(0xFF15803D))
                                                : appState.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _gpsCoordinates != null ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _isLocating ? null : _getCurrentGpsLocation,
                                    child: _isLocating
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(
                                            _gpsCoordinates != null
                                                ? appState.tr('GPS Active ✓', 'GPS റെഡി ✓')
                                                : appState.tr('Get GPS', 'GPS എടുക്കൂ'),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _locationController,
                              label: appState.tr('Town / Landmark / House Name', 'സ്ഥലം / ലാൻഡ്മാർക്ക് / വീട്ടുപേര്'),
                              icon: Icons.home_work_outlined,
                              hintText: 'e.g. Near Beach Road, Mavoor',
                              appState: appState,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your town/landmark' : null,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      side: BorderSide(color: appState.borderCol),
                                      backgroundColor: appState.inputBg,
                                    ),
                                    onPressed: _pickDate,
                                    icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 17),
                                    label: Text(
                                      _selectedDate == null
                                          ? appState.tr('Select Date', 'തിയതി തിരഞ്ഞെടുക്കുക')
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: appState.textPrimary, fontSize: 12.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      side: BorderSide(color: appState.borderCol),
                                      backgroundColor: appState.inputBg,
                                    ),
                                    onPressed: _pickTime,
                                    icon: const Icon(Icons.schedule_rounded, color: Color(0xFF38BDF8), size: 17),
                                    label: Text(
                                      _selectedTime == null
                                          ? appState.tr('Select Time', 'സമയം തിരഞ്ഞെടുക്കുക')
                                          : _selectedTime!.format(context),
                                      style: TextStyle(fontWeight: FontWeight.w600, color: appState.textPrimary, fontSize: 12.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              style: TextStyle(color: appState.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: appState.tr('Number of Workers Required', 'ആവശ്യമായ തൊഴിലാളികളുടെ എണ്ണം'),
                                labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
                                prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFF38BDF8), size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
                                filled: true,
                                fillColor: appState.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: '1',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter worker count' : null,
                              onChanged: (v) => _numberOfWorkers = int.tryParse(v) ?? 1,
                            ),

                            const SizedBox(height: 24),

                            // SUBMIT BUTTON WITH GRADIENT & SHADOW
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isSubmitting ? null : _submitBooking,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF38BDF8)),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '${appState.tr('Book', 'ബുക്ക് ചെയ്യുക')} ${appState.formatCategory(_selectedCategory)} ${appState.tr('Now', 'ഇപ്പോൾ')}',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appState.navBg,
          border: Border(top: BorderSide(color: appState.borderCol)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, appState.tr('Home', 'ഹോം'), false, () => context.go('/'), appState),
                _buildNavItem(Icons.engineering_rounded, appState.tr('Book', 'ബുക്കിംഗ്'), true, () {}, appState),
                _buildNavItem(Icons.work_outline_rounded, appState.tr('Jobs', 'തൊഴിൽ'), false, () => context.go('/jobs'), appState),
                _buildNavItem(Icons.headset_mic_outlined, appState.tr('Contact', 'ഹെൽപ്പ്'), false, () => context.go('/contact'), appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap, AppStateProvider appState) {
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
              color: isSelected ? const Color(0xFF38BDF8) : appState.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF38BDF8) : appState.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppStateProvider appState,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: appState.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: appState.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: appState.textSecondary.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: appState.borderCol)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
        filled: true,
        fillColor: appState.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildHeroBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
