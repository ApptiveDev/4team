import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';

abstract class RecordingDataSource {
  Future<Map<String, dynamic>> upload({
    required String assignmentId,
    required String filePath,
    required String idempotencyKey,
    required void Function(double progress) onProgress,
  });
  Future<Map<String, dynamic>> getStatus(String recordingId);
}

class ApiRecordingDataSource implements RecordingDataSource {
  ApiRecordingDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> upload({
    required String assignmentId,
    required String filePath,
    required String idempotencyKey,
    required void Function(double progress) onProgress,
  }) async {
    try {
      // 재시도할 때도 FormData와 파일 스트림은 새로 만든다.
      final form = FormData.fromMap({
        'audioFile': await MultipartFile.fromFile(
          filePath,
          filename: 'answer.m4a',
          contentType: DioMediaType('audio', 'mp4'),
        ),
      });
      final response = await _dio.put<Map<String, dynamic>>(
        '/assignments/${Uri.encodeComponent(assignmentId)}/parent-recording',
        data: form,
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 30),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress((sent / total).clamp(0.0, 1.0));
        },
      );
      return response.data!;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getStatus(String recordingId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/recordings/${Uri.encodeComponent(recordingId)}',
      );
      return response.data!;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

class MockRecordingDataSource implements RecordingDataSource {
  /// 단독 실행: flutter run --dart-define=PART_B_DEMO=recording
  /// 실패 확인: 위 명령에 --dart-define=MOCK_RECORDING=failed 추가.
  /// 지원 값: ready(기본), processing, failed, upload-error, poll-error, locked.
  /// Mock에서도 마이크 녹음은 실제 기기를 사용한다.
  MockRecordingDataSource({
    this.scenario = const String.fromEnvironment(
      'MOCK_RECORDING',
      defaultValue: 'ready',
    ),
    this.delay = const Duration(milliseconds: 500),
  });
  final String scenario;
  final Duration delay;
  final Map<String, Map<String, dynamic>> _uploads = {};
  final Map<String, String> _assignments = {};
  final Map<String, int> _polls = {};

  Future<Map<String, dynamic>> _fixture(String name) async =>
      jsonDecode(await rootBundle.loadString('assets/mocks/$name.json'))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> upload({
    required String assignmentId,
    required String filePath,
    required String idempotencyKey,
    required void Function(double progress) onProgress,
  }) async {
    await Future<void>.delayed(delay);
    if (scenario == 'upload-error') throw ApiException();
    if (scenario == 'locked') {
      throw ApiException(statusCode: 409, errorCode: 'ANSWER_LOCKED');
    }
    onProgress(1);
    if (_uploads.containsKey(idempotencyKey)) return _uploads[idempotencyKey]!;
    final json = await _fixture('recording_uploaded');
    final id = 'rec_mock_${_uploads.length + 1}';
    final response = {
      ...json,
      'recordingId': id,
      'assignmentId': assignmentId,
      'pollingUrl': '/api/v1/recordings/$id',
    };
    _uploads[idempotencyKey] = response;
    _assignments[id] = assignmentId;
    return response;
  }

  @override
  Future<Map<String, dynamic>> getStatus(String recordingId) async {
    await Future<void>.delayed(delay);
    if (scenario == 'poll-error') throw ApiException();
    final count = (_polls[recordingId] ?? 0) + 1;
    _polls[recordingId] = count;
    final name = scenario == 'processing' || count < 2
        ? 'recording_processing'
        : scenario == 'failed'
        ? 'recording_failed'
        : 'recording_ready';
    return {
      ...await _fixture(name),
      'recordingId': recordingId,
      'assignmentId': _assignments[recordingId] ?? 'asg_mock',
    };
  }
}
