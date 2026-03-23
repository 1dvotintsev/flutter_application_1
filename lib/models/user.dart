class UserModel {
  final int id;
  final String? email;
  final String? name;
  final String? location;
  final String? experienceLevel;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.location,
    this.experienceLevel,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String?,
      name: json['name'] as String?,
      location: json['location'] as String?,
      experienceLevel: json['experience_level'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'location': location,
      'experience_level': experienceLevel,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
