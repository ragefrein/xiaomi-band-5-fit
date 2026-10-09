import 'package:flutter/material.dart';

import '../services/miband_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_container.dart';
import '../widgets/brutal_button.dart';
import '../widgets/connect_dialog.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  String _fmtDur(Duration d) {
    if (d == Duration.zero) return '0j 0m';
    return '${d.inHours}j ${d.inMinutes % 60}m';
  }

  Future<void> _openConnect() async {
    final ok = await showConnectDialog(context);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Band terhubung ✔')),
      );
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
        title: Row(
          children: [
            const Icon(Icons.fitness_center, color: AppColors.black),
            const SizedBox(width: 8),
            Text('RAGE FIT', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _svc,
            builder: (context, _) {
              final ready = _svc.ready;
              return GestureDetector(
                onTap: _svc.busy ? null : _openConnect,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: ready ? AppColors.primaryMint : AppColors.primaryPeach,
                    border: Border.all(color: AppColors.black, width: 2),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                    ],
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        Icon(ready ? Icons.bluetooth_connected : Icons.bluetooth,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          ready ? 'CONNECTED' : 'CONNECT',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPink,
              border: Border.all(color: AppColors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: AppColors.black, offset: Offset(2, 2))
              ],
            ),
            child: const Icon(Icons.person, color: AppColors.white),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _svc,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 16),
                _buildHeroCard(context),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildFitnessMetrics(context),
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

  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, Rian! 🔥',
                style: Theme.of(context).textTheme.displaySmall),
            Text('Target harianmu hampir tercapai!',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Transform.rotate(
          angle: -0.05,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              border: Border.all(color: AppColors.black, width: 3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: AppColors.black, offset: Offset(3, 3))
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, size: 18),
                SizedBox(width: 4),
                Text('STREAK 12 HARI',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final steps = _svc.realtimeSteps > 0
        ? _svc.realtimeSteps
        : _svc.todaySteps;
    final stepGoal = 10000;
    final stepProgress = (steps / stepGoal).clamp(0.0, 1.0).toDouble();
    final kcal = _svc.todayCalories;
    final kcalGoal = 650.0;
    final kcalProgress = (kcal / kcalGoal).clamp(0.0, 1.0).toDouble();
    final overall = ((stepProgress + kcalProgress) / 2);
    final pct = (overall * 100).round();

    return BrutalContainer(
      backgroundColor: AppColors.primaryYellow,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.black, width: 2),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                  ],
                ),
                child: const Text('AKTIVITAS HARI INI',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Row(
                children: [
                  Text('$pct%', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.black,
                    child: Text(
                      pct >= 100 ? 'TUNTAS!' : 'HAMPIR BERES!',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 4),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cincin progres sederhana.
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(
                          value: overall,
                          strokeWidth: 8,
                          backgroundColor: AppColors.white,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primaryPink),
                        ),
                      ),
                      Text('$pct%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildProgressRow('Langkah', '${_fmt(steps)} / 10k',
                        AppColors.primaryCyan, stepProgress),
                    const SizedBox(height: 8),
                    _buildProgressRow('Kalori',
                        '${kcal.round()} / ${kcalGoal.round()} kkal',
                        AppColors.primaryPink, kcalProgress),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressRow(
      String label, String value, Color color, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black))),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.black, width: 2),
              borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                  color: color,
                  border: const Border(
                      right: BorderSide(color: AppColors.black, width: 2))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AKSI CEPAT', style: Theme.of(context).textTheme.titleLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  border: Border.all(color: AppColors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('Ketuk & Catat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 12),
        BrutalButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutScreen()),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: AppColors.white),
              SizedBox(width: 8),
              Text('MULAI LATIHAN ⚡',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Detak jantung live (menggantikan "Hidrasi").
              Expanded(child: _buildHeartRateCard()),
              const SizedBox(width: 12),
              // Kalori terbakar (menggantikan "Nutrisi").
              Expanded(child: _buildCaloriesCard()),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHeartRateCard() {
    final bpm = _svc.heartRate;
    return BrutalContainer(
      backgroundColor: AppColors.primaryCyan,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.black),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(1, 1))
                    ]),
                child: const Text('JANTUNG',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(1, 1))
                    ]),
                child: const Icon(Icons.favorite, size: 14),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(bpm == null ? '--' : '$bpm',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 28)),
              const SizedBox(width: 4),
              const Text('BPM',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: (_svc.ready && !_svc.measuringHr)
                ? () => _svc.measureHeartRate()
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: AppColors.black, offset: Offset(1.5, 1.5))
                ],
              ),
              child: Center(
                child: Text(
                  _svc.measuringHr ? 'MENGUKUR…' : 'UKUR',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final kcal = _svc.todayCalories;
    return BrutalContainer(
      backgroundColor: AppColors.primaryPeach,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.black),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(1, 1))
                    ]),
                child: const Text('KALORI',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(1, 1))
                    ]),
                child: const Icon(Icons.local_fire_department, size: 14),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_fmt(kcal.round()),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 28)),
              const SizedBox(width: 4),
              const Text('kkal',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kcal > 0 ? 'TERBAKAR HARI INI' : 'AMBIL DATA UNTUK MULAI',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessMetrics(BuildContext context) {
    final steps = _svc.realtimeSteps > 0 ? _svc.realtimeSteps : _svc.todaySteps;
    final hasSleep = _svc.sleepDuration > Duration.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('METRIK', style: Theme.of(context).textTheme.titleLarge),
            GestureDetector(
              onTap: _svc.ready
                  ? () async {
                      await _svc.fetchToday();
                      await _svc.fetchSleep();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _svc.ready
                        ? AppColors.primaryMint
                        : AppColors.primaryPeach,
                    border: Border.all(color: AppColors.black, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                    ]),
                child: Text(
                    _svc.ready ? 'SINKRONKAN DATA' : 'BAND BELUM TERHUBUNG',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        BrutalContainer(
          backgroundColor: AppColors.primaryMint,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                      ]),
                  child: const Icon(Icons.directions_walk)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_fmt(steps)} Langkah',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                        steps > 0
                            ? '${_svc.samples.length} menit sampel hari ini'
                            : 'Tekan SINKRONKAN DATA',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BrutalContainer(
          backgroundColor: AppColors.primaryLavender,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(2, 2))
                      ]),
                  child: const Icon(Icons.bedtime)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasSleep ? _fmtDur(_svc.sleepDuration) : 'Belum ada data',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                        hasSleep
                            ? 'Nyenyak ${_fmtDur(_svc.deepSleep)} • REM ${_fmtDur(_svc.remSleep)}'
                            : 'Tekan SINKRONKAN DATA',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
