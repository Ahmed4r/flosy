import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioWave extends StatefulWidget {
  final bool isRecording;
  const AudioWave({super.key, required this.isRecording});

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final _random = Random();
  final int _barsCount = 20;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barsCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(600)),
        lowerBound: 0.2,
        upperBound: 1.0,
      ),
    );
    // منطقياً: تشغيل الأنميشن فوراً إذا بدأت الصفحة وهي في حالة تسجيل
    if (widget.isRecording) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(AudioWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_barsCount, (index) {
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final double height = widget.isRecording
                  ? 20.h + (_controllers[index].value * 40.h)
                  : 20.h;
              return Container(
                width: 4.w,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4.w),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}