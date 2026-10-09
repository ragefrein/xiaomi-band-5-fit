import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_SESSION,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    await Permission.activityRecognition.request();
    await Permission.location.request();

    bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
    if (hasPermissions == false) {
      bool authorized = await _health.requestAuthorization(types, permissions: permissions);
      return authorized;
    }
    return true;
  }

  Future<int> fetchStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    int? steps = await _health.getTotalStepsInInterval(midnight, now);
    return steps ?? 0;
  }

  Future<List<HealthDataPoint>> fetchHeartRateToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE],
      startTime: midnight,
      endTime: now,
    );
    return healthData;
  }

  Future<List<HealthDataPoint>> fetchSleepData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      types: [HealthDataType.SLEEP_SESSION],
      startTime: yesterday,
      endTime: now,
    );
    return healthData;
  }
}
