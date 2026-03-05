import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ServiceTimerState {
  bool running = false;
  int remaining = 0;
  String label = '';

  void update(Map<String, dynamic> data) {
    running = data['running'] as bool? ?? false;
    remaining = data['remaining'] as int? ?? 0;
    label = data['label'] as String? ?? '';
  }
}

final serviceState = ServiceTimerState();

Router buildRouter() {
  final router = Router();

  router.post('/timer', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final duration = data['duration'];
      if (duration == null || duration is! int || duration <= 0) {
        return Response(
          400,
          body: jsonEncode({'error': 'duration must be a positive integer (seconds)'}),
          headers: {'content-type': 'application/json'},
        );
      }

      FlutterForegroundTask.sendDataToMain({
        'action': 'start',
        'duration': duration,
        'label': data['label'] ?? '',
        'sound': data['sound'] ?? true,
      });

      return Response.ok(
        jsonEncode({'ok': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        400,
        body: jsonEncode({'error': 'invalid JSON: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  router.post('/stop', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'stop'});
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/status', (Request request) async {
    return Response.ok(
      jsonEncode({
        'running': serviceState.running,
        'remaining': serviceState.remaining,
        'label': serviceState.label,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/settings', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      FlutterForegroundTask.sendDataToMain({
        'action': 'settings',
        ...data,
      });

      return Response.ok(
        jsonEncode({'ok': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        400,
        body: jsonEncode({'error': 'invalid JSON: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
