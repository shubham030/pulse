import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerStatus { idle, running, completed }

class TimerState {
  final TimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;
  final String label;
  final bool sound;

  const TimerState({
    this.status = TimerStatus.idle,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.label = '',
    this.sound = true,
  });

  TimerState copyWith({
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    String? label,
    bool? sound,
  }) {
    return TimerState(
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      label: label ?? this.label,
      sound: sound ?? this.sound,
    );
  }
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  void Function()? onComplete;

  @override
  TimerState build() => const TimerState();

  void startTimer({
    required int durationSeconds,
    String label = '',
    bool sound = true,
  }) {
    _ticker?.cancel();
    state = TimerState(
      status: TimerStatus.running,
      totalSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      label: label,
      sound: sound,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stopTimer() {
    _ticker?.cancel();
    state = const TimerState();
  }

  void _tick() {
    if (state.remainingSeconds <= 1) {
      _ticker?.cancel();
      state = state.copyWith(
        status: TimerStatus.completed,
        remainingSeconds: 0,
      );
      onComplete?.call();
    } else {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    }
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);
