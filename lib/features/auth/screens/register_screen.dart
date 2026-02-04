import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flosy/features/auth/screens/login_screen.dart';
import 'package:flosy/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isArabic = false;
  bool obscuredPassword = true;
  bool obscuredConfirmPassword = true;
  bool agreeToTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    isArabic = context.locale.languageCode == 'ar';
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      'create_account'.tr(),
                      style: AppText.head24(context).copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'create_account_subtitle'.tr(),
                      style: AppText.body16(context).copyWith(
                        color: isDarkMode ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Name Field
                    _buildInputField(
                      controller: nameController,
                      label: 'name'.tr(),
                      hint: 'enter_your_name'.tr(),
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'name_required'.tr();
                        }
                        if (value.length < 3) {
                          return 'name_min_length'.tr();
                        }
                        return null;
                      },
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16.h),

                    // Email Field
                    _buildInputField(
                      controller: emailController,
                      label: 'email'.tr(),
                      hint: 'enter_your_email'.tr(),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16.h),

                    // Password Field
                    _buildInputField(
                      controller: passwordController,
                      label: 'password'.tr(),
                      hint: 'enter_your_password'.tr(),
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscured: obscuredPassword,
                      onToggleVisibility: () {
                        setState(() => obscuredPassword = !obscuredPassword);
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
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16.h),

                    // Confirm Password Field
                    _buildInputField(
                      controller: confirmPasswordController,
                      label: 'confirm_password'.tr(),
                      hint: 'confirm_your_password'.tr(),
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscured: obscuredConfirmPassword,
                      onToggleVisibility: () {
                        setState(
                          () => obscuredConfirmPassword =
                              !obscuredConfirmPassword,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'confirm_password_required'.tr();
                        }
                        if (value != passwordController.text) {
                          return 'passwords_not_match'.tr();
                        }
                        return null;
                      },
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 16.h),

                    // Terms Checkbox
                    Row(
                      children: [
                        SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: Checkbox(
                            value: agreeToTerms,
                            onChanged: (value) {
                              setState(() => agreeToTerms = value ?? false);
                            },
                            activeColor: AppColors.colorButton,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'agree_to'.tr(),
                              style: AppText.body16(context).copyWith(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                              children: [
                                TextSpan(
                                  text: 'terms_and_conditions'.tr(),
                                  style: TextStyle(
                                    color: AppColors.colorButton,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Register Button
                    BlocListener<AuthCubitCubit, AuthCubitState>(
                      listener: (context, state) {
                        if (state is AuthCubitSuccess) {
                          // navigate to home after successful register
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
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
                            text: 'create_account'.tr(),
                            isLoading: state is AuthCubitLoading,
                            onPressed: agreeToTerms
                                ? () {
                                    if (_formKey.currentState!.validate()) {
                                      // only trigger register; navigation happens in listener
                                      context.read<AuthCubitCubit>().register(
                                        emailController.text
                                            .trim(), // Add .trim()
                                        passwordController.text
                                            .trim(), // Add .trim()
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Divider
                    _buildDivider(),
                    SizedBox(height: 24.h),

                    // Google Sign Up
                    _buildSocialButton(
                      isDarkMode: isDarkMode,
                      icon: FontAwesomeIcons.google,
                      text: 'continue_with_google'.tr(),
                      onPressed: () {
                        BlocListener<AuthCubitCubit, AuthCubitState>(
                          listener: (context, state) {
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
                              if (state is AuthCubitLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.colorButton,
                                  ),
                                );
                              }
                              return _buildSocialButton(
                                icon: FontAwesomeIcons.google,
                                text: 'continue_with_google'.tr(),
                                isDarkMode: isDarkMode,
                                onPressed: () {
                                  // Implement Google Sign-In
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 32.h),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'already_have_account'.tr(),
                          style: AppText.body16(
                            context,
                          ).copyWith(color: Colors.grey[600]),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (context) => AuthCubitCubit(),
                                  child: const LoginScreen(),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'login'.tr(),
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
            fillColor: isDarkMode
                ? Colors.grey[800] // dark mode background
                : Colors.grey[350], // light mode background
            hintText: hint,
            prefixIcon: Icon(
              prefixIcon,
              color: isDarkMode ? Colors.white : Colors.black87,
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDarkMode ? Colors.white : Colors.grey[600],
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
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorButton,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
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
        Expanded(child: Divider(color: Colors.grey[500], thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'or_continue_with'.tr(),
            style: AppText.body16(
              context,
            ).copyWith(color: Colors.grey[700], fontSize: 14.sp),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[500], thickness: 1)),
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
          side: BorderSide(color: Colors.grey[500]!),
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
                color: isDarkMode == true ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
