import 'species.dart';
import 'room.dart';
import 'care_schedule.dart';

class Plant {
  final int id;
  final int? userId;
  final int? speciesId;
  final int? roomId;
  final String? nickname;
  final String? potType;
  final String? soilType;
  final String? photoUrl;
  final String? speciesImageUrl;
  final DateTime? acquiredDate;
  final DateTime createdAt;
  final bool isActive;
  final Species? species;
  final Room? room;
  final List<CareSchedule>? schedules;
  final List<CareSchedule>? careSchedules;

  Plant({
    required this.id,
    this.userId,
    this.speciesId,
    this.roomId,
    this.nickname,
    this.potType,
    this.soilType,
    this.photoUrl,
    this.speciesImageUrl,
    this.acquiredDate,
    required this.createdAt,
    required this.isActive,
    this.species,
    this.room,
    this.schedules,
    this.careSchedules,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      speciesId: json['species_id'] as int?,
      roomId: json['room_id'] as int?,
      nickname: json['nickname'] as String?,
      potType: json['pot_type'] as String?,
      soilType: json['soil_type'] as String?,
      photoUrl: json['photo_url'] as String?,
      speciesImageUrl: json['species_image_url'] as String?,
      acquiredDate: json['acquired_date'] != null
          ? DateTime.parse(json['acquired_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? false,
      species: json['species'] != null
          ? Species.fromJson(json['species'] as Map<String, dynamic>)
          : null,
      room: json['room'] != null
          ? Room.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      schedules: ((json['schedules'] ?? json['care_schedules']) as List<dynamic>?)
          ?.map((e) => CareSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      careSchedules: (json['care_schedules'] as List<dynamic>?)
          ?.map((e) => CareSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'species_id': speciesId,
      'room_id': roomId,
      'nickname': nickname,
      'pot_type': potType,
      'soil_type': soilType,
      'photo_url': photoUrl,
      'acquired_date': acquiredDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'species': species?.toJson(),
      'room': room?.toJson(),
      'schedules': schedules?.map((e) => e.toJson()).toList(),
    };
  }
}
