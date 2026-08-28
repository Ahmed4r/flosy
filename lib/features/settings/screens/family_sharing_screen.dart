import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({Key? key}) : super(key: key);

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = true;
  String _myFamilyId = '';

  @override
  void initState() {
    super.initState();
    _loadFamilyId();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _myFamilyId = doc.data()?['familyId'] ?? user.uid;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _myFamilyId = user.uid;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFamily() async {
    final newFamilyId = _codeController.text.trim();
    if (newFamilyId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update user's familyId in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'familyId': newFamilyId,
      }, SetOptions(merge: true));

      // 2. Clear local DB to prepare for new family sync
      await dbService.deleteAllTransactions();

      if (mounted) {
        setState(() {
          _myFamilyId = newFamilyId;
          _isLoading = false;
        });
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.joined_family_success'.tr()),
            backgroundColor: AppColors.greenColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"settings.error_joining_family".tr()}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _leaveFamily() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.leave_family'.tr()),
        content: Text('settings.join_family_warning'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('settings.leave_family'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'familyId': user.uid,
      }, SetOptions(merge: true));

      await dbService.deleteAllTransactions();

      if (mounted) {
        setState(() {
          _myFamilyId = user.uid;
          _isLoading = false;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final isSharedFamily = user != null && _myFamilyId.isNotEmpty && _myFamilyId != user.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.blackColor : AppColors.whiteColor,
      appBar: AppBar(
        title: Text(
          'settings.family_sharing'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.blackColor : AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20.sp,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.greenColor.withOpacity(0.18),
                          Colors.purple.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56.w,
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: AppColors.greenColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.users,
                              color: AppColors.greenColor,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'settings.family_title'.tr(),
                          style: AppText.body18(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'settings.family_desc'.tr(),
                          style: AppText.body12(context).copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // My Family Code Box
                  Text(
                    'settings.my_family_code'.tr(),
                    style: AppText.body14(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _myFamilyId,
                            style: AppText.body14(context).copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, color: AppColors.greenColor, size: 22.sp),
                          tooltip: 'settings.copy_code'.tr(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _myFamilyId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('settings.code_copied'.tr()),
                                backgroundColor: AppColors.greenColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Current Family Members List
                  if (_myFamilyId.isNotEmpty) ...[
                    Text(
                      'settings.family_members'.tr(),
                      style: AppText.body14(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('familyId', isEqualTo: _myFamilyId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ));
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16.r,
                                  backgroundColor: AppColors.greenColor,
                                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  user?.displayName ?? user?.email ?? 'settings.member_you'.tr(),
                                  style: AppText.body14(context).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data();
                            final isMe = doc.id == user?.uid;
                            final name = data['name'] ?? data['displayName'] ?? (isMe ? (user?.displayName ?? user?.email ?? 'settings.member_you'.tr()) : doc.id.substring(0, 6));

                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isMe
                                      ? AppColors.greenColor.withOpacity(0.4)
                                      : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.r,
                                    backgroundColor: isMe ? AppColors.greenColor : Colors.purple,
                                    child: Text(
                                      (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      isMe ? '$name (${"settings.member_you".tr()})' : name,
                                      style: AppText.body14(context).copyWith(
                                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isMe)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.greenColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: TextStyle(color: AppColors.greenColor, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Join Family Input
                  Text(
                    'settings.join_family'.tr(),
                    style: AppText.body14(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'settings.enter_family_code'.tr(),
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: AppColors.greenColor, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: _joinFamily,
                      child: Text(
                        'settings.join_family_btn'.tr(),
                        style: AppText.body14(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (isSharedFamily) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: _leaveFamily,
                        child: Text(
                          'settings.leave_family'.tr(),
                          style: AppText.body14(context).copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 20.h),
                  Text(
                    'settings.join_family_warning'.tr(),
                    style: AppText.body12(context).copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
