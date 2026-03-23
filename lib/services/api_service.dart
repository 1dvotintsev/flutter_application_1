import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/plant.dart';
import '../models/species.dart';
import '../models/room.dart';
import '../models/care_schedule.dart';
import '../models/care_event.dart';
import '../models/plant_identify_result.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'local_database.dart';

class ApiService {
  final AuthService _authService;
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;
  late final Dio _dio;

  Dio get dio => _dio;

  ApiService(this._authService, this._cacheService, this._connectivityService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // TODO: redirect to login
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedProfile();
      if (cached != null) return UserModel.fromJson(cached);
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get('/users/me');
      await _cacheService.cacheProfile(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      final cached = await _cacheService.getCachedProfile();
      if (cached != null) return UserModel.fromJson(cached);
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'update_profile',
        endpoint: '/auth/profile',
        method: 'POST',
        body: jsonEncode(data),
      );
      final cached = await _cacheService.getCachedProfile();
      if (cached != null) {
        cached.addAll(data);
        await _cacheService.cacheProfile(cached);
        return UserModel.fromJson(cached);
      }
      throw Exception('Нет подключения к интернету');
    }
    final response = await _dio.post('/auth/profile', data: data);
    await _cacheService.cacheProfile(response.data as Map<String, dynamic>);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Plants ─────────────────────────────────────────────────────────────────

