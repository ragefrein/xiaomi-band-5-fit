import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_container.dart';
import '../widgets/brutal_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            const Icon(Icons.fitness_center, color: AppColors.black), // Placeholder for logo
            const SizedBox(width: 8),
            Text('KINETIX', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                border: Border.all(color: AppColors.black, width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(1.5, 1.5))],
              ),
              child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPeach,
              border: Border.all(color: AppColors.black, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))],
            ),
            child: const Center(child: Text('BERANDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black))),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPink,
              border: Border.all(color: AppColors.black, width: 2.5),
              boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))],
            ),
            child: const Icon(Icons.person, color: AppColors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
          ],
        ),
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
            Text('Halo, Rian! 🔥', style: Theme.of(context).textTheme.displaySmall),
            Text('Target harianmu hampir tercapai!', style: Theme.of(context).textTheme.bodyMedium),
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
              boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))],
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, size: 18),
                SizedBox(width: 4),
                Text('STREAK 12 HARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
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
                  boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))],
                ),
                child: const Text('AKTIVITAS HARI INI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Row(
                children: [
                  Text('84%', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.black,
                    child: const Text('HAMPIR BERES!', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Placeholder for Donut Chart
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 4),
                ),
                child: const Center(child: Icon(Icons.bolt, size: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildProgressRow('Langkah', '8.420 / 10k', AppColors.primaryCyan, 0.84),
                    const SizedBox(height: 8),
                    _buildProgressRow('Kalori', '540 / 650 kkal', AppColors.primaryPink, 0.83),
                    const SizedBox(height: 8),
                    _buildProgressRow('Waktu', '45 / 60 mnt', AppColors.black, 0.75),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, Color color, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.black))),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.black, width: 2), borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(color: color, border: const Border(right: BorderSide(color: AppColors.black, width: 2))),
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
              decoration: BoxDecoration(color: AppColors.primaryYellow, border: Border.all(color: AppColors.black, width: 1.5), borderRadius: BorderRadius.circular(4)),
              child: const Text('Ketuk & Catat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 12),
        BrutalButton(
          onPressed: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: AppColors.white),
              SizedBox(width: 8),
              Text('MULAI LATIHAN ⚡', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: BrutalContainer(backgroundColor: AppColors.primaryCyan, padding: const EdgeInsets.all(12), child: _buildMiniAction('Hidrasi', '2.1L', Icons.water_drop))),
            const SizedBox(width: 12),
            Expanded(child: BrutalContainer(backgroundColor: AppColors.primaryPeach, padding: const EdgeInsets.all(12), child: _buildMiniAction('Nutrisi', '1.480 kkal', Icons.restaurant))),
          ],
        )
      ],
    );
  }

  Widget _buildMiniAction(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.black), borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(1, 1))]),
              child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.black), boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(1, 1))]),
              child: Icon(icon, size: 14),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildFitnessMetrics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('METRIK', style: Theme.of(context).textTheme.titleLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryMint, border: Border.all(color: AppColors.black, width: 2), borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))]),
              child: const Text('SINKRONISASI OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 12),
        BrutalContainer(
          backgroundColor: AppColors.primaryMint,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.black, width: 2), boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))]), child: const Icon(Icons.directions_walk)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('8.420 Langkah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('↑ 18% vs kemarin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))])),
            ],
          )
        ),
        const SizedBox(height: 12),
        BrutalContainer(
          backgroundColor: AppColors.primaryLavender,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.black, width: 2), boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))]), child: const Icon(Icons.bedtime)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('7j 25m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('Kualitas: Nyenyak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))])),
            ],
          )
        ),
      ],
    );
  }
}
