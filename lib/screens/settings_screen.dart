import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/miband_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_button.dart';
import '../widgets/brutal_container.dart';

/// Layar untuk mengatur MAC + auth key Mi Band secara manual (tidak hardcode).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _svc = MiBandService.instance;

  late final TextEditingController _macCtrl;
  late final TextEditingController _keyCtrl;

  bool _obscure = true;
  String? _error;
  String? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _svc.init();
    _macCtrl = TextEditingController(text: _svc.mac);
    _keyCtrl = TextEditingController(text: _svc.keyHex);
  }

  @override
  void dispose() {
    _macCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _svc.saveCredentials(_macCtrl.text, _keyCtrl.text);
      if (!mounted) return;
      setState(() {
        _info = 'Tersimpan ✔ Credential baru akan dipakai saat connect.';
        // Normalisasi tampilan (mis. tambah 0x / uppercase MAC).
        _macCtrl.text = _svc.mac;
        _keyCtrl.text = _svc.keyHex;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth key disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Invalid argument(s): ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    await _svc.resetCredentials();
    if (!mounted) return;
    setState(() {
      _macCtrl.text = _svc.mac;
      _keyCtrl.text = _svc.keyHex;
      _info = 'Dikembalikan ke default bawaan.';
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(color: AppColors.black, height: 2.5),
        ),
        title: const Text('PENGATURAN BAND',
            style:
                TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: _svc,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrutalContainer(
                  backgroundColor: AppColors.primaryLavender,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.key, size: 20),
                          SizedBox(width: 8),
                          Text('AUTH KEY',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tempel auth key Mi Band kamu (32 digit hex / 16 byte). '
                        'Tidak perlu edit kode atau build ulang.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),

                      _label('AUTH KEY'),
                      _keyField(),
                      const SizedBox(height: 14),

                      _label('MAC ADDRESS'),
                      _macField(),
                      const SizedBox(height: 6),
                      Text(
                        _svc.hasSavedCredentials
                            ? 'Status: memakai credential yang kamu simpan.'
                            : 'Status: masih memakai DEFAULT bawaan.',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  BrutalContainer(
                    backgroundColor: AppColors.primaryPeach,
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
                  const SizedBox(height: 16),
                ],

                if (_info != null) ...[
                  BrutalContainer(
                    backgroundColor: AppColors.primaryMint,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_info!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                BrutalButton(
                  backgroundColor: AppColors.primaryYellow,
                  onPressed: _busy ? () {} : _save,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('SIMPAN',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BrutalButton(
                  backgroundColor: AppColors.primaryPeach,
                  onPressed: _busy ? () {} : _reset,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restart_alt),
                      SizedBox(width: 8),
                      Text('KEMBALIKAN DEFAULT',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
      );

  Widget _keyField() {
    return TextField(
      controller: _keyCtrl,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-FxX]')),
      ],
      decoration: InputDecoration(
        hintText: '0x15eda396…',
        hintStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  Widget _macField() {
    return TextField(
      controller: _macCtrl,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
      ],
      decoration: InputDecoration(
        hintText: 'C4:B5:F6:1D:93:69',
        hintStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(),
      ),
    );
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      );
}
