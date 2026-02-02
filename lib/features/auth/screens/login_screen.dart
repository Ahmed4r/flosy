import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flosy/features/auth/screens/forget_screen.dart';
import 'package:flosy/features/auth/screens/register_screen.dart';
import 'package:flosy/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isArabic = false;
  bool obscured = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isArabic = context.locale.languageCode == 'ar';
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/icons/logo.png',
                      height: 120.h,
                      width: 180.w,
                    ),

                    // Header
                    Text(
                      'welcome_back'.tr(),
                      style: AppText.head24(context).copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'please_login_to_your_account'.tr(),
                      style: AppText.body16(context).copyWith(
                        color: isDarkMode ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Email Field
                    _buildInputField(
                      controller: emailController,
                      label: 'email'.tr(),
                      hint: 'enter_your_email'.tr(),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'email_required'.tr();
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'invalid_email'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Password Field
                    _buildInputField(
                      controller: passwordController,
                      label: 'password'.tr(),
                      hint: 'enter_your_password'.tr(),
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscured: obscured,
                      isDarkMode: isDarkMode,
                      onToggleVisibility: () {
                        setState(() => obscured = !obscured);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'password_required'.tr();
                        }
                        if (value.length < 8) {
                          return 'password_min_length'.tr();
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
                          // Navigate to forgot password
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (context) => AuthCubitCubit(),
                                child: const ForgotPasswordScreen(),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'forgot_password'.tr(),
                          style: AppText.body16(context).copyWith(
                            color: AppColors.colorButton,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Login Button with BlocListener and BlocBuilder
                    BlocListener<AuthCubitCubit, AuthCubitState>(
                      listener: (context, state) {
                        if (state is AuthCubitSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('login_success'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Navigate to home or next screen
                          // Navigator.pushReplacementNamed(context, '/home');
                        }
                        if (state is AuthCubitError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: BlocBuilder<AuthCubitCubit, AuthCubitState>(
                        builder: (context, state) {
                          return _buildPrimaryButton(
                            text: 'login'.tr(),
                            isLoading: state is AuthCubitLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubitCubit>().login(
                                  emailController.text,
                                  passwordController.text,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Divider
                    _buildDivider(),
                    SizedBox(height: 24.h),

                    // Google Sign In
                    _buildSocialButton(
                      icon: FontAwesomeIcons.google,
                      text: 'continue_with_google'.tr(),
                      onPressed: () {
                        // Handle Google sign in
                      },
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 32.h),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'dont_have_an_account'.tr(),
                          style: AppText.body16(
                            context,
                          ).copyWith(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (context) => AuthCubitCubit(),
                                  child: const RegisterScreen(),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'create_account'.tr(),
                            style: AppText.body16(context).copyWith(
                              color: AppColors.colorButton,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
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
