import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api', // hoặc domain thực tế
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(AuthInterceptor());
}
