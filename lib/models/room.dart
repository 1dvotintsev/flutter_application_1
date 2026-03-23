class Room {
  final int id;
  final int? userId;
  final String? name;
  final String? lightLevel;
  final String? windowDirection;
  final String? notes;

  Room({
    required this.id,
    this.userId,
    this.name,
    this.lightLevel,
    this.windowDirection,
    this.notes,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      name: json['name'] as String?,
      lightLevel: json['light_level'] as String?,
      windowDirection: json['window_direction'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'light_level': lightLevel,
      'window_direction': windowDirection,
      'notes': notes,
    };
  }
}
