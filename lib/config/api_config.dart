class ApiConfig {
  // static const String baseUrl = 'http://192.168.31.251:8000'; //реальное устройство
  //static const String baseUrl = 'http://10.0.2.2:8000'; //эмулятор
  static const String baseUrl = 'http://45.66.117.173:8000'; //прод
  static const Duration timeout = Duration(seconds: 30);
  static const Duration identifyTimeout = Duration(seconds: 60);
}
