import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/recording/data/recording_data_source.dart';
import 'package:life_record/features/recording/data/recording_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('multipart 필드·MIME·키가 계약과 일치하고 재시도마다 새 스트림을 만든다', () async {
    final directory = await Directory.systemTemp.createTemp('recording_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/answer.m4a')
        .writeAsBytes([1, 2, 3]);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    addTearDown(() => dio.close());
    final forms = <FormData>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PUT');
          expect(options.path, '/assignments/asg_1/parent-recording');
          expect(options.headers['Idempotency-Key'], 'same-key');
          final form = options.data as FormData;
          forms.add(form);
          expect(form.files.single.key, 'audioFile');
          expect(form.files.single.value.filename, 'answer.m4a');
          expect(form.files.single.value.contentType.toString(), 'audio/mp4');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 202,
              data: {'recordingId': 'rec_1', 'assignmentId': 'asg_1'},
            ),
          );
        },
      ),
    );
    final source = ApiRecordingDataSource(dio);
    for (var i = 0; i < 2; i++) {
      final json = await source.upload(
        assignmentId: 'asg_1',
        filePath: file.path,
        idempotencyKey: 'same-key',
        onProgress: (_) {},
      );
      expect(submissionFromJson(json).recordingId, 'rec_1');
    }
    expect(identical(forms[0], forms[1]), isFalse);
  });

  test('HTTP 에러를 앱의 ApiException으로 변환한다', () async {
    final dio = Dio();
    addTearDown(() => dio.close());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 403,
                data: {'errorCode': 'ROLE_NOT_ALLOWED'},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    await expectLater(
      ApiRecordingDataSource(dio).getStatus('rec_1'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 403),
      ),
    );
  });

  test('Mock은 같은 키에 같은 제출을 반환하고 처리 완료로 전이한다', () async {
    final source = MockRecordingDataSource(delay: Duration.zero);
    Future<Map<String, dynamic>> upload() => source.upload(
      assignmentId: 'asg_1',
      filePath: '/a.m4a',
      idempotencyKey: 'key',
      onProgress: (_) {},
    );
    final first = await upload();
    expect(await upload(), first);
    final id = first['recordingId'] as String;
    expect((await source.getStatus(id))['processingStatus'], 'LLM_PROCESSING');
    expect((await source.getStatus(id))['processingStatus'], 'READY');
  });
}
