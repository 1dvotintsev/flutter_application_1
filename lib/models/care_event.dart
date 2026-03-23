class CareEvent {
  final int id;
  final int? plantId;
  final int? scheduleId;
  final String? careType;
  final String? notes;
  final String? photoUrl;
  final DateTime? performedAt;
  final DateTime createdAt;

  CareEvent({
    required this.id,
    this.plantId,
    this.scheduleId,
    this.careType,
    this.notes,
    this.photoUrl,
    this.performedAt,
    required this.createdAt,
  });

  factory CareEvent.fromJson(Map<String, dynamic> json) {
    return CareEvent(
      id: json['id'] as int? ?? 0,
      plantId: json['plant_id'] as int?,
      scheduleId: json['schedule_id'] as int?,
      careType: json['care_type'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      performedAt: json['performed_at'] != null
          ? DateTime.parse(json['performed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'schedule_id': scheduleId,
      'care_type': careType,
      'notes': notes,
      'photo_url': photoUrl,
      'performed_at': performedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
