import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class CacheService {
  // === Profile ===
  Future<void> cacheProfile(Map<String, dynamic> json) async {
    final db = await LocalDatabase.database;
    await db.insert('cached_profile', {
      'id': 1,
      'json_data': jsonEncode(json),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_profile', where: 'id = 1');
    if (results.isEmpty) return null;
    return jsonDecode(results.first['json_data'] as String);
  }

  // === Plants list ===
  Future<void> cachePlants(List<dynamic> jsonList) async {
    final db = await LocalDatabase.database;
    await db.delete('cached_plants');
    for (final item in jsonList) {
      await db.insert('cached_plants', {
        'id': item['id'],
        'json_data': jsonEncode(item),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedPlants() async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_plants');
    if (results.isEmpty) return null;
    return results
        .map((r) => jsonDecode(r['json_data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // === Plant detail ===
  Future<void> cachePlantDetail(int plantId, Map<String, dynamic> json) async {
    final db = await LocalDatabase.database;
    await db.insert('cached_plant_details', {
      'id': plantId,
      'json_data': jsonEncode(json),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedPlantDetail(int plantId) async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_plant_details',
        where: 'id = ?', whereArgs: [plantId]);
    if (results.isEmpty) return null;
    return jsonDecode(results.first['json_data'] as String);
  }

  // === Rooms ===
  Future<void> cacheRooms(List<dynamic> jsonList) async {
    final db = await LocalDatabase.database;
    await db.delete('cached_rooms');
    for (final item in jsonList) {
      await db.insert('cached_rooms', {
        'id': item['id'],
        'json_data': jsonEncode(item),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedRooms() async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_rooms');
    if (results.isEmpty) return null;
    return results
        .map((r) => jsonDecode(r['json_data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // === Events ===
  Future<void> cacheEvents(int plantId, List<dynamic> jsonList) async {
    final db = await LocalDatabase.database;
    await db.insert('cached_events', {
      'plant_id': plantId,
      'json_data': jsonEncode(jsonList),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>?> getCachedEvents(int plantId) async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_events',
        where: 'plant_id = ?', whereArgs: [plantId]);
    if (results.isEmpty) return null;
    return (jsonDecode(results.first['json_data'] as String) as List)
        .cast<Map<String, dynamic>>();
  }

  // === Schedules (today / upcoming) ===
  Future<void> cacheScheduleList(String type, List<dynamic> jsonList) async {
    final db = await LocalDatabase.database;
    await db.delete('cached_schedules', where: 'schedule_type = ?', whereArgs: [type]);
    await db.insert('cached_schedules', {
      'schedule_type': type,
      'json_data': jsonEncode(jsonList),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>?> getCachedScheduleList(String type) async {
    final db = await LocalDatabase.database;
    final results = await db.query('cached_schedules',
        where: 'schedule_type = ?', whereArgs: [type]);
    if (results.isEmpty) return null;
    return (jsonDecode(results.first['json_data'] as String) as List)
        .cast<Map<String, dynamic>>();
  }

  // === Pending actions queue ===
  Future<void> addPendingAction({
    required String actionType,
    required String endpoint,
    required String method,
    String? body,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('pending_actions', {
      'action_type': actionType,
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await LocalDatabase.database;
    return db.query('pending_actions', orderBy: 'created_at ASC');
  }

  Future<void> removePendingAction(int id) async {
    final db = await LocalDatabase.database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await LocalDatabase.database;
    await db.delete('cached_profile');
    await db.delete('cached_plants');
    await db.delete('cached_plant_details');
    await db.delete('cached_rooms');
    await db.delete('cached_events');
    await db.delete('cached_schedules');
    await db.delete('pending_actions');
  }
}
