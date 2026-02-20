import 'dart:io';
import 'dart:math';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/presentation/services/groq_service.dart';
import 'package:flosy/features/home/presentation/widgets/audio_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordingPage extends StatefulWidget {
  final String? sessionId;
  const RecordingPage({super.key, this.sessionId});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage>
    with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AIExtractionService _groqService = AIExtractionService();

  bool _isRecording = false;
  bool _isLoading = false;
  bool _isDisposing = false; // منع استدعاء stopRecorder مرتين
  String? _actualPath;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  // Recording timer
  int _secondsElapsed = 0;
  late AnimationController _timerController;

  // Hints to show user
  final List<String> _hints = [
    'قول مثلاً: "صرفت 50 جنيه في الاكل"',
    'مثال: "اشتريت هدوم بـ 300"',
    'مثال: "استلمت مرتب 5000"',
    'مثال: "دفعت فاتورة الكهربا 200"',
    'مثال: "رحت سينما بـ 150"',
  ];
  int _currentHint = 0;
  late AnimationController _hintController;
  late Animation<double> _hintOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initAndStart();
  }

  void _setupAnimations() {
    // Pulse animation for mic button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Loading spinner
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Timer controller (every second)
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _isRecording) {
              setState(() => _secondsElapsed++);
              _timerController.forward(from: 0);
            }
          });

    // Hint rotation
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
    _hintController.forward();

    // Rotate hints every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      await _hintController.reverse();
      if (!mounted) return false;
      setState(() {
        _currentHint = (_currentHint + 1) % _hints.length;
      });
      _hintController.forward();
      return mounted && !_isLoading;
    });
  }

  Future<void> _initAndStart() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        _showErrorSnackBar('تحتاج إذن الميكروفون للتسجيل');
        Navigator.pop(context);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    await _recorder.openRecorder();

    final tempDir = await getTemporaryDirectory();
    _actualPath = '${tempDir.path}/temp_voice.wav';

    await _recorder.startRecorder(
      toFile: _actualPath,
      codec: Codec.pcm16WAV,
      sampleRate: 44100,
      numChannels: 1,
    );

    if (mounted) {
      setState(() => _isRecording = true);
      _timerController.forward();
    }
  }

  Future<void> _stopAndSave(isDarkMode) async {
    final shouldSave = await _confirmStopRecording(isDarkMode);

    if (shouldSave && _actualPath != null) {
      setState(() {
        _isRecording = false;
        _isLoading = true;
      });
      _pulseController.stop();
      _rippleController.stop();
      _timerController.stop();

      try {
        await _recorder.stopRecorder();
        await Future.delayed(const Duration(milliseconds: 500));

        if (!await File(_actualPath!).exists()) {
          throw Exception('الملف مش موجود');
        }

        final transaction = await _groqService.extractDataFromAudio(
          _actualPath!,
        );

        if (mounted) {
          if (transaction != null) {
            Navigator.pop(context, transaction);
          } else {
            setState(() => _isLoading = false);
            _isRecording = true;
            _pulseController.repeat(reverse: true);
            _rippleController.repeat();
            _showErrorSnackBar('مفهمتش.. جرب تاني');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('حصلت مشكلة: $e');
        }
      }
    } else {
      await _recorder.stopRecorder();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  Future<bool> _confirmStopRecording(isDarkMode) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildConfirmSheet(isDarkMode),
        ) ??
        false;
  }

  Widget _buildConfirmSheet(isDarkMode) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 26, 22, 23),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 157, 219, 134).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic_none_outlined, color: Colors.white, size: 28),
          ),
          SizedBox(height: 16.h),
          Text(
            'تحليل التسجيل؟',
            style: TextStyle(
              color: isDarkMode ? Colors.black : Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'هيتم تحليل كلامك واستخراج بيانات العملية',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      'إلغاء',
                      textAlign: TextAlign.center,
                      style: AppText.body15(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 53, 207, 53),
                          Color.fromARGB(255, 10, 81, 28),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            167,
                            233,
                            177,
                          ).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'تحليل ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _safeStop() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      if (_recorder.isRecording) await _recorder.stopRecorder();
      await _recorder.closeRecorder();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _loadingController.dispose();
    _timerController.dispose();
    _hintController.dispose();
    _safeStop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background gradient circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300.w,
                height: 300.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color.fromARGB(255, 36, 146, 67).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color.fromARGB(255, 12, 30, 2).withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await _safeStop();
                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,

                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Text(
                          _isLoading ? 'جاري التحليل...' : 'تسجيل صوتي',
                          textAlign: TextAlign.center,
                          style: AppText.body16(context).copyWith(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(width: 40.w), // balance
                      ],
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status badge
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _isLoading
                            ? _buildLoadingBadge(isDarkMode)
                            : _buildRecordingBadge(),
                      ),

                      SizedBox(height: 48.h),

                      // Main mic button with ripples
                      _buildMicButton(),

                      SizedBox(height: 32.h),

                      // Timer
                      AnimatedOpacity(
                        opacity: _isRecording ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _formatTime(_secondsElapsed),
                          style: AppText.body28(context).copyWith(
                            fontWeight: FontWeight.w200,
                            letterSpacing: 4,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Audio wave
                      if (_isRecording && !_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: AudioWave(isRecording: _isRecording),
                        ),

                      SizedBox(height: 48.h),

                      // Hint text
                      if (!_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: FadeTransition(
                            opacity: _hintOpacity,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color.fromARGB(
                                        255,
                                        118,
                                        34,
                                        34,
                                      ).withOpacity(0.05)
                                    : const Color.fromARGB(
                                        255,
                                        39,
                                        26,
                                        26,
                                      ).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '💡 ',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _hints[_currentHint],
                                      style: AppText.body15(context).copyWith(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Stop button
                  if (!_isLoading)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: 48.h,
                        left: 40.w,
                        right: 40.w,
                      ),
                      child: GestureDetector(
                        onTap: () => _stopAndSave(isDarkMode),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 37, 167, 61),
                                Color.fromARGB(255, 4, 76, 7),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  48,
                                  165,
                                  100,
                                ).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stop_rounded, size: 22),
                              SizedBox(width: 10.w),
                              Text(
                                'إيقاف وتحليل',
                                style: AppText.body16(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return Container(
      key: const ValueKey('recording'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'يسجل الآن',
            style: TextStyle(
              color: const Color(0xFFE53935),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBadge(isDarkMode) {
    return Container(
      key: const ValueKey('loading'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 95, 229, 95).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color.fromARGB(255, 43, 131, 46).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14.w,
            height: 14.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'AI بيحلل كلامك...',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return SizedBox(
      width: 200.w,
      height: 200.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          if (_isRecording && !_isLoading)
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _rippleController,
                builder: (context, _) {
                  final delay = i * 0.33;
                  final progress = (_rippleAnimation.value + delay) % 1.0;
                  return Opacity(
                    opacity: (1 - progress) * 0.4,
                    child: Container(
                      width: 100.w + (progress * 100.w),
                      height: 100.w + (progress * 100.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE53935),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // Main button
          AnimatedBuilder(
            animation: _isRecording && !_isLoading
                ? _pulseAnimation
                : kAlwaysCompleteAnimation,
            builder: (context, child) {
              final scale = _isRecording && !_isLoading
                  ? _pulseAnimation.value
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [
                              const Color.fromARGB(255, 112, 211, 88),
                              const Color.fromARGB(255, 7, 133, 47),
                            ]
                          : [const Color(0xFFE53935), const Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isLoading
                                    ? const Color.fromARGB(255, 44, 182, 34)
                                    : const Color(0xFFE53935))
                                .withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? RotationTransition(
                          turns: _loadingController,
                          child: Icon(Icons.auto_awesome, size: 36.sp),
                        )
                      : Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 42.sp,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
