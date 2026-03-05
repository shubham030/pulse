import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import '../providers/timer_provider.dart';
import '../theme/app_themes.dart';
import '../widgets/countdown_display.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with SingleTickerProviderStateMixin {
  bool _completionHandled = false;
  late final AnimationController _completionController;
  late final Animation<double> _completionScale;
  late final Animation<double> _completionFade;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    ref.read(timerProvider.notifier).onComplete = _onTimerComplete;

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completionScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.elasticOut),
    );
    _completionFade = CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _completionController.dispose();
    super.dispose();
  }

  Future<void> _onTimerComplete() async {
    if (_completionHandled) return;
    _completionHandled = true;

    _completionController.forward();

    final state = ref.read(timerProvider);
    if (state.sound) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 1000],
          intensities: [0, 255, 0, 200, 0, 255],
        );
      }
    }

    if (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) _goHome();
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _stop() {
    ref.read(timerProvider.notifier).stopTimer();
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final pulse = context.pulse;
    final isCompleted = timerState.status == TimerStatus.completed;

    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _stop();
          }
        },
        child: Container(
          decoration: BoxDecoration(gradient: pulse.backgroundGradient),
          child: SafeArea(
            child: isCompleted
                ? _CompletedView(
                    label: timerState.label,
                    scale: _completionScale,
                    fade: _completionFade,
                    accentColor: pulse.accentColor,
                    isAmbient: pulse.isAmbient,
                    onDismiss: _goHome,
                  )
                : _RunningView(
                    timerState: timerState,
                    pulse: pulse,
                    onStop: _stop,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  final TimerState timerState;
  final PulseThemeData pulse;
  final VoidCallback onStop;

  const _RunningView({
    required this.timerState,
    required this.pulse,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Countdown — truly centered
        Center(
          child: CountdownDisplay(
            totalSeconds: timerState.totalSeconds,
            remainingSeconds: timerState.remainingSeconds,
            label: timerState.label,
            ringColor: pulse.ringColor,
            ringBgColor: pulse.ringBg,
            isAmbient: pulse.isAmbient,
          ),
        ),

        // Stop button — pinned to bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onStop,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: Colors.white38,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'swipe down to stop',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedView extends StatelessWidget {
  final String label;
  final Animation<double> scale;
  final Animation<double> fade;
  final Color accentColor;
  final bool isAmbient;
  final VoidCallback onDismiss;

  const _CompletedView({
    required this.label,
    required this.scale,
    required this.fade,
    required this.accentColor,
    required this.isAmbient,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAmbient)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  Icons.check_rounded,
                  size: 72,
                  color: accentColor,
                ),
                const SizedBox(height: 28),
                Text(
                  label.isEmpty ? 'Done' : label,
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w200,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'tap to dismiss',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
