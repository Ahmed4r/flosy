import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/auth/screens/login_screen.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/cubit/home_cubit.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flosy/features/settings/screens/currency_settings_screen.dart';
import 'package:flosy/features/settings/screens/edit_profile_screen.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubit/settings_state.dart';

class MainSettingScreen extends StatelessWidget {
  const MainSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value instead of creating a new instance
    return const _MainSettingView();
  }
}

class _MainSettingView extends StatefulWidget {
  const _MainSettingView();

  @override
  State<_MainSettingView> createState() => _MainSettingViewState();
}

class _MainSettingViewState extends State<_MainSettingView> {
  double totalBalance = 0.0;
  @override
  initState() {
    super.initState();
    getTotalBalance();
    // Load cached/remote user name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsCubit>().getUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.blackColor : AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? AppColors.blackColor
            : AppColors.whiteColor,
        elevation: 0,
        centerTitle: true,

        title: Text(
          'settings.settings'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) {
          // Rebuild whenever state changes
          if (previous is SettingsLoaded && current is SettingsLoaded) {
            return previous.profileImage?.path != current.profileImage?.path;
          }
          return true;
        },
        builder: (context, state) {
          File? profileImage;
          if (state is SettingsLoaded) {
            profileImage = state.profileImage;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Card
                _buildProfileCard(context, isDarkMode, user, profileImage),
                SizedBox(height: 24.h),

                // Preferences Section
                _buildSectionHeader(
                  context,
                  isDarkMode,
                  'settings.preferences'.tr(),
                ),
                SizedBox(height: 12.h),
                _buildPreferencesSection(context, isDarkMode, state),
                SizedBox(height: 24.h),

                // Security Section
                _buildSectionHeader(
                  context,
                  isDarkMode,
                  'settings.security'.tr(),
                ),
                SizedBox(height: 12.h),
                _buildSecuritySection(context, isDarkMode, state),
                SizedBox(height: 10.h),

                // Data Section
                _buildSectionHeader(context, isDarkMode, 'settings.data'.tr()),
                SizedBox(height: 12.h),
                _buildDataSection(context, isDarkMode),
                SizedBox(height: 10.h),

                // Logout Button
                _buildLogoutButton(context, isDarkMode),
                SizedBox(height: 100.h),

                // Version
                Center(
                  child: Text(
                    'settings.version'.tr(),
                    style: AppText.body12grey(context).copyWith(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    bool isDarkMode,
    User? user,
    File? profileImage,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
        if (result == true) {
          // Refresh the page if needed
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.greenColor.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
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
                      radius: 30.r,
                      backgroundColor: AppColors.greenColor,
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                profileImage,
                                key: ValueKey(
                                  profileImage.path,
                                ), // Add unique key
                                width: 60.r,
                                height: 60.r,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 30.sp,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 30.sp,
                              color: Colors.white,
                            ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: AppColors.greenColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? AppColors.blackColor : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.check, size: 10.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    bloc: context.read<SettingsCubit>(),
                    builder: (context, state) {
                      final cubit = context.read<SettingsCubit>();
                      final displayName = user?.displayName?.isNotEmpty == true
                          ? user!.displayName!
                          : (cubit.userName.isNotEmpty
                                ? cubit.userName
                                : 'User');
                      return Text(
                        displayName,
                        style: AppText.body16(context).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: AppText.body14(context).copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Edit Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'settings.edit'.tr(),
                style: AppText.body14(context).copyWith(
                  color: AppColors.greenColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDarkMode,
    String title,
  ) {
    return Text(
      title.toUpperCase(),
      style: AppText.body12grey(context).copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    bool isDarkMode,
    SettingsState state,
  ) {
    String currentCurrency = 'EGP';
    if (state is SettingsLoaded) {
      currentCurrency = state.selectedCurrency;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            isDarkMode,
            icon: FontAwesomeIcons.dollarSign,
            iconColor: AppColors.greenColor,
            iconBgColor: AppColors.greenColor.withOpacity(0.15),
            title: 'settings.currency'.tr(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentCurrency,
                  style: AppText.body14(context).copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20.sp,
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<SettingsCubit>(),
                    child: const CurrencySettingsScreen(),
                  ),
                ),
              );
            },
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.white12 : Colors.grey[200],
          ),
          _buildSettingsTile(
            context,
            isDarkMode,
            icon: FontAwesomeIcons.globe,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.withOpacity(0.15),
            title: 'settings.language'.tr(),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                style: AppText.body16(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                value: context.locale.languageCode,
                // إعدادات القائمة الخاصة بك
                items: [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.setLocale(Locale(value));
                  }
                },
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.white12 : Colors.grey[200],
          ),
          _buildSettingsTile(
            context,
            isDarkMode,
            icon: FontAwesomeIcons.moon,
            iconColor: Colors.indigo,
            iconBgColor: Colors.indigo.withOpacity(0.15),
            title: 'settings.dark_mode'.tr(),
            trailing: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                bool isDark = isDarkMode;
                if (state is SettingsLoaded) {
                  isDark = state.isDarkMode;
                }
                return Switch(
                  value: isDark,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleTheme(value);
                  },
                  activeColor: AppColors.greenColor,
                  activeTrackColor: AppColors.greenColor.withOpacity(0.5),
                );
              },
            ),
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    bool isDarkMode,
    SettingsState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          BlocListener<SettingsCubit, SettingsState>(
            listener: (context, state) {
              if (state is SettingsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildSettingsTile(
              context,
              isDarkMode,
              icon: FontAwesomeIcons.faceSmile,
              iconColor: Colors.purple,
              iconBgColor: Colors.purple.withOpacity(0.15),
              title: 'settings.face_id'.tr(),
              trailing: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  bool enabled = false;
                  if (state is SettingsLoaded) {
                    enabled = state.faceIdEnabled;
                  }
                  return Switch(
                    value: enabled,
                    onChanged: (value) async {
                      await context.read<SettingsCubit>().toggleFaceId(value);
                      final newState = context.read<SettingsCubit>().state;
                      if (newState is SettingsLoaded &&
                          newState.faceIdEnabled == value) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'settings.face_id_enabled'.tr()
                                    : 'settings.face_id_disabled'.tr(),
                              ),
                              backgroundColor: AppColors.greenColor,
                            ),
                          );
                        }
                      }
                    },
                    activeColor: AppColors.greenColor,
                    activeTrackColor: AppColors.greenColor.withOpacity(0.5),
                  );
                },
              ),
              onTap: null,
            ),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.white12 : Colors.grey[200],
          ),
          _buildSettingsTile(
            context,
            isDarkMode,
            icon: FontAwesomeIcons.sync,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.withOpacity(0.15),
            title: 'settings.sync'.tr(),
            trailing: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state is SettingsLoaded) {
                  return Switch(
                    key: ValueKey('sync_switch_${state.isSyncing}'),
                    value: state.isSyncing,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleSync(value, context);
                    },
                    activeColor: Colors.orange,
                  );
                }
                return const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        bloc: SettingsCubit(),
        builder: (context, state) {
          return Column(
            children: [
              _buildSettingsTile(
                context,
                isDarkMode,
                icon: FontAwesomeIcons.download,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withOpacity(0.15),
                title: 'settings.export_data'.tr(),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20.sp,
                ),
                onTap: () => _exportData(context),
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.white12 : Colors.grey[200],
              ),
              _buildSettingsTile(
                context,
                isDarkMode,
                icon: FontAwesomeIcons.cloud,
                iconColor: Colors.blueAccent,
                iconBgColor: Colors.blueAccent.withOpacity(0.15),
                title: 'settings.delete_cloud_data'.tr(),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20.sp,
                ),
                onTap: () async {
                  await context.read<SettingsCubit>().clearCloudData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings.cloud_data_removed'.tr()),
                      backgroundColor: Colors.blueAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.white12 : Colors.grey[200],
              ),
              _buildSettingsTile(
                context,
                isDarkMode,
                icon: FontAwesomeIcons.hardDrive,
                iconColor: Colors.pink,
                iconBgColor: Colors.pink.withOpacity(0.15),
                title: 'settings.delete_local_data'.tr(),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20.sp,
                ),
                onTap: () async {
                  await context.read<SettingsCubit>().clearLocalData(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings.local_data_removed'.tr()),
                      backgroundColor: Colors.pink,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.white12 : Colors.grey[200],
              ),
              _buildSettingsTile(
                context,
                isDarkMode,
                icon: FontAwesomeIcons.database,
                iconColor: Colors.limeAccent,
                iconBgColor: Colors.limeAccent.withOpacity(0.15),
                title: 'settings.delete_all_data'.tr(),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20.sp,
                ),
                onTap: () async {
                  await context.read<SettingsCubit>().clearAllData(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings.all_data_removed'.tr()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<double> getTotalBalance() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    double balance = pref.getDouble('total_balance') ?? 0.0;
    return balance;
  }

  Future<bool> _handleStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // أندرويد 13 فما فوق (API 33+) لا يطلب Permission.storage للـ PDF
      if (sdkInt >= 33) return true;

      // للإصدارات الأقدم من أندرويد 13
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) return true;

      if (context.mounted) {
        _showPermissionDialog(context, status.isPermanentlyDenied);
      }
      return false;
    }
    return true; // iOS أو منصات أخرى
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final hasPermission = await _handleStoragePermission(context);
      if (!hasPermission) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.greenColor),
        ),
      );

      // Refresh total balance before export
      await getTotalBalance();

      // Get all transactions from database
      final transactions = await dbService.getTransactions();

      if (transactions.isEmpty) {
        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.no_transactions'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Load Arabic-compatible font
      final fontData = await rootBundle.load(
        'assets/fonts/Cairo-VariableFont_slnt,wght.ttf',
      );
      final ttf = pw.Font.ttf(fontData);
      final ttfBold = pw.Font.ttf(
        fontData,
      ); // Use same for bold since it's a variable font

      // Check if current locale is Arabic
      final isArabic = context.locale.languageCode == 'ar';

      // Create PDF
      final pdf = pw.Document();

      // Calculate totals from transactions
      double totalIncome = 0;
      double totalExpense = 0;
      for (var transaction in transactions) {
        if (transaction.type.name == 'income') {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      // Use the actual total balance from database instead of calculating income - expense
      final actualBalance = await getTotalBalance();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: isArabic
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic
                        ? 'فلوسي - تقرير المعاملات'
                        : 'Flosy - Transaction Report',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                    textDirection: isArabic
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${isArabic ? 'تم الإنشاء في' : 'Generated on'}: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                    textDirection: isArabic
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary Section
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    isArabic ? 'إجمالي الدخل' : 'Total Income',
                    totalIncome,
                    PdfColors.green,
                    ttf,
                    isArabic,
                  ),
                  _buildSummaryItem(
                    isArabic ? 'إجمالي النفقات' : 'Total Expense',
                    totalExpense,
                    PdfColors.red,
                    ttf,
                    isArabic,
                  ),
                  _buildSummaryItem(
                    isArabic ? 'الرصيد' : 'Balance',
                    actualBalance,
                    actualBalance >= 0 ? PdfColors.green : PdfColors.red,
                    ttf,
                    isArabic,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Text(
              isArabic ? 'سجل المعاملات' : 'Transaction History',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: isArabic
                      ? [
                          _buildTableCell(
                            'المبلغ',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'النوع',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'الفئة',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'العنوان / الملاحظة',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'التاريخ',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                        ]
                      : [
                          _buildTableCell(
                            'Date',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'Title / Note',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'Category',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'Type',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                          _buildTableCell(
                            'Amount',
                            isHeader: true,
                            font: ttf,
                            isArabic: isArabic,
                          ),
                        ],
                ),
                // Table Rows
                ...transactions.map((transaction) {
                  // Combine title with note if exists
                  String titleWithNote = transaction.title;

                  return pw.TableRow(
                    children: isArabic
                        ? [
                            _buildTableCell(
                              '\$${transaction.amount.toStringAsFixed(2)}',
                              textColor: transaction.type.name == 'income'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              transaction.type.name == 'income'
                                  ? 'دخل'
                                  : 'مصروف',
                              textColor: transaction.type.name == 'income'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              transaction.category,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              titleWithNote,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(transaction.date),
                              font: ttf,
                              isArabic: isArabic,
                            ),
                          ]
                        : [
                            _buildTableCell(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(transaction.date),
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              titleWithNote,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              transaction.category,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              transaction.type.name.toUpperCase(),
                              textColor: transaction.type.name == 'income'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                            _buildTableCell(
                              '\$${transaction.amount.toStringAsFixed(2)}',
                              textColor: transaction.type.name == 'income'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              font: ttf,
                              isArabic: isArabic,
                            ),
                          ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              '${isArabic ? 'إجمالي المعاملات' : 'Total Transactions'}: ${transactions.length}',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
            ),
          ],
          footer: (context) => pw.Container(
            alignment: isArabic
                ? pw.Alignment.centerLeft
                : pw.Alignment.centerRight,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${isArabic ? 'صفحة' : 'Page'} ${context.pageNumber} ${isArabic ? 'من' : 'of'} ${context.pagesCount}',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 10,
                color: PdfColors.grey,
              ),
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
            ),
          ),
        ),
      );

      // Get directory based on platform
      Directory? directory;
      String successMessage = 'settings.pdf_exported'.tr();

      if (Platform.isAndroid) {
        // Android: Save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
        successMessage = 'settings.pdf_exported_android'.tr();
      } else if (Platform.isIOS) {
        // iOS: Save to app's document directory
        directory = await getApplicationDocumentsDirectory();
        successMessage = 'settings.pdf_exported_ios'.tr();
      }

      // Save PDF file
      final fileName =
          'Flosy_Transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory!.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      // For iOS, share the file directly
      if (Platform.isIOS) {
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: fileName,
        );
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.greenColor,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'settings.view'.tr(),
              textColor: Colors.white,
              onPressed: () async {
                final pdfData = await file.readAsBytes();
                await Printing.layoutPdf(onLayout: (format) async => pdfData);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'settings.export_failed'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(BuildContext context, bool isPermanentlyDenied) {
    final isDarkMode = AppTheme.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.blackColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.folder_open, color: AppColors.greenColor, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'settings.storage_permission'.tr(),
                style: AppText.body16(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isPermanentlyDenied
              ? 'settings.storage_permission_permanently_denied'.tr()
              : 'settings.storage_permission_denied'.tr(),
          style: AppText.body14(
            context,
          ).copyWith(color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr(),
              style: AppText.body14(context).copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Open app settings
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              'settings.open_settings'.tr(),
              style: AppText.body14(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    double amount,
    PdfColor color,
    pw.Font font,
    bool isArabic,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '\$${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            font: font,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
    required pw.Font font,
    required bool isArabic,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.red,
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'settings.log_out'.tr(),
              style: AppText.body16(
                context,
              ).copyWith(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    bool isDarkMode, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: FaIcon(icon, color: iconColor, size: 18.sp),
                ),
              ),
              SizedBox(width: 12.w),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppText.body16(context).copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Trailing
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'settings.log_out'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'settings.log_out_confirmation'.tr(),
          style: AppText.body14(
            context,
          ).copyWith(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: AppText.body14(context).copyWith(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginScreen();
                  },
                ),
              );
            },
            child: Text(
              'settings.log_out'.tr(),
              style: AppText.body16(
                context,
              ).copyWith(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
