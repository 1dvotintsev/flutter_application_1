class SchedulePlant {
  final String? nickname;
  final String? photoUrl;

  SchedulePlant({this.nickname, this.photoUrl});

  factory SchedulePlant.fromJson(Map<String, dynamic> json) {
    return SchedulePlant(
      nickname: json['nickname'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class CareSchedule {
  final int id;
  final int? plantId;
  final int? intervalDays;
  final String? careType;
  final DateTime? nextDue;
  final DateTime? updatedAt;
  final double? seasonCoefficient;
  final bool notified;
  final bool isActive;
  final SchedulePlant? plant;

  CareSchedule({
    required this.id,
    this.plantId,
    this.intervalDays,
    this.careType,
    this.nextDue,
    this.updatedAt,
    this.seasonCoefficient,
    required this.notified,
    required this.isActive,
    this.plant,
  });

  factory CareSchedule.fromJson(Map<String, dynamic> json) {
    print('Parsing schedule: id=${json['id'] ?? json['schedule_id']} nextDue=${json['next_due']} isActive=${json['is_active']}');
    // Сервер возвращает плоскую структуру: plant_nickname, plant_photo_url
    // вместо вложенного объекта plant
    final plantNickname = json['plant_nickname'] as String?;
    final plantPhotoUrl = json['plant_photo_url'] as String?;
    final hasPlantData = plantNickname != null || plantPhotoUrl != null;

    return CareSchedule(
      id: ((json['id'] ?? json['schedule_id']) as num?)?.toInt() ?? 0,
      plantId: (json['plant_id'] as num?)?.toInt(),
      intervalDays: (json['interval_days'] as num?)?.toInt(),
      careType: json['care_type'] as String?,
      nextDue: json['next_due'] != null
          ? DateTime.parse(json['next_due'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      seasonCoefficient: (json['season_coefficient'] as num?)?.toDouble(),
      notified: json['notified'] as bool? ?? false,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      plant: json['plant'] != null
          ? SchedulePlant.fromJson(json['plant'] as Map<String, dynamic>)
          : hasPlantData
              ? SchedulePlant(
                  nickname: plantNickname,
                  photoUrl: plantPhotoUrl,
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'interval_days': intervalDays,
      'care_type': careType,
      'next_due': nextDue?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'season_coefficient': seasonCoefficient,
      'notified': notified,
      'is_active': isActive,
    };
  }
}
