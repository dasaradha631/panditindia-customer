import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../models/api_error.dart';
import '../models/auth_models.dart';
import 'session_service.dart';

/// Thin Dio wrapper: base URL from [AppConfig], bearer token injection,
/// single-flight refresh on 401 and normalised [ApiException] errors.
///
/// Widgets never call HTTP directly - they go through the service layer
/// (PDF section 17).
class ApiService {
  ApiService({Dio? dio, SessionService? session})
      : _session = session ?? SessionService.instance,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: <String, String>{'Accept': 'application/json'},
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;
  final SessionService _session;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request<dynamic>('GET', path, query: query);

  Future<dynamic> post(String path, {Object? data}) =>
      _request<dynamic>('POST', path, data: data);

  Future<dynamic> put(String path, {Object? data}) =>
      _request<dynamic>('PUT', path, data: data);

  Future<dynamic> delete(String path) => _request<dynamic>('DELETE', path);

  Future<T> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool auth = true,
    bool allowRefresh = true,
  }) async {
    final Map<String, dynamic> headers = <String, dynamic>{};
    if (auth) {
      final String? token = await _session.accessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
      return response.data as T;
    } on DioException catch (error) {
      if (allowRefresh &&
          auth &&
          error.response?.statusCode == 401 &&
          await _refresh()) {
        return _request<T>(
          method,
          path,
          data: data,
          query: query,
          auth: auth,
          allowRefresh: false,
        );
      }
      throw mapDioError(error);
    }
  }

  /// Exchanges the stored refresh token for a new access token.
  Future<bool> _refresh() async {
    final String? refreshToken = await _session.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(headers: <String, String>{'Accept': 'application/json'}),
      );
      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        final dynamic payload =
            body['data'] is Map<String, dynamic> ? body['data'] : body;
        if (payload is Map<String, dynamic> &&
            payload['access_token'] != null) {
          await _session.saveTokens(AuthTokens.fromJson(payload));
          return true;
        }
      }
      return false;
    } on DioException {
      await _session.clear();
      return false;
    }
  }

  static ApiException mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && error.error == null)) {
      return ApiException(
        code: ApiException.codeNetwork,
        message: 'Unable to reach PanditIndia. Check your connection and retry.',
        isNetworkError: true,
      );
    }

    final Response<dynamic>? response = error.response;
    if (response == null) {
      return ApiException(
        code: ApiException.codeNetwork,
        message: 'Unable to reach PanditIndia. Check your connection and retry.',
        isNetworkError: true,
      );
    }

    final int? status = response.statusCode;
    final dynamic payload = response.data;
    if (payload is Map<String, dynamic>) {
      final ApiException parsed = ApiException.fromPayload(
        payload,
        statusCode: status,
      );
      if (status == 401 && parsed.code == ApiException.codeGeneric) {
        return ApiException(
          code: ApiException.codeSessionExpired,
          message: 'Your session has expired. Please sign in again.',
          statusCode: status,
        );
      }
      return parsed;
    }

    return ApiException(
      code: ApiException.codeGeneric,
      message: status == 401
          ? 'Your session has expired. Please sign in again.'
          : 'Something went wrong. Please try again.',
      statusCode: status,
    );
  }
}
