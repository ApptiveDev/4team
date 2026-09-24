import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';

abstract class AuthDataSource {
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String role,
    required String deviceId,
  });
}

class MockAuthDataSource implements AuthDataSource {
  @override
  Future<Map<String, dynamic>> signUp({
    required String name, required String role, required String deviceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 확인용
    final file = role == 'PARENT' ? 'user_parent' : 'user_child';
    final raw = await rootBundle.loadString('assets/mocks/$file.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

class ApiAuthDataSource implements AuthDataSource {
  ApiAuthDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> signUp({
    required String name, required String role, required String deviceId,
  }) async {
    try {
      final res = await _dio.post('/users',
          data: {'name': name, 'role': role, 'deviceId': deviceId});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}