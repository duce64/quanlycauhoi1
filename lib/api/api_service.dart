import 'package:dio/dio.dart';

class ApiService {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {
      'Content-Type': 'application/json',
    },
  ));
}
