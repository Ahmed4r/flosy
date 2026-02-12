import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/services/biometric_service_helper.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flosy/features/auth/screens/forget_screen.dart';
import 'package:flosy/features/auth/screens/register_screen.dart';
import 'package:flosy/features/navigation/main_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final LocalAuthentication auth = LocalAuthentication();
  bool isArabic = false;
  bool _isFaceIdEnabled = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkFaceIdEnabled();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canUse = await BiometricService.canUseBiometrics();

      if (mounted) {
        setState(() {
          _canUseBiometrics = canUse;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  Future<void> _checkFaceIdEnabled() async {
    try {
      final enabled = await BiometricService.isFaceIdEnabled();

      if (mounted) {
        setState(() {
          _isFaceIdEnabled = enabled;
        });
      }
    } catch (e) {
      debugPrint('Error checking Face ID status: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      if (!_canUseBiometrics) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final authenticated = await BiometricService.authenticateWithFaceId(
        reason: 'Authenticate to login to Flosy',
      );

      if (authenticated && mounted) {
        // Get stored credentials
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('saved_email');
        final savedPassword = prefs.getString('saved_password');

        if (savedEmail != null && savedPassword != null) {
          emailController.text = savedEmail;
          passwordController.text = savedPassword;

          // Trigger login
          if (_formKey.currentState!.validate()) {
            context.read<AuthCubit>().login(
              emailController.text.trim(),
              passwordController.text.trim(),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No saved credentials found. Please login manually first.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  @override
  Widget build(BuildContext context) {
    isArabic = context.locale.languageCode == 'ar';
    return Scaffold(
      body: BlocListener<AuthCubit, AuthCubitState>(
        listener: (context, state) async {
          if (state is AuthLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(color: AppColors.greenColor),
              ),
            );
          } else if (state is AuthSuccess) {
            Navigator.of(context).pop();

            // Save credentials if Face ID is enabled
            if (_isFaceIdEnabled) {
              await _saveCredentials(
                emailController.text.trim(),
                passwordController.text.trim(),
              );
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainNavScreen()),
            );
          } else if (state is AuthError) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),
                    // Logo
                    Image.asset(
                      'assets/icons/logo.png',
                      height: 120.h,
                      width: 180.w,
                    ),

                    // Header
                    Text(
                      'welcome_back'.tr(),
                      style: AppText.body28(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode(context)
                            ? Colors.white
                            : Colors.black87,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'please_login_to_your_account'.tr(),
                      style: AppText.body14(context).copyWith(
                        color: isDarkMode(context)
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    SizedBox(height: 40.h),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        hintText: 'enter_your_email'.tr(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.greenColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        hintText: 'enter_your_password'.tr(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.greenColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),

                    // Forgot Password
                    Align(
                      alignment: isArabic
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'forgot_password'.tr(),
                          style: AppText.body14(
                            context,
                          ).copyWith(color: AppColors.greenColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Login Button
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthCubit>().login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenColor,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'login'.tr(),
                        style: AppText.body16(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Face ID / Biometric Login Button
                    if (_isFaceIdEnabled && _canUseBiometrics) ...[
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'or_continue_with'.tr(),
                              style: AppText.body14(
                                context,
                              ).copyWith(color: Colors.grey),
                            ),
                            SizedBox(height: 16.h),
                            InkWell(
                              onTap: _authenticateWithBiometrics,
                              borderRadius: BorderRadius.circular(50.r),
                              child: Container(
                                width: 60.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.greenColor.withOpacity(0.1),
                                  border: Border.all(
                                    color: AppColors.greenColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.fingerprint,
                                  color: AppColors.greenColor,
                                  size: 32.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Use Face ID',
                              style: AppText.body12grey(context).copyWith(
                                color: AppColors.greenColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Or Continue With
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'or_continue_with'.tr(),
                            style: AppText.body14(context).copyWith(
                              color: Colors.grey[500],
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Google Sign In
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Google Sign-In not implemented yet'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.red,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'continue_with_google'.tr(),
                            style: AppText.body16(context).copyWith(
                              color: isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'dont_have_an_account'.tr(),
                          style: AppText.body14(context).copyWith(
                            color: isDarkMode(context)
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'create_account'.tr(),
                            style: AppText.body14(context).copyWith(
                              color: AppColors.greenColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscured = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    bool isDarkMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? obscured : false,
          validator: validator,
          decoration: InputDecoration(
            filled: true, // <-- required for fillColor to work
            fillColor: isDarkMode
                ? Colors.grey[800] // dark mode background
                : Colors.grey[350], // light mode background
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.colorButton, width: 2),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppText.textButton(
                  context,
                ).copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'or_continue_with'.tr(),
            style: AppText.body16(
              context,
            ).copyWith(color: Colors.grey[500], fontSize: 14.sp),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isDarkMode = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[400]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20, color: Colors.red),
            SizedBox(width: 12.w),
            Text(
              text,
              style: AppText.body16(context).copyWith(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
