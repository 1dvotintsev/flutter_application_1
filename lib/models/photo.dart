class Photo {
  final int id;
  final int? plantId;
  final String? url;
  final String? s3Key;
  final String? purpose;
  final DateTime? uploadedAt;
  final bool isPrimary;

  Photo({
    required this.id,
    this.plantId,
    this.url,
    this.s3Key,
    this.purpose,
    this.uploadedAt,
    required this.isPrimary,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int? ?? 0,
      plantId: json['plant_id'] as int?,
      url: json['url'] as String?,
      s3Key: json['s3_key'] as String?,
      purpose: json['purpose'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'url': url,
      's3_key': s3Key,
      'purpose': purpose,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'is_primary': isPrimary,
    };
  }
}
