// lib/features/auth/screens/biometric_prompt_screen.dart
import 'package:flosy/core/services/biometric_service_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class BiometricPromptScreen extends StatefulWidget {
  const BiometricPromptScreen({super.key});

  @override
  State<BiometricPromptScreen> createState() => _BiometricPromptScreenState();
}

class _BiometricPromptScreenState extends State<BiometricPromptScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-trigger Face ID authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithFaceId();
    });
  }

  Future<void> _authenticateWithFaceId() async {
    setState(() => _isAuthenticating = true);

    final authenticated = await BiometricService.authenticateWithFallback(
      reason: 'Authenticate to access your account',
    );

    if (mounted) {
      Navigator.of(context).pop(authenticated);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.blackColor : AppColors.whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Face ID Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenColor.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.greenColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.faceSmile,
                        size: 50.sp,
                        color: AppColors.greenColor,
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 40.h),

            // Title
            Text(
              'Face ID Authentication',
              style: AppText.body16(context).copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: 16.h),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Please authenticate using Face ID to access your account',
                textAlign: TextAlign.center,
                style: AppText.body14(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),

            SizedBox(height: 60.h),

            // Manual trigger button (in case auto-trigger fails)
            if (!_isAuthenticating)
              ElevatedButton(
                onPressed: _authenticateWithFaceId,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Authenticate',
                  style: AppText.body16(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),

            SizedBox(height: 20.h),

            // Skip button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Use Password Instead',
                style: AppText.body14(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
