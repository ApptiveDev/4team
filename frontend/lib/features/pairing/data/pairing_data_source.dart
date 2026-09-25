import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';

abstract class PairingDataSource {
  Future<Map<String, dynamic>> createInvitation();
  Future<Map<String, dynamic>> join(String inviteCode);
  Future<bool> isPaired();
}

class MockPairingDataSource implements PairingDataSource {
  /// [pairedAfter]가 지나면 부모가 연결한 것으로 본다. (자녀 대기 화면 확인용)
  /// 에러 화면을 볼 때: flutter run --dart-define=MOCK_PAIRING_ERROR=INVITE_CODE_USED
  /// 지원 값: INVITE_CODE_NOT_FOUND, INVITE_CODE_USED, INVITE_CODE_EXPIRED, ALREADY_PAIRED, NETWORK
  MockPairingDataSource({
    this.pairedAfter = const Duration(seconds: 8),
    this.delay = const Duration(milliseconds: 500),
  });

  final Duration pairedAfter;
  final Duration delay;
  final _createdAt = DateTime.now();

  static const _forcedError = String.fromEnvironment('MOCK_PAIRING_ERROR');

  @override
  Future<Map<String, dynamic>> createInvitation() async {
    await Future.delayed(delay);
    final json = await _load('pair_invitation');
    return {
      ...json,
      'expiresAt': DateTime.now()
          .add(const Duration(hours: 24))
          .toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> join(String inviteCode) async {
    await Future.delayed(delay);
    final error = _errorFromDefine(_forcedError);
    if (error != null) throw error;
    return _load('pair_joined');
  }

  @override
  Future<bool> isPaired() async =>
      DateTime.now().difference(_createdAt) >= pairedAfter;

  Future<Map<String, dynamic>> _load(String name) async {
    final raw = await rootBundle.loadString('assets/mocks/$name.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static ApiException? _errorFromDefine(String code) {
    switch (code) {
      case 'INVITE_CODE_NOT_FOUND':
        return ApiException(statusCode: 404, errorCode: code);
      case 'INVITE_CODE_USED':
      case 'INVITE_CODE_EXPIRED':
      case 'ALREADY_PAIRED':
        return ApiException(statusCode: 409, errorCode: code);
      case 'NETWORK':
        return ApiException();
      default:
        return null;
    }
  }
}

class ApiPairingDataSource implements PairingDataSource {
  ApiPairingDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> createInvitation() =>
      _call(() => _dio.post('/pairs/invitations'));

  @override
  Future<Map<String, dynamic>> join(String inviteCode) =>
      _call(() => _dio.post('/pairs/join', data: {'inviteCode': inviteCode}));

  @override
  Future<bool> isPaired() async {
    try {
      await _dio.get('/today');
      return true;
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      switch (error.errorCode) {
        case 'PAIR_NOT_FOUND':
          return false;
        case 'TODAY_ASSIGNMENT_NOT_FOUND':
          return true; // 연결은 됐고 오늘 질문만 없음
        default:
          throw error;
      }
    }
  }

  Future<Map<String, dynamic>> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final res = await request();
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
