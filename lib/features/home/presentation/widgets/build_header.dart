import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/ai_insights/screens/ai_insights_screen.dart';
import 'package:flosy/features/home/presentation/cubit/recording_cubit.dart';
import 'package:flosy/features/home/presentation/screens/recording_screen.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../settings/cubit/settings_state.dart';

Widget buildHeader(BuildContext context, String Function() getGreetingMessage) {
  bool isDarkMode = AppTheme.isDarkMode(context);
  final user = FirebaseAuth.instance.currentUser;
  final userName = user?.displayName ?? 'settings.user_name'.tr();
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
                userName,
                style: AppText.body18(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Notification bell with badge
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiInsightsScreen()),
          ),
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/ai.png',
                width: 22.w,
                height: 22.h,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
