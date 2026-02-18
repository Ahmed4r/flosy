// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class RecordingCubit extends Cubit<bool> {
//   RecordingCubit() : super(false) {
//     _initPlayer(); // التأكد من تشغيل التهيئة فوراً
//   }

//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   String? _filePath;
//   FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
//   bool _mPlayerIsInited = false;
//   Future<void> _initPlayer() async {
//     try {
//       // هذا السطر هو المفتاح لحل المشكلة
//       await _mPlayer?.openPlayer();
//       _mPlayerIsInited = true;
//       log("Player initialized successfully");
//     } catch (e) {
//       log("Player initialization failed: $e");
//     }
//   }

//   Future<void> startRecording() async {
//     // 1. طلب الصلاحية برمجياً (منطقياً لا يمكن البدء بدونها)
//     var status = await Permission.microphone.request();
//     if (status != PermissionStatus.granted) {
//       throw Exception("Microphone permission denied");
//     }

//     // 2. فتح الجلسة وتحديد المسار
//     await _recorder.openRecorder();
//     Directory tempDir = await getTemporaryDirectory();
//     _filePath =
//         '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';

//     // 3. بدء التسجيل
//     await _recorder.startRecorder(toFile: _filePath, codec: Codec.aacADTS);
//     emit(true); // تحديث الحالة إلى "جاري التسجيل"
//   }

//   Future<String?> stopRecording() async {
//     await _recorder.stopRecorder();
//     await _recorder.closeRecorder();
//     emit(false); // تحديث الحالة إلى "توقف التسجيل"
//     return _filePath;
//   }

//   // أضف هذه الدالة أو حدث الموجودة في RecordingCubit
//   Future<void> playSpecificFile(String path) async {
//     if (!_mPlayerIsInited) {
//       await _mPlayer?.openPlayer();
//       _mPlayerIsInited = true;
//     }

//     try {
//       await _mPlayer?.startPlayer(
//         fromURI: path,
//         codec: Codec.aacADTS,
//         whenFinished: () {
//           log("Finished playing: $path");
//         },
//       );
//     } catch (e) {
//       log("Error playing specific file: $e");
//     }
//   }

//   Future<void> openRecordFile() async {
//     if (_filePath != null) {
//       final file = File(_filePath!);
//       if (await file.exists()) {
//         // يمكنك هنا فتح الملف باستخدام أي مكتبة لعرض الصوت أو تشغيله
//         log("File path: $_filePath");
//         playSpecificFile(_filePath!); // تشغيل الملف للتأكد من أنه يعمل
//       } else {
//         log("File does not exist");
//       }
//     } else {
//       log("No recording found");
//     }
//   }

//   Future<void> stopPlayer() async {
//     if (_mPlayer != null) {
//       await _mPlayer!.stopPlayer();
//     }
//   }

//   @override
//   Future<void> close() {
//     _recorder.closeRecorder();
//     _mPlayer?.closePlayer();
//     return super.close();
//   }
// }
