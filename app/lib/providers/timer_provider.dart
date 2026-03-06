import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerStatus { idle, running, paused, completed }

enum PomodoroPhase { focus, shortBreak, longBreak }

class QueuedTimer {
  final int durationSeconds;
  final String label;
  final bool sound;

  const QueuedTimer({
    required this.durationSeconds,
    this.label = '',
    this.sound = true,
  });

  Map<String, dynamic> toJson() => {
        'duration': durationSeconds,
        'label': label,
        'sound': sound,
      };

  factory QueuedTimer.fromJson(Map<String, dynamic> json) => QueuedTimer(
        durationSeconds: json['duration'] as int,
        label: json['label'] as String? ?? '',
        sound: json['sound'] as bool? ?? true,
      );
}

class PomodoroConfig {
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;
  final int totalCycles;

  const PomodoroConfig({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.cyclesBeforeLongBreak = 4,
    this.totalCycles = 4,
  });

  Map<String, dynamic> toJson() => {
        'focusMinutes': focusMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
        'totalCycles': totalCycles,
      };

  factory PomodoroConfig.fromJson(Map<String, dynamic> json) => PomodoroConfig(
        focusMinutes: json['focusMinutes'] as int? ?? 25,
        shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
        longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
        cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] as int? ?? 4,
        totalCycles: json['totalCycles'] as int? ?? 4,
      );
}

class PomodoroState {
  final PomodoroConfig config;
  final int currentCycle;
  final PomodoroPhase phase;

  const PomodoroState({
    required this.config,
    this.currentCycle = 1,
    this.phase = PomodoroPhase.focus,
  });

  PomodoroState copyWith({int? currentCycle, PomodoroPhase? phase}) =>
      PomodoroState(
        config: config,
        currentCycle: currentCycle ?? this.currentCycle,
        phase: phase ?? this.phase,
      );

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'currentCycle': currentCycle,
        'totalCycles': config.totalCycles,
        'phase': phase.name,
      };
}

class TimerState {
  final TimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;
  final String label;
  final bool sound;
  final List<QueuedTimer> queue;
  final PomodoroState? pomodoro;

  const TimerState({
    this.status = TimerStatus.idle,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.label = '',
    this.sound = true,
    this.queue = const [],
    this.pomodoro,
  });

  bool get hasNext => pomodoro != null || queue.isNotEmpty;

  TimerState copyWith({
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    String? label,
    bool? sound,
    List<QueuedTimer>? queue,
    PomodoroState? Function()? pomodoro,
  }) {
    return TimerState(
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      label: label ?? this.label,
      sound: sound ?? this.sound,
      queue: queue ?? this.queue,
      pomodoro: pomodoro != null ? pomodoro() : this.pomodoro,
    );
  }

  Map<String, dynamic> toStatusJson() => {
        'status': status.name,
        'running': status == TimerStatus.running,
        'paused': status == TimerStatus.paused,
        'remaining': remainingSeconds,
        'total': totalSeconds,
        'label': label,
        'queue': queue.map((q) => q.toJson()).toList(),
        if (pomodoro != null) 'pomodoro': pomodoro!.toJson(),
      };
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  void Function()? onComplete;

  @override
  TimerState build() => const TimerState();

  /// Start a fresh timer, clearing queue and pomodoro.
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
    _startTicker();
  }

  void pauseTimer() {
    if (state.status != TimerStatus.running) return;
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resumeTimer() {
    if (state.status != TimerStatus.paused) return;
    state = state.copyWith(status: TimerStatus.running);
    _startTicker();
  }

  void stopTimer() {
    _ticker?.cancel();
    state = const TimerState();
  }

  void skipTimer() {
    _ticker?.cancel();
    advanceOrStop();
  }

  /// Called by UI after completion animation, or by skip.
  void advanceOrStop() {
    if (state.pomodoro != null) {
      _advancePomodoro();
    } else if (state.queue.isNotEmpty) {
      _startNextFromQueue();
    } else {
      state = const TimerState();
    }
  }

  // -- Queue --

  void enqueueTimer({
    required int durationSeconds,
    String label = '',
    bool sound = true,
  }) {
    final newQueue = [
      ...state.queue,
      QueuedTimer(durationSeconds: durationSeconds, label: label, sound: sound),
    ];
    state = state.copyWith(queue: newQueue);

    if (state.status == TimerStatus.idle) {
      _startNextFromQueue();
    }
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final newQueue = [...state.queue]..removeAt(index);
    state = state.copyWith(queue: newQueue);
  }

  void clearQueue() {
    state = state.copyWith(queue: [], pomodoro: () => null);
  }

  // -- Pomodoro --

  void startPomodoro(PomodoroConfig config) {
    _ticker?.cancel();
    final pomo = PomodoroState(config: config);
    state = state.copyWith(queue: [], pomodoro: () => pomo);
    _startPomodoroPhase(pomo);
  }

  void _startPomodoroPhase(PomodoroState pomo) {
    int duration;
    String label;
    switch (pomo.phase) {
      case PomodoroPhase.focus:
        duration = pomo.config.focusMinutes * 60;
        label = 'Focus ${pomo.currentCycle}/${pomo.config.totalCycles}';
      case PomodoroPhase.shortBreak:
        duration = pomo.config.shortBreakMinutes * 60;
        label = 'Short Break';
      case PomodoroPhase.longBreak:
        duration = pomo.config.longBreakMinutes * 60;
        label = 'Long Break';
    }

    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.running,
      totalSeconds: duration,
      remainingSeconds: duration,
      label: label,
      sound: true,
      pomodoro: () => pomo,
    );
    _startTicker();
  }

  void _advancePomodoro() {
    final pomo = state.pomodoro!;
    PomodoroState next;

    switch (pomo.phase) {
      case PomodoroPhase.focus:
        if (pomo.currentCycle >= pomo.config.totalCycles) {
          state = const TimerState();
          return;
        }
        if (pomo.currentCycle % pomo.config.cyclesBeforeLongBreak == 0) {
          next = pomo.copyWith(phase: PomodoroPhase.longBreak);
        } else {
          next = pomo.copyWith(phase: PomodoroPhase.shortBreak);
        }
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        next = pomo.copyWith(
          currentCycle: pomo.currentCycle + 1,
          phase: PomodoroPhase.focus,
        );
    }

    _startPomodoroPhase(next);
  }

  void _startNextFromQueue() {
    if (state.queue.isEmpty) return;
    final next = state.queue.first;
    final newQueue = state.queue.sublist(1);

    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.running,
      totalSeconds: next.durationSeconds,
      remainingSeconds: next.durationSeconds,
      label: next.label,
      sound: next.sound,
      queue: newQueue,
    );
    _startTicker();
  }

  // -- Internal --

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
