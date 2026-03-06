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
      if (mounted) {
        final notifier = ref.read(timerProvider.notifier);
        final current = ref.read(timerProvider);
        if (current.hasNext) {
          // Start next timer in queue/pomodoro
          notifier.advanceOrStop();
          _completionHandled = false;
          _completionController.reset();
        } else {
          notifier.advanceOrStop();
          _goHome();
        }
      }
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _stop() {
    ref.read(timerProvider.notifier).stopTimer();
    _goHome();
  }

  void _togglePause() {
    final notifier = ref.read(timerProvider.notifier);
    final status = ref.read(timerProvider).status;
    if (status == TimerStatus.running) {
      notifier.pauseTimer();
    } else if (status == TimerStatus.paused) {
      notifier.resumeTimer();
    }
  }

  void _skip() {
    _completionHandled = false;
    _completionController.reset();
    ref.read(timerProvider.notifier).skipTimer();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final pulse = context.pulse;
    final isCompleted = timerState.status == TimerStatus.completed;
    final isPaused = timerState.status == TimerStatus.paused;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // If timer was stopped externally (e.g. via API), go home
    if (timerState.status == TimerStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goHome();
      });
    }

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
                    hasNext: timerState.hasNext,
                    pomodoro: timerState.pomodoro,
                    scale: _completionScale,
                    fade: _completionFade,
                    accentColor: pulse.accentColor,
                    isAmbient: pulse.isAmbient,
                    onDismiss: () {
                      ref.read(timerProvider.notifier).advanceOrStop();
                      if (!ref.read(timerProvider).hasNext) _goHome();
                      _completionHandled = false;
                      _completionController.reset();
                    },
                  )
                : isTablet
                    ? _TabletRunningView(
                        timerState: timerState,
                        pulse: pulse,
                        isPaused: isPaused,
                        onStop: _stop,
                        onTogglePause: _togglePause,
                        onSkip: timerState.hasNext ? _skip : null,
                      )
                    : _RunningView(
                        timerState: timerState,
                        pulse: pulse,
                        isPaused: isPaused,
                        onStop: _stop,
                        onTogglePause: _togglePause,
                        onSkip: timerState.hasNext ? _skip : null,
                      ),
          ),
        ),
      ),
    );
  }
}

// -- Phone layout --

class _RunningView extends StatelessWidget {
  final TimerState timerState;
  final PulseThemeData pulse;
  final bool isPaused;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;
  final VoidCallback? onSkip;

  const _RunningView({
    required this.timerState,
    required this.pulse,
    required this.isPaused,
    required this.onStop,
    required this.onTogglePause,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: CountdownDisplay(
            totalSeconds: timerState.totalSeconds,
            remainingSeconds: timerState.remainingSeconds,
            label: timerState.label,
            ringColor: pulse.ringColor,
            ringBgColor: pulse.ringBg,
            isAmbient: pulse.isAmbient,
            isPaused: isPaused,
          ),
        ),

        // Queue indicator
        if (timerState.queue.isNotEmpty || timerState.pomodoro != null)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: _QueueIndicator(
              timerState: timerState,
              accentColor: pulse.accentColor,
            ),
          ),

        // Controls
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: _ControlBar(
              isPaused: isPaused,
              onStop: onStop,
              onTogglePause: onTogglePause,
              onSkip: onSkip,
            ),
          ),
        ),
      ],
    );
  }
}

// -- Tablet layout --

class _TabletRunningView extends StatelessWidget {
  final TimerState timerState;
  final PulseThemeData pulse;
  final bool isPaused;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;
  final VoidCallback? onSkip;