  Future<List<Plant>> getPlants({int? roomId}) async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedPlants();
      if (cached != null) {
        final plants = cached.map((e) => Plant.fromJson(e)).toList();
        if (roomId == null) return plants;
        // Фильтрация по комнате: список может не содержать room_id,
        // поэтому сверяемся с кэшем деталей каждого растения.
        final filtered = <Plant>[];
        for (final plant in plants) {
          final detail =
              await _cacheService.getCachedPlantDetail(plant.id);
          final detailRoomId = detail?['room_id'];
          if (detailRoomId == roomId) {
            filtered.add(plant);
          }
        }
        return filtered;
      }
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get(
        '/plants',
        queryParameters: roomId != null ? {'room_id': roomId} : null,
      );
      // Кэшировать только полный список (без фильтра по комнате).
      if (roomId == null) {
        await _cacheService.cachePlants(response.data as List<dynamic>);
      }
      return (response.data as List<dynamic>)
          .map((e) => Plant.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cached = await _cacheService.getCachedPlants();
      if (cached != null) {
        final plants = cached.map((e) => Plant.fromJson(e)).toList();
        if (roomId == null) return plants;
        final filtered = <Plant>[];
        for (final plant in plants) {
          final detail =
              await _cacheService.getCachedPlantDetail(plant.id);
          if (detail?['room_id'] == roomId) filtered.add(plant);
        }
        return filtered;
      }
      rethrow;
    }
  }

  Future<Plant> getPlant(int id) async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedPlantDetail(id);
      if (cached != null) return Plant.fromJson(cached);
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get('/plants/$id');
      await _cacheService.cachePlantDetail(
          id, response.data as Map<String, dynamic>);
      return Plant.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      final cached = await _cacheService.getCachedPlantDetail(id);
      if (cached != null) return Plant.fromJson(cached);
      rethrow;
    }
  }

  Future<Plant> createPlant(Map<String, dynamic> data) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      final response = await _dio.post('/plants', data: data);
      return Plant.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Plant> updatePlant(int id, Map<String, dynamic> data) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'update_plant',
        endpoint: '/plants/$id',
        method: 'PUT',
        body: jsonEncode(data),
      );
      final cached = await _cacheService.getCachedPlantDetail(id);
      if (cached != null) {
        cached.addAll(data);
        await _cacheService.cachePlantDetail(id, cached);
        return Plant.fromJson(cached);
      }
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.put('/plants/$id', data: data);
      return Plant.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePlant(int id) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'delete_plant',
        endpoint: '/plants/$id',
        method: 'DELETE',
      );
      final db = await LocalDatabase.database;
      await db.delete('cached_plants', where: 'id = ?', whereArgs: [id]);
      await db.delete('cached_plant_details', where: 'id = ?', whereArgs: [id]);
      return;
    }
    await _dio.delete('/plants/$id');
    final db = await LocalDatabase.database;
    await db.delete('cached_plants', where: 'id = ?', whereArgs: [id]);
    await db.delete('cached_plant_details', where: 'id = ?', whereArgs: [id]);
  }

  // ── Identify ───────────────────────────────────────────────────────────────

  Future<PlantIdentifyResult> identifyPlant(String imageBase64) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      final response = await _dio.post(
        '/plants/identify',
        data: {'image_base64': imageBase64},
        options: Options(receiveTimeout: ApiConfig.identifyTimeout),
      );
      return PlantIdentifyResult.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // ── Schedule ───────────────────────────────────────────────────────────────

  Future<List<CareSchedule>> getTodayTasks() async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedScheduleList('today');
      if (cached != null) {
        return cached.map((e) => CareSchedule.fromJson(e)).toList();
      }
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get('/schedule/today');
      await _cacheService.cacheScheduleList(
          'today', response.data as List<dynamic>);
      return (response.data as List<dynamic>)
          .map((e) => CareSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cached = await _cacheService.getCachedScheduleList('today');
      if (cached != null) {
        return cached.map((e) => CareSchedule.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<List<CareSchedule>> getUpcomingTasks({int days = 7}) async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedScheduleList('upcoming');
      if (cached != null) {
        return cached.map((e) => CareSchedule.fromJson(e)).toList();
      }
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get(
        '/schedule/upcoming',
        queryParameters: {'days': days},
      );
      await _cacheService.cacheScheduleList(
          'upcoming', response.data as List<dynamic>);
      return (response.data as List<dynamic>)
          .map((e) => CareSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cached = await _cacheService.getCachedScheduleList('upcoming');
      if (cached != null) {
        return cached.map((e) => CareSchedule.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<CareSchedule> updateScheduleInterval(
      int scheduleId, int intervalDays) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'update_schedule_interval',
        endpoint: '/schedule/$scheduleId',
        method: 'PUT',
        body: jsonEncode({'interval_days': intervalDays}),
      );
      // Обновить кэш деталей растения с новым интервалом и пересчитанным next_due
      final db = await LocalDatabase.database;
      final allDetails = await db.query('cached_plant_details');
      for (final row in allDetails) {
        final detail =
            jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        final schedules = detail['care_schedules'] as List?;
        if (schedules == null) continue;
        for (int i = 0; i < schedules.length; i++) {
          if (schedules[i]['id'] == scheduleId) {
            final coeff =
                (schedules[i]['season_coefficient'] as num?)?.toDouble() ?? 1.0;
            final newNextDue = DateTime.now()
                .add(Duration(days: (intervalDays * coeff).round()));
            schedules[i] = Map<String, dynamic>.from(
                schedules[i] as Map<String, dynamic>)
              ..['interval_days'] = intervalDays
              ..['next_due'] = newNextDue.toUtc().toIso8601String();
            detail['care_schedules'] = schedules;
            await _cacheService.cachePlantDetail(
                detail['id'] as int, detail);
            return CareSchedule.fromJson(
                schedules[i] as Map<String, dynamic>);
          }
        }
      }
      throw Exception('Schedule не найден в кэше');
    }
    try {
      final response = await _dio.put(
        '/schedule/$scheduleId',
        data: {'interval_days': intervalDays},
      );
      return CareSchedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeSchedule(int id) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'complete_schedule',
        endpoint: '/schedule/$id/complete',
        method: 'POST',
      );
      return {'status': 'queued'};
    }
    try {
      final response = await _dio.post('/schedule/$id/complete');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> snoozeSchedule(int id) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'snooze_schedule',
        endpoint: '/schedule/$id/snooze',
        method: 'POST',
      );
      return {'status': 'queued'};
    }
    try {
      final response = await _dio.post('/schedule/$id/snooze');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<List<CareEvent>> getPlantEvents(int plantId) async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedEvents(plantId);
      if (cached != null) {
        return cached.map((e) => CareEvent.fromJson(e)).toList();
      }
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get('/plants/$plantId/events');
      await _cacheService.cacheEvents(plantId, response.data as List<dynamic>);
      return (response.data as List<dynamic>)
          .map((e) => CareEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cached = await _cacheService.getCachedEvents(plantId);
      if (cached != null) {
        return cached.map((e) => CareEvent.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<CareEvent> createEvent(int plantId, Map<String, dynamic> data) async {
    if (!_connectivityService.isOnline) {
      await _cacheService.addPendingAction(
        actionType: 'create_event',
        endpoint: '/plants/$plantId/events',
        method: 'POST',
        body: jsonEncode(data),
      );
      return CareEvent.fromJson({
        'id': -DateTime.now().millisecondsSinceEpoch,
        'plant_id': plantId,
        'care_type': data['care_type'],
        'notes': data['notes'],
        'performed_at':
            data['performed_at'] ?? DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    try {
      final response =
          await _dio.post('/plants/$plantId/events', data: data);
      return CareEvent.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // ── Species ────────────────────────────────────────────────────────────────

  Future<List<Species>> searchSpecies(String query) async {
    try {
      final response =
          await _dio.get('/species', queryParameters: {'q': query});
      return (response.data as List<dynamic>)
          .map((e) => Species.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Species> getSpecies(int id) async {
    try {
      final response = await _dio.get('/species/$id');
      return Species.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // ── Rooms ──────────────────────────────────────────────────────────────────

  Future<List<Room>> getRooms() async {
    if (!_connectivityService.isOnline) {
      final cached = await _cacheService.getCachedRooms();
      if (cached != null) return cached.map((e) => Room.fromJson(e)).toList();
      throw Exception('Нет подключения к интернету');
    }
    try {
      final response = await _dio.get('/rooms');
      await _cacheService.cacheRooms(response.data as List<dynamic>);
      return (response.data as List<dynamic>)
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cached = await _cacheService.getCachedRooms();
      if (cached != null) return cached.map((e) => Room.fromJson(e)).toList();
      rethrow;
    }
  }

  Future<Room> createRoom(Map<String, dynamic> data) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      final response = await _dio.post('/rooms', data: data);
      return Room.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Room> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/rooms/$id', data: data);
      return Room.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoom(int id) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      await _dio.delete('/rooms/$id');
    } catch (e) {
      rethrow;
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> updateDeviceToken(String token) async {
    try {
      await _dio.post('/auth/device-token', data: {'device_token': token});
    } catch (e) {
      rethrow;
    }
  }

  // ── Photo uploads ──────────────────────────────────────────────────────────

  Future<UserModel> uploadAvatar(String filePath) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/auth/avatar', data: formData);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Plant> uploadPlantPhoto(int plantId, String filePath) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Требуется подключение к интернету');
    }
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response =
          await _dio.post('/plants/$plantId/photo', data: formData);
      return Plant.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
