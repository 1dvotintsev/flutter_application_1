import 'plant.dart';
import 'species.dart';
import 'care_schedule.dart';

class PlantIdentifyResult {
  final Plant? plant;
  final Species? species;
  final List<CareSchedule>? schedules;

  PlantIdentifyResult({
    this.plant,
    this.species,
    this.schedules,
  });

  factory PlantIdentifyResult.fromJson(Map<String, dynamic> json) {
    return PlantIdentifyResult(
      plant: json['plant'] != null
          ? Plant.fromJson(json['plant'] as Map<String, dynamic>)
          : null,
      species: json['species'] != null
          ? Species.fromJson(json['species'] as Map<String, dynamic>)
          : null,
      schedules: json['schedules'] != null
          ? (json['schedules'] as List<dynamic>)
              .map((e) => CareSchedule.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}
