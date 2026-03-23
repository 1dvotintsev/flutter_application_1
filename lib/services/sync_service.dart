import 'dart:convert';
import 'package:dio/dio.dart';
import 'cache_service.dart';

class SyncService {
  final CacheService _cache;
  final Dio _dio;

  SyncService(this._cache, this._dio);

  Future<void> syncPendingActions() async {
    final actions = await _cache.getPendingActions();
    if (actions.isEmpty) {
      print('No pending actions to sync');
      return;
    }

    print('=== SYNC START: ${actions.length} actions ===');

    for (final action in actions) {
      final method = action['method'] as String;
      final endpoint = action['endpoint'] as String;
      final bodyStr = action['body'] as String?;
      final body = bodyStr != null ? jsonDecode(bodyStr) : null;

      print('Syncing: $method $endpoint body=$body');

      try {
        switch (method) {
          case 'POST':
            final postResp = await _dio.post(endpoint, data: body);
            print('  -> ${postResp.statusCode} OK');
          case 'PUT':
            final putResp = await _dio.put(endpoint, data: body);
            print('  -> ${putResp.statusCode} OK');
          case 'DELETE':
            final delResp = await _dio.delete(endpoint);
            print('  -> ${delResp.statusCode} OK');
        }

        await _cache.removePendingAction(action['id'] as int);
        print('  -> Removed from queue');
      } catch (e) {
        print('  -> FAILED: $e');
        break; // Stop on first error — order matters
      }
    }

    print('=== SYNC END ===');
  }
}
