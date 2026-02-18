import 'dart:convert';
import 'dart:developer';

import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart'; // مهم للأيقونات
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // لإضافة MediaType
import 'package:flosy/features/home/data/model/transaction_model.dart';

class AIExtractionService {
  final String apiKey =
      "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";

  Future<TransactionModel?> extractDataFromAudio(String filePath) async {
    try {
      print("🚀 بدأت المعالجة للملف: $filePath");

      // 1. تحويل الصوت لنص (Whisper)
      var whisperRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      whisperRequest.headers['Authorization'] = 'Bearer $apiKey';
      whisperRequest.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          // المنطق بيقول لو سجلنا wav نبعته wav ولو m4a نبعته m4a
          contentType: MediaType(
            'audio',
            filePath.endsWith('.wav') ? 'wav' : 'm4a',
          ),
        ),
      );
      whisperRequest.fields['model'] = 'whisper-large-v3';

      var whisperStream = await whisperRequest.send();
      var whisperResponse = await http.Response.fromStream(whisperStream);

      if (whisperResponse.statusCode != 200) {
        log("❌ خطأ في Whisper: ${whisperResponse.body}");
        return null;
      }

      var transcription = jsonDecode(whisperResponse.body)['text'];
      log("📝 الكلام اللي اتسمع: $transcription");

      // 2. تحليل النص (Llama 3.3)
      var llamaResponse = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content":
                  "Extract transaction data. Return ONLY JSON: {'title': String, 'amount': double, 'type': 0 for income/1 for expense, 'category': String}",
            },
            {"role": "user", "content": transcription},
          ],
          "response_format": {"type": "json_object"},
        }),
      );

      if (llamaResponse.statusCode != 200) {
        log("❌ خطأ في Llama: ${llamaResponse.body}");
        return null;
      }

      // --- الجزء الحساس: معالجة البيانات القادمة من Llama ---
      var llamaData = jsonDecode(llamaResponse.body);
      String rawJson = llamaData['choices'][0]['message']['content'];
      Map<String, dynamic> content = jsonDecode(
        rawJson,
      ); // فك الـ JSON مرة واحدة بس

      log("📦 الـ JSON المستخرج: $content");

      // 3. اختيار الأيقونة بناءً على النوع (Logic)
      IconData displayIcon = _getIconForCategory(content['category']);

      // 4. إنشاء الـ Model
      final transaction = TransactionModel(
        title: content['title'] ?? "معاملة صوتية",
        amount: (content['amount'] as num).toDouble(),
        type: TransactionType.values[content['type'] ?? 1],
        date: DateTime.now(),
        category: content['category'] ?? "عام",
        iconCodePoint: displayIcon.codePoint,
        iconFontFamily: displayIcon.fontFamily ?? 'MaterialIcons',
        iconFontPackage: displayIcon.fontPackage,
      );

      // 5. الحفظ في قاعدة البيانات تلقائياً
      await dbService.addTransaction(transaction);
      log("✅ تم الحفظ في قاعدة البيانات بنجاح");

      return transaction;
    } catch (e) {
      log("⚠️ عطل فني نهائي: $e");
      return null;
    }
  }

  // دالة مساعدة لتحديد الأيقونة
  IconData _getIconForCategory(String? category) {
    String cat = (category ?? "").toLowerCase();
    if (cat.contains('أكل') || cat.contains('food')) return Icons.restaurant;
    if (cat.contains('سوبر') || cat.contains('shop'))
      return Icons.shopping_cart;
    if (cat.contains('مواصلات') || cat.contains('transport'))
      return Icons.directions_car;
    if (cat.contains('راتب') || cat.contains('salary')) return Icons.payments;
    return Icons.receipt_long; // افتراضية
  }
}
