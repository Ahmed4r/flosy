import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flosy/features/settings/screens/main_setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildHeader(BuildContext context, String Function() getGreetingMessage) {
  bool isDarkMode = AppTheme.isDarkMode(context);

  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent, width: 3),
        ),
        child: GestureDetector(
          onTap: () {
            // Handle profile picture tap, e.g., open image picker
          },
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              File? profileImage;
              // Get profile image from another source
              // For example, from SharedPreferences or another cubit
              if (state is SettingsLoaded) {
                profileImage = state.profileImage;
              }
              return CircleAvatar(
                radius: 20.r,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage)
                    : null,
                child: profileImage == null
                    ? Icon(Icons.person, size: 20.sp, color: Colors.grey)
                    : null,
              );
            },
          ),
        ),
      ),
      SizedBox(width: 12.w),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(getGreetingMessage(), style: AppText.body12grey(context)),
          Text(
            'home.user_name'.tr(),
            style: AppText.body16(context).copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      Spacer(),
      Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black54 : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: isDarkMode ? Colors.white : Colors.black,
          size: 20.sp,
        ),
      ),
    ],
  );
}
