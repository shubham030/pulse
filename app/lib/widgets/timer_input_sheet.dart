import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../app.dart';

class TimerInputSheet extends ConsumerStatefulWidget {
  const TimerInputSheet({super.key});

  @override
  ConsumerState<TimerInputSheet> createState() => _TimerInputSheetState();
}

class _TimerInputSheetState extends ConsumerState<TimerInputSheet> {
  int _minutes = 25;
  int _seconds = 0;
  final _labelController = TextEditingController();
  bool _sound = true;

  @override
  void initState() {
    super.initState();
    _sound = ref.read(settingsProvider).soundDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _start() {
    final totalSeconds = _minutes * 60 + _seconds;
    if (totalSeconds <= 0) return;

    ref.read(timerProvider.notifier).startTimer(
          durationSeconds: totalSeconds,
          label: _labelController.text.trim(),
          sound: _sound,
        );

    Navigator.of(context).pop();
    navigatorKey.currentState?.pushReplacementNamed('/timer');
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Custom Timer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 24),

            // Duration picker
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('MIN', style: TextStyle(color: color, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          scrollController:
                              FixedExtentScrollController(initialItem: _minutes),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              setState(() => _minutes = i),
                          children: List.generate(
                            121,
                            (i) => Center(
                              child: Text(
                                '$i',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(':', style: TextStyle(color: color, fontSize: 32)),
                Expanded(
                  child: Column(
                    children: [
                      Text('SEC', style: TextStyle(color: color, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          scrollController:
                              FixedExtentScrollController(initialItem: _seconds),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              setState(() => _seconds = i),
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Label
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Label (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sound toggle
            Row(
              children: [
                const Icon(Icons.vibration, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                const Text('Vibrate on complete',
                    style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Switch(
                  value: _sound,
                  onChanged: (v) => setState(() => _sound = v),
                  activeThumbColor: color,
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _minutes + _seconds > 0 ? _start : null,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                      letterSpacing: 3, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
