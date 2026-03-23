import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/species.dart';
import 'auth_provider.dart';

final speciesSearchProvider =
    FutureProvider.autoDispose.family<List<Species>, String>((ref, query) async {
  return ref.read(apiServiceProvider).searchSpecies(query);
});
