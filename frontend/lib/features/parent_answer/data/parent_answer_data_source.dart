import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';

abstract class ParentAnswerDataSource {
  Future<Map<String, dynamic>> getToday();
  Future<Map<String, dynamic>> getAudio(String answerId);
}

class ApiParentAnswerDataSource implements ParentAnswerDataSource {
  ApiParentAnswerDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data!;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getToday() => _get('/today');
  @override
  Future<Map<String, dynamic>> getAudio(String answerId) =>
      _get('/answers/${Uri.encodeComponent(answerId)}/audio');
}

class MockParentAnswerDataSource implements ParentAnswerDataSource {
  /// 단독 실행: flutter run --dart-define=PART_B_DEMO=answer
  /// 실패 확인: 위 명령에 --dart-define=MOCK_PARENT_ANSWER=failed 추가.
  /// 지원 값: ready(기본), waiting, empty, error, processing, failed,
  /// not-requested, audio-error. 재생은 실제 TTS 대신 1초 테스트 소리다.
  MockParentAnswerDataSource({
    this.scenario = const String.fromEnvironment(
      'MOCK_PARENT_ANSWER',
      defaultValue: 'ready',
    ),
    this.delay = const Duration(milliseconds: 400),
  });
  final String scenario;
  final Duration delay;

  Future<Map<String, dynamic>> _fixture(String name) async =>
      jsonDecode(await rootBundle.loadString('assets/mocks/$name.json'))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> getToday() async {
    await Future<void>.delayed(delay);
    if (scenario == 'error') throw ApiException();
    if (scenario == 'empty') {
      throw ApiException(
        statusCode: 404,
        errorCode: 'TODAY_ASSIGNMENT_NOT_FOUND',
      );
    }
    if (scenario == 'waiting') return _fixture('today_waiting_for_child');
    return _fixture('today_parent_revealed');
  }

  @override
  Future<Map<String, dynamic>> getAudio(String answerId) async {
    await Future<void>.delayed(delay);
    if (scenario == 'audio-error') throw ApiException();
    final json = await _fixture('answer_audio_ready');
    final status = switch (scenario) {
      'processing' => 'PROCESSING',
      'failed' => 'FAILED',
      'not-requested' => 'NOT_REQUESTED',
      _ => 'READY',
    };
    return {
      ...json,
      'answerId': answerId,
      'ttsStatus': status,
      // 실제 음성 대신 재생 확인용 짧은 소리를 사용한다.
      'audioUrl': status == 'READY'
          ? 'asset:///assets/audio/demo_tone.wav'
          : null,
      'audioExpiresAt': null,
    };
  }
}
