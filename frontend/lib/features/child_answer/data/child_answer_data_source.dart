import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';

abstract class ChildAnswerDataSource {
  Future<Map<String, dynamic>> putChildAnswer({
    required String assignmentId,
    required String text,
  });
}

class MockChildAnswerDataSource implements ChildAnswerDataSource {
  /// [failWith]를 주면 그 에러를 던진다. (테스트용)
  /// 에뮬레이터에서 에러 화면을 볼 때는:
  /// flutter run --dart-define=MOCK_CHILD_ANSWER_ERROR=ANSWER_LOCKED
  /// 지원 값: ANSWER_LOCKED, VALIDATION_ERROR, NETWORK, SERVER
  MockChildAnswerDataSource({
    this.failWith,
    this.delay = const Duration(milliseconds: 500),
  });

  final ApiException? failWith;
  final Duration delay;

  static const _forcedError = String.fromEnvironment('MOCK_CHILD_ANSWER_ERROR');

  @override
  Future<Map<String, dynamic>> putChildAnswer({
    required String assignmentId,
    required String text,
  }) async {
    await Future.delayed(delay); // 로딩 화면 확인용
    final error = failWith ?? _errorFromDefine(_forcedError);
    if (error != null) throw error;

    final raw = await rootBundle.loadString(
      'assets/mocks/child_answer_submitted.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    // 실제 서버처럼 보낸 값이 응답에 반영되게 덮어쓴다.
    return {
      ...json,
      'assignmentId': assignmentId,
      'text': text,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static ApiException? _errorFromDefine(String code) {
    switch (code) {
      case 'ANSWER_LOCKED':
        return ApiException(statusCode: 409, errorCode: 'ANSWER_LOCKED');
      case 'VALIDATION_ERROR':
        return ApiException(statusCode: 400, errorCode: 'VALIDATION_ERROR');
      case 'NETWORK':
        return ApiException(); // statusCode 없음 = 연결 실패
      case 'SERVER':
        return ApiException(statusCode: 500, errorCode: 'INTERNAL_ERROR');
      default:
        return null;
    }
  }
}

class ApiChildAnswerDataSource implements ChildAnswerDataSource {
  ApiChildAnswerDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> putChildAnswer({
    required String assignmentId,
    required String text,
  }) async {
    try {
      final res = await _dio.put(
        '/assignments/$assignmentId/child-answer',
        data: {'text': text},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
