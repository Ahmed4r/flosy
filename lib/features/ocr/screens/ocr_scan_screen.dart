import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  File? _image;
  String _extracted = '';
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  String _category = 'more';

  @override
  void dispose() {
    _textRecognizer.close();
    _textController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? xfile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (xfile == null) return;

    setState(() {
      _image = File(xfile.path);
      _extracted = '';
      _textController.text = '';
      _titleController.text = '';
      _amountController.text = '';
    });
  }

  Map<String, dynamic> _parseTransaction(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final amountRegex = RegExp(
      r'[\$]?([0-9]{1,3}(?:[,0-9]{3})*(?:\.[0-9]{1,2})?)',
    );
    double? amount;
    for (final line in lines) {
      final m = amountRegex.firstMatch(line);
      if (m != null) {
        final cleaned = m.group(1)!.replaceAll(',', '');
        amount = double.tryParse(cleaned);
        if (amount != null) break;
      }
    }

    final dateRegexes = [
      RegExp(r'(\d{4}-\d{2}-\d{2})'),
      RegExp(r'(\d{2}/\d{2}/\d{4})'),
      RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})'),
    ];
    DateTime? date;
    for (final line in lines) {
      for (final r in dateRegexes) {
        final m = r.firstMatch(line);
        if (m != null) {
          final candidate = m.group(1)!.replaceAll('/', '-');
          date = DateTime.tryParse(candidate);
          if (date != null) break;
        }
      }
      if (date != null) break;
    }

    String title = lines.isNotEmpty ? lines.first : 'Receipt';
    for (final line in lines) {
      if (amountRegex.hasMatch(line)) continue;
      if (dateRegexes.any((r) => r.hasMatch(line))) continue;
      if (RegExp(
        r'^(total|subtotal|tax|balance|visa|mastercard|cash)\$',
        caseSensitive: false,
      ).hasMatch(line))
        continue;
      title = line;
      break;
    }

    String category = 'more';
    final lc = text.toLowerCase();
    if (lc.contains('restaurant') ||
        lc.contains('cafe') ||
        lc.contains('grocery') ||
        lc.contains('supermarket')) {
      category = 'food';
    } else if (lc.contains('uber') || lc.contains('taxi')) {
      category = 'transport';
    } else if (lc.contains('rent') || lc.contains('apartment')) {
      category = 'rent';
    }

    return {
      'amount': amount ?? 0.0,
      'date': date ?? DateTime.now(),
      'title': title,
      'category': category,
    };
  }

  Future<void> _saveParsedTransaction() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final title = _titleController.text.trim().isEmpty
        ? 'Receipt'
        : _titleController.text.trim();

    final transaction = TransactionModel(
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _category,
      type: _isExpense ? TransactionType.expense : TransactionType.income,
      iconCodePoint: Icons.receipt_outlined.codePoint,
      iconFontFamily: Icons.receipt_outlined.fontFamily ?? 'MaterialIcons',
      iconFontPackage: Icons.receipt_outlined.fontPackage,
    );

    try {
      await dbService.addTransaction(transaction);
      final prefs = await SharedPreferences.getInstance();
      double current = prefs.getDouble('total_balance') ?? 0.0;
      final delta = _isExpense ? -amount : amount;
      await prefs.setDouble('total_balance', current + delta);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('transaction.saved'.tr())));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }

    Future<void> _pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    }
  }

  Future<Map<String, dynamic>?> requestOcrApi() async {
    String baseUrl = 'https://api.ocr.space/parse/image';
    var response = await http.post(
      Uri.parse(baseUrl),
      headers: {'apikey': 'K87093961488957'},
      body: {
        'url':
            'https://img.freepik.com/free-vector/realistic-receipt-template_23-2147938550.jpg',
        'OCREngine': '1',
      },
    );
    log(response.body);
    return jsonDecode(response.body);
  }

  String extractTotal(String ocrText) {
    final regex = RegExp(
      r'(?:total|grand total|amount paid)\s*[:\-]?\s*\$?(\d+(\.\d{1,2})?)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(ocrText);
    if (match != null) {
      return match.group(1)!; // الرقم المستخرج
    }
    return 'Not found';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.blackColor : AppColors.whiteColor;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('scan_receipt'.tr(), style: AppText.body16(context)),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.photo_camera, color: AppColors.greenColor),
          //   // onPressed: () => _pickImage(ImageSource.camera),
          // ),
          // IconButton(
          //   icon: Icon(Icons.photo_library, color: AppColors.colorButton),
          //   // onPressed: () => _pickImage(ImageSource.gallery),
          // ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () async {
                final result = await requestOcrApi();
                if (result != null && result.containsKey('ParsedResults')) {
                  final parsedResults = result['ParsedResults'] as List;
                  if (parsedResults.isNotEmpty) {
                    final ocrText = parsedResults[0]['ParsedText'] as String;
                    final total = extractTotal(ocrText);
                    log('Extracted total: $total');
                  }
                }
              },
              child: Container(
                height: 220.h,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                //   child: _image != null
                //       ? ClipRRect(
                //           borderRadius: BorderRadius.circular(16.r),
                //           child: Image.file(_image!, fit: BoxFit.cover),
                //         )
                //       : Center(
                //           child: Column(
                //             mainAxisSize: MainAxisSize.min,
                //             children: [
                //               Icon(
                //                 Icons.camera_alt_outlined,
                //                 size: 36.sp,
                //                 color: AppColors.greyColor,
                //               ),
                //               SizedBox(height: 8.h),
                //               Text(
                //                 'no_image'.tr(),
                //                 style: AppText.body14(
                //                   context,
                //                 ).copyWith(color: Colors.grey),
                //               ),
                //             ],
                //           ),
                //         ),
                // ),

                // SizedBox(height: 16.h),

                // Row(
                //   children: [
                //     Expanded(
                //       child: ElevatedButton(
                //         onPressed: (_image == null || _loading)
                //             ? null
                //             : _processImage,
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: AppColors.colorButton,
                //           padding: EdgeInsets.symmetric(vertical: 14.h),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(12.r),
                //           ),
                //         ),
                //         child: _loading
                //             ? SizedBox(
                //                 height: 18.h,
                //                 width: 18.w,
                //                 child: CircularProgressIndicator(
                //                   color: Colors.white,
                //                   strokeWidth: 2,
                //                 ),
                //               )
                //             : Text(
                //                 'extract_text'.tr(),
                //                 style: AppText.body16(
                //                   context,
                //                 ).copyWith(color: Colors.white),
                //               ),
                //       ),
                //     ),
                //     SizedBox(width: 12.w),
                //     IconButton(
                //       onPressed: () {
                //         if (_textController.text.isNotEmpty) {
                //           _textController.clear();
                //           setState(() {
                //             _extracted = '';
                //           });
                //         }
                //       },
                //       icon: Icon(Icons.clear, color: AppColors.greyColor),
                //     ),
                //   ],
                // ),

                // SizedBox(height: 12.h),

                // Expanded(
                //   child: Container(
                //     padding: EdgeInsets.all(12.w),
                //     decoration: BoxDecoration(
                //       color: cardColor,
                //       borderRadius: BorderRadius.circular(12.r),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           'extracted_text'.tr(),
                //           style: AppText.body14(
                //             context,
                //           ).copyWith(fontWeight: FontWeight.w700),
                //         ),
                //         SizedBox(height: 8.h),
                //         Expanded(
                //           child: TextField(
                //             controller: _textController,
                //             maxLines: null,
                //             expands: true,
                //             decoration: InputDecoration.collapsed(
                //               hintText: 'no_text'.tr(),
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                // SizedBox(height: 12.h),

                // Container(
                //   padding: EdgeInsets.all(12.w),
                //   decoration: BoxDecoration(
                //     color: cardColor,
                //     borderRadius: BorderRadius.circular(12.r),
                //   ),
                //   child: Column(
                //     children: [
                //       Row(
                //         children: [
                //           Expanded(
                //             child: TextFormField(
                //               controller: _titleController,
                //               decoration: InputDecoration(
                //                 labelText: 'title'.tr(),
                //               ),
                //             ),
                //           ),
                //           SizedBox(width: 12.w),
                //           SizedBox(
                //             width: 120.w,
                //             child: TextFormField(
                //               controller: _amountController,
                //               keyboardType: TextInputType.numberWithOptions(
                //                 decimal: true,
                //               ),
                //               decoration: InputDecoration(
                //                 labelText: 'amount'.tr(),
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //       SizedBox(height: 12.h),
                //       Row(
                //         children: [
                //           Expanded(
                //             child: GestureDetector(
                //               onTap: _pickDate,
                //               child: Row(
                //                 children: [
                //                   Icon(
                //                     Icons.calendar_today,
                //                     color: AppColors.greenColor,
                //                   ),
                //                   SizedBox(width: 8.w),
                //                   Text(
                //                     DateFormat(
                //                       'yyyy-MM-dd',
                //                     ).format(_selectedDate),
                //                     style: AppText.body14(context),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //           SizedBox(width: 12.w),
                //           DropdownButton<String>(
                //             value: _category,
                //             items: const [
                //               DropdownMenuItem(
                //                 value: 'food',
                //                 child: Text('Food'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'transport',
                //                 child: Text('Transport'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'rent',
                //                 child: Text('Rent'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'more',
                //                 child: Text('Other'),
                //               ),
                //             ],
                //             onChanged: (v) =>
                //                 setState(() => _category = v ?? 'more'),
                //           ),
                //           SizedBox(width: 8.w),
                //           Switch(
                //             value: _isExpense,
                //             onChanged: (v) => setState(() => _isExpense = v),
                //             activeColor: AppColors.greenColor,
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),

                // SizedBox(height: 12.h),

                // SizedBox(
                //   height: 52.h,
                //   child: ElevatedButton(
                //     onPressed: (_amountController.text.trim().isEmpty)
                //         ? null
                //         : _saveParsedTransaction,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.greenColor,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12.r),
                //       ),
                //     ),
                //     child: Text(
                //       'create_transaction'.tr(),
                //       style: AppText.body16(
                //         context,
                //       ).copyWith(color: Colors.white),
                //     ),
                //   ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
