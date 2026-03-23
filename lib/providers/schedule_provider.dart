import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/care_schedule.dart';
import '../models/plant.dart';
import 'auth_provider.dart';

final todayTasksProvider =
    FutureProvider.autoDispose<List<CareSchedule>>((ref) async {
  return ref.read(apiServiceProvider).getTodayTasks();
});

class UpcomingItem {
  final CareSchedule schedule;
  final Plant plant;
  final int daysUntil;

  UpcomingItem({
    required this.schedule,
    required this.plant,
    required this.daysUntil,
  });
}

final upcomingSchedulesProvider =
    FutureProvider.autoDispose<List<UpcomingItem>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final plants = await api.getPlants();
  print('Loaded ${plants.length} plants');

  final todayDate = DateTime.now();
  final today =
      DateTime(todayDate.year, todayDate.month, todayDate.day);

  final List<UpcomingItem> upcoming = [];
  for (final plant in plants) {
    try {
      final full = await api.getPlant(plant.id);
      print('Plant ${full.nickname}: schedules=${full.schedules?.length ?? 0} careSchedules=${full.careSchedules?.length ?? 0}');
      for (final s in full.careSchedules ?? []) {
        final daysUntil = s.nextDue != null
            ? DateTime(s.nextDue!.year, s.nextDue!.month, s.nextDue!.day)
                .difference(today)
                .inDays
            : null;
        print('  ${s.careType} nextDue=${s.nextDue} isActive=${s.isActive} daysUntil=$daysUntil');
        if (!s.isActive || s.nextDue == null || daysUntil == null) continue;
        if (daysUntil > 0 && daysUntil <= 7) {
          upcoming.add(UpcomingItem(schedule: s, plant: full, daysUntil: daysUntil));
        }
      }
    } catch (e) {
      print('Error loading plant ${plant.id}: $e');
    }
  }

  print('Total upcoming: ${upcoming.length}');
  upcoming.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  return upcoming;
});
