import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flosy/features/auth/screens/forget_screen.dart';
import 'package:flosy/features/auth/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
                    Text('welcome_back'.tr(), style: AppText.head24(context)),
                    SizedBox(height: 8.h),
                    Text(
                      'please_login_to_your_account'.tr(),
                      style: AppText.body16(
                        context,
                      ).copyWith(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 10.h),

                    // Email Field
                    _buildInputField(
                      controller: emailController,
                      label: 'email'.tr(),
                      hint: 'enter_your_email'.tr(),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                      onToggleVisibility: () {
                        setState(() => obscured = !obscured);
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

                    // Login Button
                    _buildPrimaryButton(
                      text: 'login'.tr(),
                      isLoading: isLoading,
                      onPressed: () {
                        // Handle login
                      },
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body16(context).copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? obscured : false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
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
              style: AppText.body16(
                context,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
