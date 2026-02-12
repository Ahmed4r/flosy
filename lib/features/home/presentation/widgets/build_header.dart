import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildHeader(BuildContext context, String Function() getGreetingMessage) {
  bool isDarkMode = AppTheme.isDarkMode(context);

  return Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: Row(
      children: [
        // Avatar with green ring
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenColor.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              File? profileImage;
              if (state is SettingsLoaded) {
                profileImage = state.profileImage;
              }
              return CircleAvatar(
                radius: 22.r,
                backgroundColor: isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[200],
                backgroundImage: profileImage != null
                    ? FileImage(profileImage)
                    : null,
                child: profileImage == null
                    ? Icon(Icons.person, size: 22.sp, color: Colors.grey[500])
                    : null,
              );
            },
          ),
        ),
        SizedBox(width: 14.w),

        // Greeting + Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getGreetingMessage(),
                style: AppText.body12(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'home.user_name'.tr(),
                style: AppText.body18(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Notification bell with badge
        Stack(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 22.sp,
              ),
            ),
            // Red dot indicator
            Positioned(
              right: 10.w,
              top: 10.h,
              child: Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[900]! : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
