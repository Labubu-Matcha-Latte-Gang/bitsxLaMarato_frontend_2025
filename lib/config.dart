class Config {
  static const String apiUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://loaclhost:5000');
}
