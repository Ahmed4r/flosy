import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isArabic = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Icon
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.colorButton.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.lock_reset_outlined,
                        size: 40.sp,
                        color: AppColors.colorButton,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Header
                  Text(
                    'forgot_password_title'.tr(),
                    style: AppText.head24(context),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'forgot_password_subtitle'.tr(),
                    style: AppText.body16(
                      context,
                    ).copyWith(color: Colors.grey[600], height: 1.5),
                  ),
                  SizedBox(height: 32.h),

                  // Email Field
                  Text(
                    'email'.tr(),
                    style: AppText.body16(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'enter_your_email'.tr(),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
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

                  const Spacer(),

                  // Send Button with BlocListener and BlocBuilder
                  BlocListener<AuthCubit, AuthCubitState>(
                    listener: (context, state) {
                      if (state is AuthSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('password_reset_email_sent'.tr()),
                            backgroundColor: Colors.green,
                          ),
                        );
                        log(emailController.text.trim());
                        Navigator.pop(context);
                      }
                      if (state is AuthError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<AuthCubit, AuthCubitState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      BlocProvider.of<AuthCubit>(

                                        context,
                                      ).resetPassword(
                                        emailController.text.trim(),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.colorButton,
                              disabledBackgroundColor: Colors.grey[300],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: state is AuthLoading
                                ? SizedBox(
                                    height: 24.h,
                                    width: 24.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'send_code'.tr(),
                                    style: AppText.textButton(
                                      context,
                                    ).copyWith(color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
