import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPin = prefs.getString('user_pin') ?? '';

      // Verify current PIN
      if (currentPin.isNotEmpty && currentPin != _currentPinController.text) {
        throw 'settings.incorrect_current_pin'.tr();
      }

      // Save new PIN
      await prefs.setString('user_pin', _newPinController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.pin_changed'.tr()),
            backgroundColor: AppColors.greenColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'settings.change_pin'.tr(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'settings.change_pin_desc'.tr(),
                style: AppText.body14(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 30.h),
              // Current PIN
              _buildPinField(
                controller: _currentPinController,
                label: 'settings.current_pin'.tr(),
                obscure: _obscureCurrentPin,
                onToggle: () =>
                    setState(() => _obscureCurrentPin = !_obscureCurrentPin),
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 20.h),
              // New PIN
              _buildPinField(
                controller: _newPinController,
                label: 'settings.new_pin'.tr(),
                obscure: _obscureNewPin,
                onToggle: () =>
                    setState(() => _obscureNewPin = !_obscureNewPin),
                isDarkMode: isDarkMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'settings.pin_required'.tr();
                  }
                  if (value.length < 4) {
                    return 'settings.pin_min_length'.tr();
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              // Confirm PIN
              _buildPinField(
                controller: _confirmPinController,
                label: 'settings.confirm_pin'.tr(),
                obscure: _obscureConfirmPin,
                onToggle: () =>
                    setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                isDarkMode: isDarkMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'settings.pin_required'.tr();
                  }
                  if (value != _newPinController.text) {
                    return 'settings.pins_not_match'.tr();
                  }
                  return null;
                },
              ),
              SizedBox(height: 40.h),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePin,
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
                          'settings.change_pin'.tr(),
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

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDarkMode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: AppText.body16(context).copyWith(
        color: isDarkMode ? Colors.white : Colors.black,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body14(
          context,
        ).copyWith(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          onPressed: onToggle,
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
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.greenColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
