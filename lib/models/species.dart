class Species {
  final int id;
  final String? commonName;
  final String? scientificName;
  final String? family;
  final String? lightRequirement;
  final String? description;
  final int? waterIntervalDays;
  final int? fertilizeIntervalDays;
  final int? repotIntervalMonths;
  final double? temperatureMin;
  final double? temperatureMax;
  final Map<String, dynamic>? careTips;
  final String? imageUrl;

  Species({
    required this.id,
    this.commonName,
    this.scientificName,
    this.family,
    this.lightRequirement,
    this.description,
    this.waterIntervalDays,
    this.fertilizeIntervalDays,
    this.repotIntervalMonths,
    this.temperatureMin,
    this.temperatureMax,
    this.careTips,
    this.imageUrl,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] as int? ?? 0,
      commonName: json['common_name'] as String?,
      scientificName: json['scientific_name'] as String?,
      family: json['family'] as String?,
      lightRequirement: json['light_requirement'] as String?,
      description: json['description'] as String?,
      waterIntervalDays: json['water_interval_days'] as int?,
      fertilizeIntervalDays: json['fertilize_interval_days'] as int?,
      repotIntervalMonths: json['repot_interval_months'] as int?,
      temperatureMin: (json['temperature_min'] as num?)?.toDouble(),
      temperatureMax: (json['temperature_max'] as num?)?.toDouble(),
      careTips: json['care_tips'] as Map<String, dynamic>?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'common_name': commonName,
      'scientific_name': scientificName,
      'family': family,
      'light_requirement': lightRequirement,
      'description': description,
      'water_interval_days': waterIntervalDays,
      'fertilize_interval_days': fertilizeIntervalDays,
      'repot_interval_months': repotIntervalMonths,
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'care_tips': careTips,
      'image_url': imageUrl,
    };
  }
}
