import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    ref.read(authServiceProvider),
    ref.read(cacheServiceProvider),
    ref.read(connectivityServiceProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(cacheServiceProvider),
    ref.read(apiServiceProvider).dio,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Stream провайдер для отслеживания статуса сети в UI.
/// Выдаёт начальное значение сразу, затем обновления при изменении.
final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield service.isOnline;
  yield* service.connectionChange.stream;
});
