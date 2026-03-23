import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import 'auth_provider.dart';

final plantsProvider =
    FutureProvider.autoDispose.family<List<Plant>, int?>((ref, roomId) async {
  return ref.read(apiServiceProvider).getPlants(roomId: roomId);
});

final plantDetailProvider =
    FutureProvider.autoDispose.family<Plant, int>((ref, id) async {
  return ref.read(apiServiceProvider).getPlant(id);
});
