import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({this.statusCode, this.errorCode, this.traceId});

  final int? statusCode;
  final String? errorCode; // 화면 분기는 이 값으로
  final String? traceId; // 문의용 보관

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    return ApiException(
      statusCode: e.response?.statusCode,
      errorCode: data is Map ? data['errorCode'] as String? : null,
      traceId: data is Map ? data['traceId'] as String? : null,
    );
  }

  String get userMessage {
    final s = statusCode;
    if (s == null) return '인터넷 연결을 확인해 주세요.';
    if (s == 401) return '다시 시작해 주세요.';
    if (s == 403) return '이 화면은 볼 수 없어요.';
    if (s == 413 || s == 422) return '녹음을 다시 해 주세요.';
    if (s == 429 || s >= 500) return '잠시 후 다시 시도해 주세요.';
    return '문제가 생겼어요. 다시 시도해 주세요.';
  }
}
