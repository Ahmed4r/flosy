import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/services/biometric_service_helper.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/features/auth/screens/login_screen.dart';
import 'package:flosy/features/navigation/main_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _contentController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _glowRadius;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _glowRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOutCubic),
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contentController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _glowController.forward();

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _navigateNext();
  }

  Future<void> _navigateNext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final loggedIn = token != null && token.isNotEmpty;

      if (!mounted) return;

      if (loggedIn) {
        try {
          final faceIdEnabled = await BiometricService.isFaceIdEnabled();
          final biometricAvailable = await BiometricService.canUseBiometrics();

          if (faceIdEnabled && biometricAvailable) {
            final authenticated = await BiometricService.authenticateWithFaceId(
              reason: 'Authenticate to access your account',
            );

            if (authenticated) {
              _navigateToHome();
            } else {
              _navigateToLogin();
            }
          } else {
            _navigateToHome();
          }
        } catch (e) {
          // If biometric check fails, just navigate to home
          _navigateToHome();
        }
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      // Fallback to login on any error
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ────────────────── BUILD ──────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppTheme.isDarkMode(context);
    final Color bg = isDark ? AppColors.blackColor : AppColors.whiteColor;
    final Color textPrimary = isDark ? Colors.white : AppColors.blackColor;
    final Color textSecondary = isDark ? Colors.white54 : Colors.grey.shade500;

    return Scaffold(
      body: Container(
        color: bg,
        child: Stack(
          children: [
            // ── Soft radial glow behind logo ──
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: _glowRadius.value * 0.6,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.colorButton.withOpacity(
                                isDark ? 0.15 : 0.1,
                              ),
                              blurRadius: 80,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Floating particles ──
            ...List.generate(5, (i) => _buildParticle(i, isDark)),

            // ── Main content ──
            Center(
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 28),

                      // App name
                      SlideTransition(
                        position: _titleSlide,
                        child: Opacity(
                          opacity: _titleFade.value,
                          child: Text(
                            'flosy'.tr(),
                            style: TextStyle(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Text(
                          'money_moves_no_cap'.tr(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Bottom loading dots ──
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return Opacity(opacity: _dotsFade.value, child: child);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPulseDots(isDark),
                    const SizedBox(height: 14),
                    Text(
                      'loading_your_bag'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: textSecondary.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── PARTICLES ──────────────────

  Widget _buildParticle(int index, bool isDark) {
    final offsets = [
      const Alignment(-0.8, -0.7),
      const Alignment(0.85, -0.4),
      const Alignment(-0.6, 0.55),
      const Alignment(0.7, 0.6),
      const Alignment(0.2, -0.85),
    ];
    final sizes = [5.0, 6.0, 4.0, 5.0, 3.5];
    final speeds = [1.0, 0.7, 1.3, 0.9, 1.1];

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final t = _particleController.value * speeds[index] * math.pi * 2;
        final dx = math.sin(t + index * 1.2) * 0.02;
        final dy = math.cos(t + index * 0.9) * 0.03;
        final opacity = 0.2 + 0.2 * math.sin(t + index * 0.7);

        return Align(
          alignment: Alignment(offsets[index].x + dx, offsets[index].y + dy),
          child: Container(
            width: sizes[index],
            height: sizes[index],
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.colorButton.withOpacity(
                isDark ? opacity * 0.6 : opacity,
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────── PULSE DOTS LOADING ──────────────────

  Widget _buildPulseDots(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = _pulseController.value * math.pi * 2 - i * 0.9;
            final scale = 0.5 + 0.5 * math.sin(phase).clamp(0.0, 1.0);
            final opacity = 0.25 + 0.75 * math.sin(phase).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.colorButton.withOpacity(opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
