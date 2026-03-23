import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import 'auth_provider.dart';

final roomsProvider = FutureProvider.autoDispose<List<Room>>((ref) async {
  return ref.read(apiServiceProvider).getRooms();
});
