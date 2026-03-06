import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

class PulseDevice {
  final String name;
  final String host;
  final int port;

  const PulseDevice({
    required this.name,
    required this.host,
    required this.port,
  });

  String get baseUrl => 'http://$host:$port';

  @override
  bool operator ==(Object other) =>
      other is PulseDevice && host == other.host && port == other.port;

  @override
  int get hashCode => Object.hash(host, port);
}

class DeviceDiscoveryNotifier extends Notifier<List<PulseDevice>> {
  Discovery? _discovery;

  @override
  List<PulseDevice> build() {
    ref.onDispose(stopDiscovery);
    return [];
  }

  Future<void> startDiscovery() async {
    try {
      _discovery = await startNsdDiscovery('_pulse._tcp');
      _discovery!.addServiceListener((service, status) {
        if (status == ServiceStatus.found) {
          final host = service.addresses?.firstOrNull?.address;
          final port = service.port;
          if (host != null && port != null) {
            final device = PulseDevice(
              name: service.name ?? 'Pulse Device',
              host: host,
              port: port,
            );
            if (!state.contains(device)) {
              state = [...state, device];
            }
          }
        } else if (status == ServiceStatus.lost) {
          final host = service.addresses?.firstOrNull?.address;
          final port = service.port;
          if (host != null && port != null) {
            state = state
                .where((d) => !(d.host == host && d.port == port))
                .toList();
          }
        }
      });
    } catch (e) {
      debugPrint('Device discovery failed: $e');
    }
  }

  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      try {
        await stopNsdDiscovery(_discovery!);
      } catch (_) {}
      _discovery = null;
    }
  }

  /// Send a command to all discovered devices.
  Future<void> broadcastToDevices(Map<String, dynamic> command) async {
    final path = command.remove('_path') as String? ?? '/timer';
    final method = command.remove('_method') as String? ?? 'POST';
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    for (final device in state) {
      try {
        final uri = Uri.parse('${device.baseUrl}$path');
        late HttpClientRequest req;
        if (method == 'POST') {
          req = await client.postUrl(uri);
          req.headers.set('content-type', 'application/json');
          req.write(jsonEncode(command));
        } else if (method == 'DELETE') {
          req = await client.deleteUrl(uri);
        } else {
          req = await client.getUrl(uri);
        }
        final res = await req.close();
        await res.drain<void>();
      } catch (e) {
        debugPrint('Failed to reach ${device.name}: $e');
      }
    }
    client.close();
  }
}

final deviceDiscoveryProvider =
    NotifierProvider<DeviceDiscoveryNotifier, List<PulseDevice>>(
  DeviceDiscoveryNotifier.new,
);

Future<Discovery> startNsdDiscovery(String serviceType) async {
  return await startDiscovery(serviceType);
}

Future<void> stopNsdDiscovery(Discovery discovery) async {
  await stopDiscovery(discovery);
}
