import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl:
        'http://192.168.52.91:3000', // Đổi thành IP phù hợp nếu dùng real device
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      // Lưu token vào SharedPreferences
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> register(String username, String password,
      String detailUser, String department, String fullName) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'username': username,
          'password': password,
          'role': 'user',
          'detail': detailUser,
          'department': department,
          'fullname': fullName
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Register failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // Hàm tiện ích để lấy token (nếu cần dùng trong Interceptor chẳng hạn)
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
