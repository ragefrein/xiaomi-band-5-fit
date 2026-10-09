import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/heart_rate_screen.dart';

void main() {
  runApp(const KinetixApp());
}

class KinetixApp extends StatelessWidget {
  const KinetixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinetix Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StepsScreen(),
    const SleepScreen(),
    const HeartRateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.black, width: 3)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.black,
          unselectedItemColor: AppColors.black.withValues(alpha: 0.5),
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          items: [
            _buildNavItem(Icons.dashboard, 'Beranda', 0),
            _buildNavItem(Icons.directions_walk, 'Langkah', 1),
            _buildNavItem(Icons.bedtime, 'Tidur', 2),
            _buildNavItem(Icons.favorite, 'Jantung', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: Offset(2, 2),
                  )
                ],
              )
            : null,
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
