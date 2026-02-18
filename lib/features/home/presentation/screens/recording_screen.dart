import 'dart:io';
import 'package:flosy/features/home/presentation/services/gemini_service.dart';
import 'package:flosy/features/home/presentation/widgets/audio_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // سطر الاستيراد المفقود
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordingPage extends StatefulWidget {
  final String? sessionId;
  const RecordingPage({super.key, this.sessionId});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AIExtractionService _groqService = AIExtractionService();
  bool _isRecording = false;
  bool _isLoading = false;
  String? _actualPath;

  @override
  void initState() {
    super.initState();
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    // 1. طلب الصلاحية منطقياً
    await Permission.microphone.request();
    // 2. فتح المسجل
    await _recorder.openRecorder();
    // 3. بدء التسجيل الفعلي في مسار حقيقي
    final tempDir = await getTemporaryDirectory();
    _actualPath = '${tempDir.path}/temp_voice.m4a';

    await _recorder.startRecorder(toFile: _actualPath, codec: Codec.aacMP4);
    setState(() => _isRecording = true);
  }

  Future<void> _stopAndSave() async {
    final shouldSave = await _confirmStopRecording();

    if (shouldSave && _actualPath != null) {
      setState(() {
        _isRecording = false; // نوقف الأنميشن فوراً
        _isLoading = true; // نشغل علامة التحميل
      });

      try {
        // أهم خطوة: اقفل المسجل واستنى لحظة عشان الملف يتحفظ على الموبايل
        await _recorder.stopRecorder();
        await Future.delayed(const Duration(milliseconds: 500));

        if (!await File(_actualPath!).exists()) {
          throw Exception("الملف مسمعش في الذاكرة");
        }

        // نبعت المسار للخدمة اللي عملناها فوق
        final transaction = await _groqService.extractDataFromAudio(
          _actualPath!,
        );

        if (mounted) {
          if (transaction != null) {
            Navigator.pop(context, transaction); // ارجع بالسلامة ومعاك البيانات
          } else {
            setState(() => _isLoading = false);
            _showErrorSnackBar(
              "مفهمتش.. قول مثلاً: صرفت 200 جنيه في السوبر ماركت",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar("حصلت مشكلة تقنية: $e");
        }
      }
    } else {
      await _recorder.stopRecorder();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool> _confirmStopRecording() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حفظ وتسجيل؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('نعم'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? "Gemini is analyzing..." : "Recording"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AudioWave(isRecording: _isRecording && !_isLoading),
            if (_isLoading) const CircularProgressIndicator(),
            SizedBox(height: 50.h),
            FloatingActionButton(
              onPressed: _isLoading ? null : _stopAndSave,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            ),
          ],
        ),
      ),
    );
  }
}
