import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Pulse / Breathing aura animation for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Smooth progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _mainController.forward();
    _progressController.forward();

    // Navigate to home after 3.2 seconds
    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      context.go('/');
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: Stack(
        children: [
          // Background Ambient Glow Orbs
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: _buildGlowOrb(
              diameter: size.width * 0.9,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.2,
            child: _buildGlowOrb(
              diameter: size.width * 0.9,
              color: const Color(0xFF0F4C81).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.25,
            child: _buildGlowOrb(
              diameter: size.width * 0.5,
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
            ),
          ),

          // Main Content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Animated Glowing Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: _buildPremiumLogoCard(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Animated Branding Text & Tagline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Main Title
                          Text(
                            'WORK CONNECT',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Kerala Golden Subtitle
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFE08A),
                                Color(0xFFD4AF37),
                                Color(0xFFF59E0B),
                                Color(0xFFFFE08A),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'K E R A L A',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 9.0,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Luxury Tagline Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Trusted Workers • Quality Service',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Modern Progress Bar & Status
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          // Sleek Glowing Progress Bar
                          Container(
                            height: 4,
                            width: 170,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressController.value.clamp(0.05, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0F4C81),
                                          Color(0xFFD4AF37),
                                          Color(0xFFFFE08A),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting Kerala with trusted experts',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.4,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLogoCard() {
    return Container(
      width: 125,
      height: 125,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE08A),
            Color(0xFFD4AF37),
            Color(0xFF996515),
            Color(0xFFD4AF37),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF070E1A),
        ),
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            'asset/work connect logo.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.handyman_rounded,
                  size: 55,
                  color: Color(0xFFD4AF37),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlowOrb({required double diameter, required Color color}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
