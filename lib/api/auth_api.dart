import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthAPI {
  static Future<Response> login({
    required String username,
    required String password,
  }) async {
    return await ApiService.dio.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  static Future<Response> register({
    required String username,
    required String password,
    required String role,
    required String detail,
    required String department,
  }) async {
    return await ApiService.dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'role': role,
        'detail': detail,
        'department': department,
      },
    );
  }
}
