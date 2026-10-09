import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brutal_container.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5FF),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(color: AppColors.black, height: 2.5),
        ),
        title: const Text('TIDUR SEMALAM', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BrutalContainer(
              backgroundColor: AppColors.primaryLavender,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('KUALITAS PEMULIHAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('SANGAT NYENYAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, backgroundColor: AppColors.primaryYellow)),
                    ],
                  ),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('88', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Text('/100', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Durasi', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('7j 25m', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.93,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF9B5DE5),
                          border: Border(right: BorderSide(color: AppColors.black, width: 2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BrutalContainer(
              backgroundColor: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FASE TIDUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildPhase(const Color(0xFFA2D2FF), 'Dalam', '1j 45m')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPhase(const Color(0xFFE8AEFF), 'REM', '2j 05m')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildPhase(const Color(0xFFB9FBC0), 'Ringan', '3j 20m')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPhase(AppColors.primaryPeach, 'Bangun', '15m')),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPhase(Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
