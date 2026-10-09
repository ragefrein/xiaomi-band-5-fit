import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/miband_service.dart';
import '../theme/app_colors.dart';
import 'brutal_button.dart';
import 'brutal_container.dart';

/// Popup alur connect Mi Band:
///   scan Bluetooth → pilih band → isi auth key → connect + auth.
///
/// Mengembalikan `true` bila berhasil connect & auth.
Future<bool> showConnectDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ConnectDialog(),
  );
  return ok ?? false;
}

class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog();

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

enum _Step { scanning, pick, key, connecting }

class _ConnectDialogState extends State<_ConnectDialog> {
  final _svc = MiBandService.instance;
  final _keyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  _Step _step = _Step.scanning;
  List<ScanResult> _results = const [];
  ScanResult? _selected;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _keyCtrl.text = _svc.keyHex == '0x15eda396884d8f2c1fe52817a61764dc'
        ? ''
        : _svc.keyHex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _step = _Step.scanning;
      _error = null;
      _results = const [];
    });

    // Pastikan Bluetooth aktif.
    try {
      if (await FlutterBluePlus.isSupported == false) {
        setState(() {
          _error = 'Perangkat ini tidak mendukung Bluetooth LE.';
          _step = _Step.pick;
        });
        return;
      }
    } catch (_) {}

    if (!await _svc.requestPermissions()) {
      setState(() {
        _error = 'Izin Bluetooth/Lokasi ditolak. Buka Setelan lalu izinkan.';
        _step = _Step.pick;
      });
      return;
    }

    final list = await _svc.scanDevices();
    if (!mounted) return;
    setState(() {
      _results = list;
      _step = _Step.pick;
      if (list.isEmpty) {
        _error = 'Tidak ada device ditemukan. Pastikan band dekat & menyala.';
      }
    });
  }

  void _pickDevice(ScanResult r) {
    setState(() {
      _selected = r;
      _error = null;
      _step = _Step.key;
    });
  }

  Future<void> _connect() async {
    final dev = _selected?.device;
    if (dev == null) return;

    if (_keyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Auth key belum diisi.');
      return;
    }

    setState(() {
      _step = _Step.connecting;
      _error = null;
    });

    final ok = await _svc.connectToDevice(dev, _keyCtrl.text);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _step = _Step.key;
        _error = _svc.lastError ?? 'Connect/Auth gagal.';
      });
    }
  }

  String _name(ScanResult r) {
    final n = r.device.platformName;
    return n.isEmpty ? '(tanpa nama)' : n;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: BrutalContainer(
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              if (_error != null) ...[
                BrutalContainer(
                  backgroundColor: AppColors.primaryPeach,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: AppColors.black, offset: Offset(2, 2))
            ],
          ),
          child: const Icon(Icons.bluetooth_searching, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('CONNECT BAND',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.scanning:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.black),
              SizedBox(height: 16),
              Text('MENCARI DEVICE BLUETOOTH…',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );

      case _Step.pick:
        return _pickList();

      case _Step.key:
        return _keyForm();

      case _Step.connecting:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.black),
              SizedBox(height: 16),
              Text('MENGHUBUNGKAN & AUTHENTIKASI…',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
    }
  }

  Widget _pickList() {
    if (_results.isEmpty) {
      return Column(
        children: [
          const Text('Tidak ada device. Coba scan ulang.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          _scanAgainButton(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PILIH BAND:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            controller: _scrollCtrl,
            shrinkWrap: true,
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = _results[i];
              final strong = r.rssi > -70;
              return GestureDetector(
                onTap: () => _pickDevice(r),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.watch, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name(r),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(r.device.remoteId.str,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 10)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: strong
                              ? AppColors.primaryMint
                              : AppColors.primaryPeach,
                          border: Border.all(color: AppColors.black),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${r.rssi} dBm',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _scanAgainButton(),
      ],
    );
  }

  Widget _scanAgainButton() {
    return BrutalButton(
      backgroundColor: AppColors.primaryYellow,
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: _startScan,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh),
          SizedBox(width: 8),
          Text('SCAN ULANG', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _keyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrutalContainer(
          backgroundColor: AppColors.primaryLavender,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.watch, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${_name(_selected!)} • ${_selected!.device.remoteId.str}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('MASUKKAN AUTH KEY',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: _keyCtrl,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            hintText: '32 digit hex (16 byte)',
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: AppColors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Key diambil dari Gadgetbridge/Zepp Life SETELAH pairing terakhir. '
          'Kalau band di-factory-reset, key harus diambil ulang.',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BrutalButton(
                backgroundColor: AppColors.primaryPeach,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () =>
                    setState(() => _step = _Step.pick),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 6),
                    Text('KEMBALI',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BrutalButton(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _connect,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, size: 18),
                    SizedBox(width: 6),
                    Text('CONNECT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  OutlineInputBorder _border() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      );
}
