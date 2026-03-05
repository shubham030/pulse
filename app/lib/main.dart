import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/foreground_service.dart';

final providerContainer = ProviderContainer();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be called before runApp so no messages are dropped
  FlutterForegroundTask.initCommunicationPort();

  // Register callback at top level using container — survives hot restarts
  registerTaskDataCallback(providerContainer);

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: const PulseApp(),
    ),
  );
}
