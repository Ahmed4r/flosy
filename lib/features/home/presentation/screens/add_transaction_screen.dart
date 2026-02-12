import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- add

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TextEditingController amountController;
  late TextEditingController noteController;

  String selectedCategory = '';
  bool isExpense = true;
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'food',
      'icon': FontAwesomeIcons.burger,
      'labelKey': 'categories.food',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'rent',
      'icon': FontAwesomeIcons.house,
      'labelKey': 'categories.rent',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'transport',
      'icon': FontAwesomeIcons.car,
      'labelKey': 'categories.transport',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'shopping',
      'icon': FontAwesomeIcons.shoppingBag,
      'labelKey': 'categories.shopping',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'fun',
      'icon': FontAwesomeIcons.film,
      'labelKey': 'categories.fun',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'health',
      'icon': FontAwesomeIcons.heartPulse,
      'labelKey': 'categories.health',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'salary',
      'icon': Icons.attach_money,
      'labelKey': 'categories.salary',
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'more',
      'icon': Icons.more_horiz,
      'labelKey': 'categories.more',
      'color': const Color(0xFF88B0D3),
    },
  ];

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    noteController = TextEditingController();

    // Prefill when editing
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      isExpense = tx.type == TransactionType.expense;
      selectedCategory = tx.category;
      selectedDate = tx.date;
      amountController.text = tx.amount.toStringAsFixed(2);
      noteController.text = tx.title;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF1F1F1F)
        : Colors.grey[50] ?? Colors.white;
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF2A2A2A)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color _getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400] ?? Colors.grey
        : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        surfaceTintColor: _getCardColor(context),
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'transaction.add_transaction'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              amountController.clear();
              noteController.clear();
              setState(() {
                isExpense = true;
                selectedCategory = ''; // not 'Food'
                selectedDate = DateTime.now();
              });
            },
            child: Text(
              'transaction.reset'.tr(),
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTransactionTypeToggle(),
              SizedBox(height: 15.h),
              buildAmountDisplay(),
              SizedBox(height: 15.h),
              buildCategorySection(),
              SizedBox(height: 15.h),
              buildDateSection(isDarkMode),
              SizedBox(height: 15.h),
              buildNoteSection(isDarkMode),
              SizedBox(height: 20.h),
              buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTransactionTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isExpense = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isExpense ? Color(0xFFFF6B6B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    'transaction.expense'.tr(),
                    style: AppText.body14(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isExpense ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isExpense = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: !isExpense ? Color(0xFFE8EEFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    'transaction.income'.tr(),
                    style: AppText.body14(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: !isExpense ? Color(0xFF5B5BFF) : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAmountDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: _getIconColor(context),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextFormField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  fontSize: 50.sp,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
                decoration: InputDecoration(
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontSize: 48.sp,
                    color: _getIconColor(context).withOpacity(0.4),
                  ),
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'transaction.please_enter_amount'.tr();
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'transaction.category'.tr(),
              style: AppText.body16(context).copyWith(
                fontWeight: FontWeight.bold,
                color: _getTextColor(context),
              ),
            ),
            Text(
              'transaction.see_all'.tr(),
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected =
                selectedCategory == category['id']; // <-- compare by id

            return GestureDetector(
              onTap: () => setState(() => selectedCategory = category['id']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A2E)
                            : const Color.fromARGB(255, 2, 2, 26))
                      : _getCardColor(context),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected ? Colors.white : category['color'],
                      size: 28.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      (category['labelKey'] as String).tr(),
                      style: AppText.body12(context).copyWith(
                        color: isSelected
                            ? Colors.white
                            : _getTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildDateSection(bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: BorderRadius.circular(12.r),
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
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black45 : Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: FaIcon(
                FontAwesomeIcons.calendar,
                color: _getIconColor(context),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'transaction.date'.tr(),
                  style: AppText.body12grey(context),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  style: AppText.body16(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(context),
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: _getIconColor(context),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoteSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(12.r),
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black45 : Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: FaIcon(
                  FontAwesomeIcons.stickyNote,
                  color: _getIconColor(context),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transaction.note'.tr(),
                      style: AppText.body14(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: noteController,
                      style: AppText.body14(
                        context,
                      ).copyWith(color: _getTextColor(context)),
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        hintText: 'transaction.what_is_this_for'.tr(),
                        hintStyle: AppText.body14(
                          context,
                        ).copyWith(color: _getIconColor(context)),
                      ),
                      maxLines: expandedText(),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int expandedText() {
    if (noteController.text.length > 40) {
      return 3;
    } else {
      return 1;
    }
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: () async {
          if (amountController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('transaction.please_enter_amount'.tr())),
            );
            return;
          }

          final amount = double.tryParse(amountController.text);
          if (amount == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('transaction.invalid_amount'.tr())),
            );
            return;
          }

          final category = categories.firstWhere(
            (c) => c['id'] == selectedCategory,
          );
          final iconData = category['icon'] as IconData;

          final tx = TransactionModel(
            id: widget.transaction?.id,
            title: noteController.text.isNotEmpty
                ? noteController.text
                : (category['labelKey'] as String).tr(),
            amount: amount,
            type: isExpense ? TransactionType.expense : TransactionType.income,
            date: selectedDate,
            category: selectedCategory,
            iconCodePoint: iconData.codePoint,
            iconFontFamily: iconData.fontFamily ?? 'MaterialIcons',
            iconFontPackage:
                iconData.fontPackage, // <-- store package for FontAwesome
          );

          // Save to DB
          if (widget.transaction == null) {
            await dbService.addTransaction(tx);
          } else {
            await dbService.updateTransaction(tx);
          }

          // Update total balance in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          double current = prefs.getDouble('total_balance') ?? 0.0;

          // effect of new transaction
          final newDelta =
              tx.amount * (tx.type == TransactionType.expense ? -1.0 : 1.0);

          if (widget.transaction == null) {
            // new transaction: just apply its effect
            current += newDelta;
          } else {
            // editing: remove old effect, apply new one
            final old = widget.transaction!;
            final oldDelta =
                old.amount * (old.type == TransactionType.expense ? -1.0 : 1.0);
            current = current - oldDelta + newDelta;
          }

          await prefs.setDouble('total_balance', current);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('transaction.transaction_saved'.tr()),
              backgroundColor: Colors.green,
            ),
          );

          // return `true` so HomeScreen knows to refresh
          Navigator.pop(context, true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, color: Colors.black),
            SizedBox(width: 8.w),
            Text(
              'transaction.save_transaction'.tr(),
              style: AppText.body16(
                context,
              ).copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
