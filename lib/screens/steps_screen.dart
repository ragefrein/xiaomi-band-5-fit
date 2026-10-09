import 'package:flutter/material.dart';

import '../services/miband/miband5.dart';
import '../services/miband_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_button.dart';
import '../widgets/brutal_container.dart';
import 'settings_screen.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final _svc = MiBandService.instance;

  @override
  void initState() {
    super.initState();
    _svc.init();
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _stateLabel(MiBandState s) {
    switch (s) {
      case MiBandState.idle:
        return 'BELUM TERHUBUNG';
      case MiBandState.scanning:
        return 'MENCARI BAND…';
      case MiBandState.connecting:
        return 'MENGHUBUNGKAN…';
      case MiBandState.connected:
        return 'TERHUBUNG';
      case MiBandState.authenticating:
        return 'AUTHENTIKASI…';
      case MiBandState.authenticated:
        return 'SIAP ✔';
      case MiBandState.fetching:
        return 'MENGAMBIL DATA…';
      case MiBandState.failed:
        return 'GAGAL';
      case MiBandState.disconnected:
        return 'TERPUTUS';
    }
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
        title: const Text('LANGKAH',
            style:
                TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Atur auth key / MAC',
            icon: const Icon(Icons.settings, color: AppColors.black),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _svc,
        builder: (context, _) {
          final progress =
              (_svc.todaySteps / 10000).clamp(0.0, 1.0).toDouble();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ---- Status band ----
                BrutalContainer(
                  backgroundColor: _svc.ready
                      ? AppColors.primaryMint
                      : AppColors.primaryPeach,
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'BAND: ${_stateLabel(_svc.state)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(
                        _svc.mac,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Kartu langkah hari ini ----
                BrutalContainer(
                  backgroundColor: AppColors.primaryMint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Langkah Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _fmt(_svc.todaySteps),
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Text('/ 10.000',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.black, offset: Offset(2, 2))
                          ],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primaryYellow,
                              border: Border(
                                  right: BorderSide(
                                      color: AppColors.black, width: 2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sampel terakhir: ${_svc.samples.length} menit',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Kartu langkah live ----
                BrutalContainer(
                  backgroundColor: AppColors.primaryCyan,
                  child: Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LANGKAH LIVE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10)),
                          Text(
                            _fmt(_svc.realtimeSteps),
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Tombol ----
                BrutalButton(
                  backgroundColor: AppColors.primaryYellow,
                  onPressed:
                      _svc.busy ? () {} : () => _svc.connectAndAuth(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bluetooth_searching),
                      const SizedBox(width: 8),
                      Text(
                        _svc.ready ? 'HUBUNGKAN ULANG' : 'HUBUNGKAN BAND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BrutalButton(
                  backgroundColor: _svc.ready
                      ? AppColors.primaryPink
                      : AppColors.primaryPeach,
                  onPressed: (_svc.ready && !_svc.busy)
                      ? () => _svc.fetchToday()
                      : () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_download, color: AppColors.white),
                      SizedBox(width: 8),
                      Text('AMBIL DATA HARI INI',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white)),
                    ],
                  ),
                ),

                if (_svc.lastError != null) ...[
                  const SizedBox(height: 16),
                  BrutalContainer(
                    backgroundColor: AppColors.primaryPeach,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_svc.lastError!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
