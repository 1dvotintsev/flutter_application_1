import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> connectionChange = StreamController.broadcast();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      connectionChange.add(_isOnline);

      if (wasOffline && _isOnline) {
        print('Back online — syncing pending actions...');
      }
    });
  }

  void dispose() {
    connectionChange.close();
  }
}
