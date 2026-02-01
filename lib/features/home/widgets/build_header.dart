import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/screens/language_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildHeader(BuildContext context, String Function() getGreetingMessage) {
  bool isDarkMode = AppTheme.isDarkMode(context);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent, width: 3),
        ),
        child: CircleAvatar(
          radius: 20.r,
          backgroundImage: AssetImage('assets/images/profile.jpg'),
        ),
      ),
      SizedBox(width: 15.w),
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
      // IconButton(
      IconButton(
        icon: Icon(
          Icons.language,

          color: isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSettingsScreen(),
            ),
          );
        },
      ),
      Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications,
          color: isDarkMode ? Colors.white : Colors.black,
          size: 20.sp,
        ),
      ),
    ],
  );
}
