import 'package:dio/dio.dart';
import '../observability/error_reporter.dart';

class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          ErrorReporter.report(
            error,
            error.stackTrace,
            context: 'API ${error.requestOptions.method} ${error.requestOptions.path}',
          );
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio dio;
}
