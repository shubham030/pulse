import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

Registration? _registration;

Future<void> registerMdns() async {
  try {
    _registration = await register(
      const Service(name: 'Pulse Timer', type: '_pulse._tcp', port: 7878),
    );
  } catch (e) {
    debugPrint('mDNS registration failed: $e');
  }
}

Future<void> unregisterMdns() async {
  if (_registration != null) {
    try {
      await unregister(_registration!);
    } catch (e) {
      debugPrint('mDNS unregistration failed: $e');
    }
    _registration = null;
  }
}