  const _TabletRunningView({
    required this.timerState,
    required this.pulse,
    required this.isPaused,
    required this.onStop,
    required this.onTogglePause,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final hasQueue = timerState.queue.isNotEmpty || timerState.pomodoro != null;

    return Row(
      children: [
        // Main timer area
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Center(
                child: CountdownDisplay(
                  totalSeconds: timerState.totalSeconds,
                  remainingSeconds: timerState.remainingSeconds,
                  label: timerState.label,
                  ringColor: pulse.ringColor,
                  ringBgColor: pulse.ringBg,
                  isAmbient: pulse.isAmbient,
                  isPaused: isPaused,
                  maxSize: 400,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _ControlBar(
                    isPaused: isPaused,
                    onStop: onStop,
                    onTogglePause: onTogglePause,
                    onSkip: onSkip,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Queue sidebar on tablet
        if (hasQueue)
          Container(
            width: 240,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: _QueueSidebar(
              timerState: timerState,
              accentColor: pulse.accentColor,
            ),
          ),
      ],
    );
  }
}

// -- Shared controls --

class _ControlBar extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;
  final VoidCallback? onSkip;

  const _ControlBar({
    required this.isPaused,
    required this.onStop,
    required this.onTogglePause,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stop
            _CircleButton(
              icon: Icons.stop_rounded,
              onTap: onStop,
              size: 48,
            ),
            const SizedBox(width: 24),
            // Pause / Resume
            _CircleButton(
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onTap: onTogglePause,
              size: 56,
              highlighted: true,
            ),
            const SizedBox(width: 24),
            // Skip
            _CircleButton(
              icon: Icons.skip_next_rounded,
              onTap: onSkip,
              size: 48,
              enabled: onSkip != null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isPaused ? 'paused' : 'swipe down to stop',
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool highlighted;
  final bool enabled;

  const _CircleButton({
    required this.icon,
    this.onTap,
    this.size = 48,
    this.highlighted = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = enabled ? (highlighted ? 0.15 : 0.05) : 0.02;
    final iconAlpha = enabled ? (highlighted ? 0.6 : 0.38) : 0.15;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.15 : 0.05),
          ),
          color: Colors.white.withValues(alpha: alpha),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: iconAlpha),
          size: size * 0.4,
        ),
      ),
    );
  }
}

// -- Queue indicators --

class _QueueIndicator extends StatelessWidget {
  final TimerState timerState;
  final Color accentColor;

  const _QueueIndicator({
    required this.timerState,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    String info;
    if (timerState.pomodoro != null) {
      final p = timerState.pomodoro!;
      info =
          '${p.phase.name.toUpperCase()} ${p.currentCycle}/${p.config.totalCycles}';
    } else {
      info = '${timerState.queue.length} more in queue';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accentColor.withValues(alpha: 0.1),
        ),
        child: Text(
          info,
          style: TextStyle(
            color: accentColor.withValues(alpha: 0.6),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QueueSidebar extends StatelessWidget {
  final TimerState timerState;
  final Color accentColor;

  const _QueueSidebar({
    required this.timerState,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timerState.pomodoro != null ? 'POMODORO' : 'QUEUE',
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (timerState.pomodoro != null) ...[
            _PomodoroInfo(
              pomodoro: timerState.pomodoro!,
              accentColor: accentColor,
            ),
          ],
          if (timerState.queue.isNotEmpty) ...[
            Expanded(
              child: ListView.separated(
                itemCount: timerState.queue.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final q = timerState.queue[i];
                  final m = q.durationSeconds ~/ 60;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${m}m',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.label.isEmpty ? 'Timer' : q.label,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PomodoroInfo extends StatelessWidget {
  final PomodoroState pomodoro;
  final Color accentColor;

  const _PomodoroInfo({
    required this.pomodoro,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalCycles = pomodoro.config.totalCycles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cycle dots
        Row(
          children: List.generate(totalCycles, (i) {
            final isComplete = i + 1 < pomodoro.currentCycle;
            final isCurrent = i + 1 == pomodoro.currentCycle;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: isCurrent ? 12 : 8,
                height: isCurrent ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete || isCurrent
                      ? accentColor.withValues(alpha: isCurrent ? 0.8 : 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  border: isCurrent
                      ? Border.all(color: accentColor, width: 1.5)
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          '${pomodoro.config.focusMinutes}m focus / '
          '${pomodoro.config.shortBreakMinutes}m break',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// -- Completion --

class _CompletedView extends StatelessWidget {
  final String label;
  final bool hasNext;
  final PomodoroState? pomodoro;
  final Animation<double> scale;
  final Animation<double> fade;
  final Color accentColor;
  final bool isAmbient;
  final VoidCallback onDismiss;

  const _CompletedView({
    required this.label,
    required this.hasNext,
    this.pomodoro,
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
                  hasNext ? 'tap to continue' : 'tap to dismiss',
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
