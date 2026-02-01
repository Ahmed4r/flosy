import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/services/language_service.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selectedLanguage;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedLanguage = context.locale.languageCode;
      _loadSelectedLanguage();
      _initialized = true;
    }
  }

  Future<void> _loadSelectedLanguage() async {
    final language = await LanguageService.getLanguage();
    if (mounted) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LanguageService.setLanguage(languageCode);
    if (mounted) {
      await context.setLocale(Locale(languageCode));
      setState(() {
        _selectedLanguage = languageCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('settings.language_changed'.tr()),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = AppTheme.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        surfaceTintColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'settings.select_language'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      backgroundColor: isDarkMode ? Color(0xFF1F1F1F) : Colors.grey[50],
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.language'.tr(),
              style: AppText.body16(context).copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16.h),
            _buildLanguageOption(context, 'English', 'en', isDarkMode),
            SizedBox(height: 12.h),
            _buildLanguageOption(context, 'العربية', 'ar', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageName,
    String languageCode,
    bool isDarkMode,
  ) {
    final isSelected = _selectedLanguage == languageCode;
    return GestureDetector(
      onTap: () => _changeLanguage(languageCode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.2)
              : (isDarkMode ? Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : SizedBox(),
            ),
            SizedBox(width: 16.w),
            Text(
              languageName,
              style: AppText.body16(context).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
