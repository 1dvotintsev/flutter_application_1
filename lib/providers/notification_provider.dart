import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationInitProvider = FutureProvider<void>((ref) async {
  final service = NotificationService();
  final token = await service.init();

  if (token != null) {
    try {
      await ref.read(apiServiceProvider).updateDeviceToken(token);
      print('Device token sent to server');
    } catch (e) {
      print('Failed to send device token: $e');
    }
  }

  service.onTokenRefresh.listen((newToken) {
    ref.read(apiServiceProvider).updateDeviceToken(newToken).catchError((_) {});
  });
});
