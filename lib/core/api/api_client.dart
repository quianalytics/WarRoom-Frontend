import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio dio;
}
