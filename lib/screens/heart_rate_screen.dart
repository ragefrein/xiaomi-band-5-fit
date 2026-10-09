import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_container.dart';
import '../widgets/brutal_button.dart';

class HeartRateScreen extends StatelessWidget {
  const HeartRateScreen({super.key});

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
        title: const Text('JANTUNG', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BrutalContainer(
              backgroundColor: AppColors.primaryPink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MONITOR AKTIF • LIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, backgroundColor: AppColors.primaryYellow)),
                      Text('BAND 8 PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, backgroundColor: AppColors.primaryCyan)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('72', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Text('BPM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          border: Border.all(color: AppColors.black, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))],
                        ),
                        child: const Icon(Icons.favorite, color: AppColors.primaryPink, size: 36),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: AppColors.primaryCyan),
                        SizedBox(width: 8),
                        Text('Detak Jantung Istirahat Normal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: BrutalContainer(
                    backgroundColor: AppColors.primaryLavender,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HRV', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('65 ms', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalContainer(
                    backgroundColor: AppColors.primaryMint,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STRES', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('28/100', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BrutalButton(
              backgroundColor: AppColors.primaryYellow,
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart),
                  SizedBox(width: 8),
                  Text('UKUR MANUAL SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
