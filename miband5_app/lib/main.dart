import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/aes_ecb.dart';
import 'core/miband5.dart';

void main() => runApp(const MiBandApp());

class MiBandApp extends StatelessWidget {
  const MiBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Band 5 (custom)',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _macCtrl = TextEditingController(text: 'C4:B5:F6:1D:93:69');
  final _keyCtrl = TextEditingController(text: '0xf5b6262c77798467ad93abadf2aa7115');
  final _storage = const FlutterSecureStorage();

  late final MiBand5 _band;
  final _logLines = <String>[];
  MiBandState _state = MiBandState.idle;

  @override
  void initState() {
    super.initState();
    _band = MiBand5(onLog: _appendLog);
    _band.stateStream.listen((s) => setState(() => _state = s));
    _loadKey();
  }

  Future<void> _loadKey() async {
    final saved = await _storage.read(key: 'auth_key');
    if (saved != null && saved.isNotEmpty) {
      _keyCtrl.text = saved;
    }
  }

  void _appendLog(String m) {
    setState(() => _logLines.insert(0, m));
  }

  Future<void> _connectAndAuth() async {
    final mac = _macCtrl.text.trim();
    final keyHex = _keyCtrl.text.trim();

    Uint8List key;
    try {
      key = hexToBytes(keyHex);
      if (key.length != 16) throw 'Key must be 16 bytes';
    } catch (e) {
      _appendLog('Invalid key: $e');
      return;
    }

    // Persist the key securely for next launch.
    await _storage.write(key: 'auth_key', value: keyHex);

    final device = await _band.scanFor(mac);
    if (device == null) return;

    final connected = await _band.connect(device);
    if (!connected) return;

    await _band.authenticate(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Band 5 — Custom App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _macCtrl,
              decoration: const InputDecoration(
                labelText: 'Band MAC address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Auth key (16 bytes, hex)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _state == MiBandState.authenticating ||
                      _state == MiBandState.connecting ||
                      _state == MiBandState.scanning
                  ? null
                  : _connectAndAuth,
              icon: const Icon(Icons.bluetooth),
              label: const Text('Connect & Authenticate'),
            ),
            const SizedBox(height: 8),
            Text('State: $_state'),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _logLines.length,
                itemBuilder: (_, i) => Text(
                  _logLines[i],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _band.dispose();
    _macCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }
}
