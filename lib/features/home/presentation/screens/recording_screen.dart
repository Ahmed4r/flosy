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

// import 'package:audio_session/audio_session.dart';

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
  bool _isDisposing = false;
  String? _actualPath;

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  int _secondsElapsed = 0;
  late AnimationController _timerController;

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

  // 🎨 الألوان الأساسية
  static const Color primaryGreen = Color.fromARGB(255, 37, 167, 61);
  static const Color darkGreenDeep = Color.fromARGB(255, 4, 76, 7);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _isRecording) {
              setState(() => _secondsElapsed++);
              _timerController.forward(from: 0);
            }
          });

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
    _hintController.forward();

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

    if (!status.isGranted) {
      if (status.isPermanentlyDenied || status.isDenied) {
        _showErrorSnackBar(
          'تحتاج إذن الميكروفون للتسجيل — رجاءً فعّله من الإعدادات',
        );
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
      // final session = await AudioSession.instance;
      // await session.configure(...);

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

  Future<void> _stopAndSave(bool isDarkMode) async {
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
        if (len <= 44) {
          throw Exception('الصوت قصير جداً أو فيه مشكلة في المايك');
        }

        final transaction = await _groqService.extractDataFromAudio(
          _actualPath!,
        );

        if (mounted) {
          if (transaction != null) {
            _showSuccessSnackBar(
              'تمت الإضافة: ${transaction.title} — ${transaction.amount.toStringAsFixed(0)}',
            );
            await Future.delayed(const Duration(milliseconds: 700));
            if (!mounted) return;
            Navigator.pop(context, transaction);
          } else {
            throw Exception('مفهمتش كلامك.. جرب تقولها بطريقة تانية');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _secondsElapsed = 0;
          });

          final errText = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('AIExtractionService error: ', '');

          _showErrorSnackBar(errText);

          if (_isRecording) {
            await _recorder.stopRecorder();
          }
          Navigator.pop(context);
        }
      }
    } else {
      await _recorder.stopRecorder();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _confirmStopRecording(isDarkMode) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? const [
                          Color(0xFF1A2E1A),
                          Color(0xFF0D1F1A),
                          Color(0xFF162A22),
                        ]
                      : const [
                          Color.fromARGB(255, 226, 244, 202),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stop_circle_rounded,
                      color: primaryGreen,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'إيقاف التسجيل؟',
                    style: AppText.head20(context).copyWith(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'هتوقف التسجيل وترسل الصوت للـ AI عشان يحلله',
                    style: AppText.body14(context).copyWith(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.65)
                          : Colors.black.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.15),
                              ),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: AppText.body14(context).copyWith(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            'تأكيد',
                            style: AppText.body14(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        backgroundColor: const Color(0xFF43A047),
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? const [
                      Color(0xFF1A2E1A),
                      Color(0xFF0D1F1A),
                      Color(0xFF162A22),
                    ]
                  : const [
                      Color.fromARGB(255, 226, 244, 202),
                      Color(0xFFF5F9F6),
                      Colors.white,
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundIconButton(
                        icon: Icons.close_rounded,
                        isDarkMode: isDarkMode,
                        onTap: () async {
                          if (_isRecording && !_isLoading) {
                            await _recorder.stopRecorder();
                          }
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: _isLoading
                            ? _buildLoadingBadge(isDarkMode)
                            : (_isRecording
                                  ? _buildRecordingBadge()
                                  : const SizedBox.shrink()),
                      ),
                      SizedBox(width: 44.w),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Timer ──
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (_isRecording && !_isLoading) ? 1 : 0,
                  child: Text(
                    _formatTime(_secondsElapsed),
                    style: TextStyle(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                SizedBox(height: 36.h),

                // ── Mic Button ──
                _buildMicButton(),

                SizedBox(height: 28.h),

                // ── Audio Wave ──
                SizedBox(
                  height: 40.h,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: (_isRecording && !_isLoading) ? 1 : 0,
                    child: AudioWave(isRecording: _isRecording),
                  ),
                ),

                const Spacer(),

                // ── Hint Card ──
                if (!_isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey(_currentHint),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 18.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : primaryGreen.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lightbulb_outline_rounded,
                                color: primaryGreen,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _hints[_currentHint],
                                style: AppText.body14(context).copyWith(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20.h),

                // ── Stop Button ──
                if (!_isLoading)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 32.h,
                      left: 28.w,
                      right: 28.w,
                    ),
                    child: GestureDetector(
                      onTap: () => _stopAndSave(isDarkMode),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 17.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryGreen, darkGreenDeep],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.stop_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
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
        ),
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return Container(
      key: const ValueKey('recording'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: errorRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: errorRed.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(color: errorRed),
          SizedBox(width: 8.w),
          Text(
            'يسجل الآن',
            style: TextStyle(
              color: errorRed,
              fontSize: 12.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13.w,
            height: 13.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(primaryGreen),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'AI بيحلل كلامك...',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return SizedBox(
      width: 190.w,
      height: 190.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                      width: 100.w + (progress * 90.w),
                      height: 100.w + (progress * 90.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: errorRed, width: 1.5),
                      ),
                    ),
                  );
                },
              );
            }),
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
                          ? [primaryGreen, darkGreenDeep]
                          : const [errorRed, Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading ? primaryGreen : errorRed)
                            .withOpacity(0.4),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? RotationTransition(
                          turns: _loadingController,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 34.sp,
                          ),
                        )
                      : Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 40.sp,
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

// ── Widgets مساعدة ──

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
