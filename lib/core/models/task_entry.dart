class TaskEntry {
  final String id;
  final String name;
  final String emoji;
  final TaskType type;
  final int? targetMinutes; // null for binary tasks
  double? actualMinutes;
  bool? done; // for binary tasks

  TaskEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    this.targetMinutes,
    this.actualMinutes,
    this.done,
  });

  double get percentage {
    switch (type) {
      case TaskType.binary:
        return (done == true) ? 100.0 : 0.0;
      case TaskType.minutes:
        if (targetMinutes == null || actualMinutes == null) return 0.0;
        final raw = (actualMinutes! / targetMinutes!) * 100;
        return raw.clamp(0.0, 200.0);
      case TaskType.inverse:
        // Device use — 0 min = 100%, 60+ min = 0%
        final used = actualMinutes ?? 0;
        final raw = ((60 - used) / 60) * 100;
        return raw.clamp(0.0, 100.0);
    }
  }

  TaskEntry copyWith({double? actualMinutes, bool? done}) {
    return TaskEntry(
      id: id,
      name: name,
      emoji: emoji,
      type: type,
      targetMinutes: targetMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      done: done ?? this.done,
    );
  }
}

enum TaskType { binary, minutes, inverse }

class DayData {
  final DateTime date;
  final List<TaskEntry> tasks;

  DayData({required this.date, required this.tasks});

  double get dayScore {
    if (tasks.isEmpty) return 0.0;
    final total = tasks.fold(0.0, (sum, t) => sum + t.percentage);
    return total / tasks.length;
  }

  bool get allPrayersDone {
    final prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return prayerIds.every(
      (id) => tasks.firstWhere((t) => t.id == id, orElse: () => _dummy).done == true,
    );
  }

  static final _dummy = TaskEntry(
    id: '__dummy__',
    name: '',
    emoji: '',
    type: TaskType.binary,
    done: false,
  );
}

List<TaskEntry> buildDefaultTasks() {
  return [
    TaskEntry(id: 'workout', name: 'Workout', emoji: '💪', type: TaskType.minutes, targetMinutes: 45),
    TaskEntry(id: 'skill1', name: 'Skill Block #1', emoji: '📚', type: TaskType.minutes, targetMinutes: 120),
    TaskEntry(id: 'skill2', name: 'Skill Block #2', emoji: '📚', type: TaskType.minutes, targetMinutes: 120),
    TaskEntry(id: 'project', name: 'Project / Build', emoji: '🛠️', type: TaskType.minutes, targetMinutes: 120),
    TaskEntry(id: 'skill3', name: 'Skill Block #3 / Reading', emoji: '📖', type: TaskType.minutes, targetMinutes: 90),
    TaskEntry(id: 'fajr', name: 'Fajr Namaz', emoji: '🕌', type: TaskType.binary),
    TaskEntry(id: 'dhuhr', name: 'Dhuhr Namaz', emoji: '🕌', type: TaskType.binary),
    TaskEntry(id: 'asr', name: 'Asr Namaz', emoji: '🕌', type: TaskType.binary),
    TaskEntry(id: 'maghrib', name: 'Maghrib Namaz', emoji: '🕌', type: TaskType.binary),
    TaskEntry(id: 'isha', name: 'Isha Namaz', emoji: '🕌', type: TaskType.binary),
    TaskEntry(id: 'breakfast', name: 'Breakfast', emoji: '🍽️', type: TaskType.binary),
    TaskEntry(id: 'lunch', name: 'Lunch', emoji: '🍽️', type: TaskType.binary),
    TaskEntry(id: 'dinner', name: 'Dinner', emoji: '🍽️', type: TaskType.binary),
    TaskEntry(id: 'family', name: 'Family Time', emoji: '👨‍👩‍👦', type: TaskType.minutes, targetMinutes: 30),
    TaskEntry(id: 'device', name: 'Mindless Device Use', emoji: '📵', type: TaskType.inverse),
    TaskEntry(id: 'sleep', name: 'Sleep', emoji: '😴', type: TaskType.minutes, targetMinutes: 450),
    TaskEntry(id: 'journal', name: 'Daily Review / Journal', emoji: '📝', type: TaskType.binary),
  ];
}

