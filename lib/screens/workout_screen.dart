import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/brutal_container.dart';

/// Daftar jenis latihan. GPS menyusul — untuk sekarang hanya jenis latihannya.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

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
        title: const Text('LATIHAN',
            style:
                TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrutalContainer(
              backgroundColor: AppColors.primaryYellow,
              child: const Row(
                children: [
                  Icon(Icons.bolt, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PILIH JENIS LATIHAN. PELACAKAN GPS MENYUSUL.',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: const [
                _WorkoutCard(
                  label: 'LARI',
                  icon: Icons.directions_run,
                  color: AppColors.primaryPink,
                ),
                _WorkoutCard(
                  label: 'JALAN',
                  icon: Icons.directions_walk,
                  color: AppColors.primaryCyan,
                ),
                _WorkoutCard(
                  label: 'BERSEPEDA',
                  icon: Icons.directions_bike,
                  color: AppColors.primaryMint,
                ),
                _WorkoutCard(
                  label: 'TREADMILL',
                  icon: Icons.fitness_center,
                  color: AppColors.primaryLavender,
                ),
                _WorkoutCard(
                  label: 'Yoga',
                  icon: Icons.self_improvement,
                  color: AppColors.primaryPeach,
                ),
                _WorkoutCard(
                  label: 'Renang',
                  icon: Icons.pool,
                  color: AppColors.primaryOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: BrutalContainer(
        backgroundColor: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('SEGERA',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Latihan $label — pelacakan GPS menyusul.')),
    );
  }
}
