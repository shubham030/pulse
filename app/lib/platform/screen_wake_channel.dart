import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenWakeChannel {
  static const _channel = MethodChannel('dev.pulse/screen_wake');

  static Future<void> wakeScreen() async {
    try {
      await _channel.invokeMethod('wakeScreen');
    } on PlatformException catch (e) {
      // Log but don't crash — screen wake is best-effort
      debugPrint('ScreenWakeChannel error: ${e.message}');
    }
  }
}
