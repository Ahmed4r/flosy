import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubit/settings_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _loadProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? imagePath = pref.getString('profile_image');
    if (!mounted) return;
    if (imagePath != null) {
      context.read<SettingsCubit>().updateProfileImage(File(imagePath));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.profile_updated'.tr()),
            backgroundColor: AppColors.greenColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.update_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  final ImagePicker picker = ImagePicker();
  XFile? image;
  Future<void> pickImage() async {
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      image = pickedImage;
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('profile_image', pickedImage.path);
      if (!mounted) return;
      context.read<SettingsCubit>().updateProfileImage(File(pickedImage.path));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.blackColor : AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? AppColors.blackColor
            : AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'settings.edit_profile'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 20.h),
              // Profile Picture
              Stack(
                children: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    bloc: context.read<SettingsCubit>(),
                    builder: (context, state) {
                      File? profileImage;

                      if (state is SettingsLoaded) {
                        profileImage = state.profileImage;
                      }
                      return CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.greenColor,
                        child: image != null
                            ? ClipOval(
                                child: Image.file(
                                  File(image!.path),
                                  width: 120.r,
                                  height: 120.r,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60.sp,
                                color: Colors.white,
                              ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.greenColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode
                                ? AppColors.blackColor
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              // Name Field
              TextFormField(
                controller: _nameController,
                style: AppText.body16(
                  context,
                ).copyWith(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'name'.tr(),
                  labelStyle: AppText.body14(context).copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.black54 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white12
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: AppColors.greenColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'name_required'.tr();
                  }
                  if (value.length < 3) {
                    return 'name_min_length'.tr();
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              // Email Field (Read-only)
              TextFormField(
                controller: _emailController,
                enabled: false,
                style: AppText.body16(context).copyWith(
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                ),
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  labelStyle: AppText.body14(context).copyWith(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.black38 : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'save'.tr(),
                          style: AppText.body16(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
