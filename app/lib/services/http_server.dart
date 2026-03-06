import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServiceTimerState {
  String status = 'idle';
  bool running = false;
  bool paused = false;
  int remaining = 0;
  int total = 0;
  String label = '';
  List<Map<String, dynamic>> queue = [];
  Map<String, dynamic>? pomodoro;

  void update(Map<String, dynamic> data) {
    status = data['status'] as String? ?? 'idle';
    running = data['running'] as bool? ?? false;
    paused = data['paused'] as bool? ?? false;
    remaining = data['remaining'] as int? ?? 0;
    total = data['total'] as int? ?? 0;
    label = data['label'] as String? ?? '';
    queue = (data['queue'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    pomodoro = data['pomodoro'] as Map<String, dynamic>?;
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'running': running,
        'paused': paused,
        'remaining': remaining,
        'total': total,
        'label': label,
        'queue': queue,
        if (pomodoro != null) 'pomodoro': pomodoro,
      };
}

final serviceState = ServiceTimerState();

// -- WebSocket clients --
final Set<WebSocketChannel> _wsClients = {};

void broadcastWsState() {
  if (_wsClients.isEmpty) return;
  final json = jsonEncode({'type': 'status', ...serviceState.toJson()});
  for (final ws in _wsClients.toList()) {
    try {
      ws.sink.add(json);
    } catch (_) {
      _wsClients.remove(ws);
    }
  }
}

Handler buildWsHandler() {
  return webSocketHandler((WebSocketChannel ws) {
    _wsClients.add(ws);

    // Send current state on connect
    ws.sink.add(jsonEncode({'type': 'status', ...serviceState.toJson()}));

    ws.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final action = data['action'] as String?;
          // Forward WS commands to main isolate
          FlutterForegroundTask.sendDataToMain(data);
          if (action == null) return;
        } catch (_) {}
      },
      onDone: () => _wsClients.remove(ws),
      onError: (_) => _wsClients.remove(ws),
    );
  });
}

Router buildRouter() {
  final router = Router();

  // -- Timer control --

  router.post('/timer', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final duration = data['duration'];
      if (duration == null || duration is! int || duration <= 0) {
        return _badRequest('duration must be a positive integer (seconds)');
      }
      FlutterForegroundTask.sendDataToMain({
        'action': 'start',
        'duration': duration,
        'label': data['label'] ?? '',
        'sound': data['sound'] ?? true,
      });
      return _ok();
    } catch (e) {
      return _badRequest('invalid JSON: $e');
    }
  });

  router.post('/stop', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'stop'});
    return _ok();
  });

  router.post('/pause', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'pause'});
    return _ok();
  });

  router.post('/resume', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'resume'});
    return _ok();
  });

  router.post('/skip', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'skip'});
    return _ok();
  });

  // -- Status --

  router.get('/status', (Request request) async {
    return Response.ok(
      jsonEncode(serviceState.toJson()),
      headers: _jsonHeaders,
    );
  });

  // -- Queue --

  router.post('/queue', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final duration = data['duration'];
      if (duration == null || duration is! int || duration <= 0) {
        return _badRequest('duration must be a positive integer (seconds)');
      }
      FlutterForegroundTask.sendDataToMain({
        'action': 'enqueue',
        'duration': duration,
        'label': data['label'] ?? '',
        'sound': data['sound'] ?? true,
      });
      return _ok();
    } catch (e) {
      return _badRequest('invalid JSON: $e');
    }
  });

  router.get('/queue', (Request request) async {
    return Response.ok(
      jsonEncode({'queue': serviceState.queue}),
      headers: _jsonHeaders,
    );
  });

  router.delete('/queue', (Request request) async {
    FlutterForegroundTask.sendDataToMain({'action': 'clearQueue'});
    return _ok();
  });

  router.delete('/queue/<index>', (Request request, String index) async {
    final i = int.tryParse(index);
    if (i == null) return _badRequest('index must be an integer');
    FlutterForegroundTask.sendDataToMain({
      'action': 'removeFromQueue',
      'index': i,
    });
    return _ok();
  });

  // -- Pomodoro --

  router.post('/pomodoro', (Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data = {};
      if (body.isNotEmpty) {
        data = jsonDecode(body) as Map<String, dynamic>;
      }
      FlutterForegroundTask.sendDataToMain({
        'action': 'pomodoro',
        ...data,
      });
      return _ok();
    } catch (e) {
      return _badRequest('invalid JSON: $e');
    }
  });

  // -- Settings --

  router.post('/settings', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      FlutterForegroundTask.sendDataToMain({
        'action': 'settings',
        ...data,
      });
      return _ok();
    } catch (e) {
      return _badRequest('invalid JSON: $e');
    }
  });

  return router;
}

// -- Helpers --

const _jsonHeaders = {'content-type': 'application/json'};

Response _ok([Map<String, dynamic>? extra]) => Response.ok(
      jsonEncode({'ok': true, ...?extra}),
      headers: _jsonHeaders,
    );

Response _badRequest(String error) => Response(
      400,
      body: jsonEncode({'error': error}),
      headers: _jsonHeaders,
    );
