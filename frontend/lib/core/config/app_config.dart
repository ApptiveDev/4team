class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  // 백엔드 준비 전에는 true로 Mock 사용
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
}