import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'ui/admin_dashboard_page.dart';
import 'ui/admin_login_page.dart';
import 'ui/contact_us_page.dart';
import 'ui/home_page.dart';
import 'ui/jobs_portal_page.dart';
import 'ui/splash_screen.dart';
import 'ui/worker_booking_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const WorkConnectKeralaApp(),
    ),
  );
}

Page<dynamic> _buildPageWithTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: '/home',
      redirect: (context, state) => '/',
    ),
    GoRoute(
      path: '/booking',
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'];
        return _buildPageWithTransition(
          state: state,
          child: WorkerBookingPage(initialCategory: category),
        );
      },
    ),
    GoRoute(
      path: '/jobs',
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const JobsPortalPage(),
      ),
    ),
    GoRoute(
      path: '/contact',
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const ContactUsPage(),
      ),
    ),
    GoRoute(
      path: '/admin/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const AdminLoginPage(),
      ),
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) {
        final user = AuthService().currentUser;
        if (user == null) {
          return '/admin/login';
        }
        return null;
      },
      pageBuilder: (context, state) => _buildPageWithTransition(
        state: state,
        child: const AdminDashboardPage(),
      ),
    ),
  ],
);

class WorkConnectKeralaApp extends StatefulWidget {
  const WorkConnectKeralaApp({super.key});

  @override
  State<WorkConnectKeralaApp> createState() => _WorkConnectKeralaAppState();
}

class _WorkConnectKeralaAppState extends State<WorkConnectKeralaApp> {
  StreamSubscription? _brandingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      _brandingSub = FirestoreService().getContactInfoStream().listen((info) {
        appState.updateBranding(info.appName, info.appTagline);
      });
    });
  }

  @override
  void dispose() {
    _brandingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp.router(
      title: appState.appName,
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        fontFamily: 'Poppins',
        fontFamilyFallback: const ['Noto Sans Malayalam', 'sans-serif'],
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF0F4C81),
          primary: const Color(0xFF0F4C81),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Poppins',
        fontFamilyFallback: const ['Noto Sans Malayalam', 'sans-serif'],
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF38BDF8),
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF070B14),
          foregroundColor: Colors.white,
        ),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
      routerConfig: _router,
    );
  }
}
