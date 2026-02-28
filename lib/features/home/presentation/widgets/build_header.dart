import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/ai_insights/screens/ai_insights_screen.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../settings/cubit/settings_state.dart';

Widget buildHeader(BuildContext context, String Function() getGreetingMessage) {
  bool isDarkMode = AppTheme.isDarkMode(context);

  return Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        // Get user info from Firebase and SettingsCubit
        final user = FirebaseAuth.instance.currentUser;
        String userName = 'Guest'; // Default fallback (non-translated)

        // Priority: SettingsCubit state > Firebase display name > Email name > Guest
        if (state is SettingsLoaded) {
          // SAFE: Check if userName exists and is not empty
          if (state.userName.isNotEmpty) {
            userName = state.userName;
          } else if (user?.displayName != null &&
              user!.displayName!.isNotEmpty) {
            userName = user.displayName!;
          } else if (user?.email != null) {
            // Extract name from email (before @)
            final emailName = user!.email!.split('@').first;
            // Capitalize first letter and replace dots/underscores
            userName = emailName.isNotEmpty
                ? emailName
                      .replaceAll('.', ' ')
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map(
                        (word) => word.isNotEmpty
                            ? word[0].toUpperCase() + word.substring(1)
                            : '',
                      )
                      .join(' ')
                : 'Guest';
          }
        } else {
          // State is not loaded yet, use Firebase data
          if (user?.displayName != null && user!.displayName!.isNotEmpty) {
            userName = user.displayName!;
          } else if (user?.email != null) {
            final emailName = user!.email!.split('@').first;
            userName = emailName.isNotEmpty
                ? emailName[0].toUpperCase() + emailName.substring(1)
                : 'Guest';
          }
        }

        File? profileImage;
        if (state is SettingsLoaded) {
          profileImage = state.profileImage;
        }

        return Row(
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
              child: CircleAvatar(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // AI Insights button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiInsightsScreen(),
                ),
              ),
              child: Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(
                        isDarkMode ? 0.3 : 0.1,
                      ),
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
        );
      },
    ),
  );
}
