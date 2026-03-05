import 'dart:math' as math;
import 'package:flutter/material.dart';

class CountdownDisplay extends StatefulWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final String label;
  final Color ringColor;
  final Color ringBgColor;
  final bool isAmbient;

  const CountdownDisplay({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.label,
    required this.ringColor,
    required this.ringBgColor,
    required this.isAmbient,
  });

  @override
  State<CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<CountdownDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = widget.remainingSeconds ~/ 60;
    final s = widget.remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (widget.totalSeconds == 0) return 0;
    return 1 - (widget.remainingSeconds / widget.totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.72;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              color: widget.ringColor.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ] else
          const SizedBox(height: 16),

        AnimatedBuilder(
          animation: _breathAnim,
          builder: (context, child) {
            final scale = widget.isAmbient ? _breathAnim.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient glow
                    if (widget.isAmbient)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.ringColor.withValues(alpha: 0.12),
                                blurRadius: 60,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Ring track
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: _progress,
                          trackColor: widget.ringBgColor,
                          progressColor: widget.ringColor,
                          isAmbient: widget.isAmbient,
                          strokeWidth: widget.isAmbient ? 3.0 : 5.0,
                        ),
                      ),
                    ),

                    // Time + label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeString,
                          style: TextStyle(
                            fontSize: size * 0.22,
                            fontWeight: FontWeight.w100,
                            color: Colors.white,
                            letterSpacing: widget.isAmbient ? 6 : 3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ProgressBar(
                          progress: _progress,
                          color: widget.ringColor,
                          isAmbient: widget.isAmbient,
                        ),
                      ],
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
}

/// A thin linear progress bar shown below the time.
class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isAmbient;

  const _ProgressBar({
    required this.progress,
    required this.color,
    required this.isAmbient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 2,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(
            color.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for the arc ring — supports gradient stroke in ambient mode.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final bool isAmbient;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.isAmbient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isAmbient) {
      progressPaint.shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          progressColor.withValues(alpha: 0.4),
          progressColor,
        ],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isAmbient != isAmbient;
}
