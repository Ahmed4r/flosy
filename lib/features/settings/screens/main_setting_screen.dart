import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flosy/features/settings/screens/change_pin_screen.dart';
import 'package:flosy/features/settings/screens/currency_settings_screen.dart';
import 'package:flosy/features/settings/screens/edit_profile_screen.dart';
import 'package:flosy/features/settings/screens/language_settings_screen.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class MainSettingScreen extends StatelessWidget {
  const MainSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value instead of creating a new instance
    return const _MainSettingView();
  }
}

class _MainSettingView extends StatelessWidget {
  const _MainSettingView();

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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                SizedBox(height: 24.h),

                // Data Section
                _buildSectionHeader(context, isDarkMode, 'settings.data'.tr()),
                SizedBox(height: 12.h),
                _buildDataSection(context, isDarkMode),
                SizedBox(height: 24.h),

                // Logout Button
                _buildLogoutButton(context, isDarkMode),
                SizedBox(height: 16.h),

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
                  Text(
                    user?.displayName ?? 'settings.user_name'.tr(),
                    style: AppText.body16(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'settings.arabic'.tr()
                      : 'settings.english'.tr(),
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
                  builder: (context) => const LanguageSettingsScreen(),
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
            icon: FontAwesomeIcons.lock,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.withOpacity(0.15),
            title: 'settings.change_pin'.tr(),
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              size: 20.sp,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePinScreen(),
                ),
              );
            },
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
      child: _buildSettingsTile(
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
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Request storage permission (Android only)
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.storage.status;

        // Check if permission is denied
        if (status.isDenied) {
          status = await Permission.storage.request();
        }

        // If still denied, show dialog to open settings
        if (status.isDenied || status.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDialog(context, status.isPermanentlyDenied);
          }
          return;
        }

        // If permission not granted, return
        if (!status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings.storage_permission_required'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.greenColor),
        ),
      );

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

      // Create PDF
      final pdf = pw.Document();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      for (var transaction in transactions) {
        if (transaction.type.name == 'income') {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Flosy - Transaction Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
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
                    'Total Income',
                    totalIncome,
                    PdfColors.green,
                  ),
                  _buildSummaryItem(
                    'Total Expense',
                    totalExpense,
                    PdfColors.red,
                  ),
                  _buildSummaryItem(
                    'Balance',
                    totalIncome - totalExpense,
                    totalIncome >= totalExpense
                        ? PdfColors.green
                        : PdfColors.red,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Text(
              'Transaction History',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Title', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Type', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                  ],
                ),
                // Table Rows
                ...transactions.map((transaction) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        DateFormat('MMM dd, yyyy').format(transaction.date),
                      ),
                      _buildTableCell(transaction.title),
                      _buildTableCell(transaction.category),
                      _buildTableCell(
                        transaction.type.name.toUpperCase(),
                        textColor: transaction.type.name == 'income'
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                      _buildTableCell(
                        '\$${transaction.amount.toStringAsFixed(2)}',
                        textColor: transaction.type.name == 'income'
                            ? PdfColors.green
                            : PdfColors.red,
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
              'Total Transactions: ${transactions.length}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
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

      Navigator.pop(context); // Close loading dialog

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

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '\$${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
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
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
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
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'settings.log_out'.tr(),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
