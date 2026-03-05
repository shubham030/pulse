import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'http_server.dart';
import 'mdns_service.dart';

class PulseTaskHandler extends TaskHandler {
  HttpServer? _server;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('PulseTaskHandler.onStart called');
    try {
      final router = buildRouter();
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 7878);
      debugPrint('HTTP server started on port 7878');
    } catch (e, st) {
      debugPrint('HTTP server failed to start: $e\n$st');
    }

    try {
      await registerMdns();
      debugPrint('mDNS registered');
    } catch (e) {
      debugPrint('mDNS failed: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('PulseTaskHandler.onDestroy called');
    await unregisterMdns();
    await _server?.close(force: true);
    _server = null;
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      final action = data['action'] as String?;
      if (action == 'statusUpdate') {
        serviceState.update(data);
      }
    }
  }
}
