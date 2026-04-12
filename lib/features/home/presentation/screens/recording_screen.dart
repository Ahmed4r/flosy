import 'dart:developer';
import 'dart:io';
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
    final statusBefore = await Permission.microphone.status;
    log('Mic permission before request: $statusBefore');

    var status = statusBefore;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      log('Mic permission after request: $status');
    }

    // Handle permission denial
    if (!status.isGranted) {
      // On iOS: after first denial, status is 'denied' (not permanentlyDenied)
      // On Android: after multiple denials or "don't ask again", it's permanentlyDenied
      if (status.isPermanentlyDenied || status.isDenied) {
        _showErrorSnackBar(
          'تحتاج إذن الميكروفون للتسجيل — رجاءً فعّله من الإعدادات',
        );
        // Give user a moment to read the message before opening settings
        await Future.delayed(const Duration(milliseconds: 500));
        openAppSettings();
      } else {
        _showErrorSnackBar('تحتاج إذن الميكروفون للتسجيل');
      }
      if (!mounted) return;

      Navigator.pop(context);
      return;
    }

    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
    } catch (e) {
      log('Recorder init error: $e');
      _showErrorSnackBar('فشل تهيئة الميكروفون: $e');
      if (!mounted) return;

      Navigator.pop(context);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    _actualPath = '${tempDir.path}/temp_voice.wav';

    try {
      await _recorder.startRecorder(
        toFile: _actualPath,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        numChannels: 1,
      );
    } catch (e) {
      log('startRecorder error: $e');
      _showErrorSnackBar('فشل بدء التسجيل: $e');
      await _recorder.closeRecorder();
      if (!mounted) return;

      Navigator.pop(context);
      return;
    }

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

        final recordedFile = File(_actualPath!);
        if (!await recordedFile.exists()) {
          throw Exception('الملف مش موجود بعد الإيقاف');
        }

        final len = await recordedFile.length();
        log('Recorded file size: $len');
        if (len < 400) {
          setState(() {
            _isLoading = false;
            _isRecording = true;
            _pulseController.repeat(reverse: true);
            _rippleController.repeat();
          });
          _showErrorSnackBar('الصوت قصير جدًا أو غير واضح — جرب مرة تانية');
          return;
        }

        // إذا الدالة في الخدمة رمت استثناء، سيتم التقاطه في الـ catch هنا
        final transaction = await _groqService.extractDataFromAudio(
          _actualPath!,
        );

        if (mounted) {
          if (transaction != null) {
            // عرض SnackBar نجاح ثم الرجوع بالنتيجة بعد تأخير بسيط
            _showSuccessSnackBar(
              'تمت الإضافة: ${transaction.title} — ${transaction.amount.toStringAsFixed(0)}',
            );
            await Future.delayed(const Duration(milliseconds: 700));
            if (!mounted) return;
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
          final errText = e.toString();
          _showErrorSnackBar('حصلت مشكلة: $errText');
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
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: isDarkMode
                ? const Color.fromARGB(255, 31, 41, 31)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'إيقاف التسجيل؟',
              style: AppText.head20(
                context,
              ).copyWith(color: isDarkMode ? Colors.white : Colors.black),
              textAlign: TextAlign.right,
            ),
            content: Text(
              'هتوقف التسجيل وترسل الصوت للـ AI عشان يحلله؟',
              style: AppText.body14(context).copyWith(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'إلغاء',
                  style: AppText.body14(context).copyWith(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 37, 167, 61),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تأكيد',
                  style: AppText.body14(context).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF43A047), // أخضر
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  void dispose() {
    if (!_isDisposing) {
      _isDisposing = true;
      _recorder.closeRecorder();
      _pulseController.dispose();
      _rippleController.dispose();
      _loadingController.dispose();
      _timerController.dispose();
      _hintController.dispose();
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Start recording as soon as the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isRecording && !_isLoading && !_isDisposing) {
        _initAndStart();
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_isRecording && !_isLoading) {
          await _recorder.stopRecorder();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 18, 18, 18)
            : const Color(0xFFF5F9F6),
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Gradient background circles
              Positioned(
                top: -150.h,
                right: -100.w,
                child: Container(
                  width: 400.w,
                  height: 400.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDarkMode
                                ? const Color.fromARGB(255, 48, 165, 100)
                                : const Color.fromARGB(255, 112, 211, 88))
                            .withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150.h,
                left: -100.w,
                child: Container(
                  width: 350.w,
                  height: 350.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  // AppBar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 30.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (_isRecording && !_isLoading) {
                              await _recorder.stopRecorder();
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDarkMode ? Colors.white : Colors.black,
                            size: 26.sp,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _isLoading
                              ? _buildLoadingBadge(isDarkMode)
                              : (_isRecording
                                    ? _buildRecordingBadge()
                                    : const SizedBox.shrink()),
                        ),
                        SizedBox(width: 48.w), // Balance the layout
                      ],
                    ),
                  ),

                  // Timer
                  if (_isRecording && !_isLoading)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (value * 0.2),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                _formatTime(_secondsElapsed),
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  SizedBox(height: 40.h),

                  // Mic button
                  _buildMicButton(),

                  SizedBox(height: 40.h),

                  // Audio wave
                  if (_isRecording && !_isLoading)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (value * 0.2),
                            child: AudioWave(isRecording: _isRecording),
                          ),
                        );
                      },
                    ),

                  // Hints
                  if (!_isLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(_currentHint),
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: const Color.fromARGB(255, 37, 167, 61),
                                size: 28.sp,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                _hints[_currentHint],
                                style: AppText.body14(context).copyWith(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
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
            ],
          ),
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
