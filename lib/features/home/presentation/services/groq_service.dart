import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // تأكد من وجود هذا الـ import لـ MediaType
import '../../data/model/transaction_model.dart';
import 'db.dart';

class AIExtractionService {
    final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  final List<Map<String, dynamic>> availableCategories = [
    {
      'id': 'food',
      'icon': FontAwesomeIcons.burger,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'rent',
      'icon': FontAwesomeIcons.house,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'transport',
      'icon': FontAwesomeIcons.car,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'shopping',
      'icon': FontAwesomeIcons.bagShopping,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'fun',
      'icon': FontAwesomeIcons.film,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'health',
      'icon': FontAwesomeIcons.heartPulse,
      'color': const Color(0xFF88B0D3),
    },
    {
      'id': 'salary',
      'icon': Icons.attach_money,
      'color': const Color(0xFF88B0D3),
    },
    {'id': 'more', 'icon': Icons.more_horiz, 'color': const Color(0xFF88B0D3)},
  ];

  Future<TransactionModel?> extractDataFromAudio(String filePath) async {
    try {
      log("🚀 بدأت المعالجة للملف: $filePath");

      // 1. Whisper API (تحويل الصوت لنص)
      var whisperRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      whisperRequest.headers['Authorization'] = 'Bearer $apiKey';
      whisperRequest.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType(
            'audio',
            filePath.endsWith('.wav') ? 'wav' : 'm4a',
          ),
        ),
      );
      whisperRequest.fields['model'] = 'whisper-large-v3';

      var whisperResponse = await http.Response.fromStream(
        await whisperRequest.send(),
      );
      if (whisperResponse.statusCode != 200) return null;

      var transcription = jsonDecode(whisperResponse.body)['text'];
      log("📝 النص المسموع: $transcription");

      // 2. التحليل بواسطة Llama
      // قمنا بتجميع الـ IDs المسموحة لإرسالها في البرومبت
      String allowedIds = availableCategories.map((e) => e['id']).join(', ');

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
                  """
                Extract transaction data. Return ONLY JSON.
                - 'title': Short summary in the SAME language/dialect used by the user.
                - 'category': Must be exactly one of these: [$allowedIds].
                - 'type': 0 for income, 1 for expense.
                - 'amount': double.
              """,
            },
            {"role": "user", "content": transcription},
          ],
          "response_format": {"type": "json_object"},
        }),
      );

      if (llamaResponse.statusCode != 200) return null;

      // فك الـ JSON المستخرج من Llama
      final Map<String, dynamic> content = jsonDecode(
        jsonDecode(llamaResponse.body)['choices'][0]['message']['content'],
      );

      log("📦 الـ JSON المستخرج: $content");

      // 3. مطابقة البيانات (المنطق البرمجي للأيقونة واللون)
      String categoryId =
          content['category']?.toString().toLowerCase().trim() ?? 'more';

      // البحث عن البيانات الكاملة للتصنيف لضمان مطابقة الأيقونة واللون
      final categoryData = availableCategories.firstWhere(
        (element) => element['id'] == categoryId,
        orElse: () => availableCategories.last, // 'more'
      );

      final IconData displayIcon = categoryData['icon'];

      // 4. بناء الـ Model
      final transaction = TransactionModel(
        title: content['title'] ?? transcription,
        amount: (content['amount'] as num).toDouble(),
        type: TransactionType.values[content['type'] ?? 1],
        date: DateTime.now(),
        category: categoryId, // سيطابق الآن TransactionColors.name في الـ Tile
        iconCodePoint: displayIcon.codePoint,
        iconFontFamily: displayIcon.fontFamily ?? "MaterialIcons",
        iconFontPackage: displayIcon.fontPackage,
      );

      await dbService.addTransaction(transaction);
      log("✅ تم الحفظ بنجاح بتصنيف: $categoryId");
      return transaction;
    } catch (e) {
      log("⚠️ عطل فني: $e");
      return null;
    }
  }
}
