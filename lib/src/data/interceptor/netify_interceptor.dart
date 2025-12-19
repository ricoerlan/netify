import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/entities/network_log.dart';
import '../../core/repositories/log_repository.dart';

class NetifyInterceptor extends Interceptor {
  final LogRepository logRepository;

  NetifyInterceptor({required this.logRepository});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final log = NetworkLog(
      id: _generateId(),
      method: options.method,
      url: options.uri.toString(),
      requestHeaders: _convertHeaders(options.headers),
      requestBody: options.data,
      requestTime: DateTime.now(),
    );

    options.extra['netify_log_id'] = log.id;
    options.extra['netify_request_time'] = log.requestTime;

    logRepository.addLog(log);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final logId = response.requestOptions.extra['netify_log_id'] as String?;
    final requestTime =
        response.requestOptions.extra['netify_request_time'] as DateTime?;

    if (logId != null && requestTime != null) {
      final responseTime = DateTime.now();
      final duration = responseTime.difference(requestTime);

      final existingLog = logRepository.logs.firstWhere(
        (log) => log.id == logId,
        orElse: () => NetworkLog(
          id: logId,
          method: response.requestOptions.method,
          url: response.requestOptions.uri.toString(),
          requestTime: requestTime,
        ),
      );

      final updatedLog = existingLog.copyWith(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        responseHeaders: _convertHeaders(response.headers.map),
        responseBody: response.data,
        responseTime: responseTime,
        responseSize: _calculateSize(response.data),
        duration: duration,
      );

      logRepository.updateLog(updatedLog);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final logId = err.requestOptions.extra['netify_log_id'] as String?;
    final requestTime =
        err.requestOptions.extra['netify_request_time'] as DateTime?;

    if (logId != null && requestTime != null) {
      final responseTime = DateTime.now();
      final duration = responseTime.difference(requestTime);

      final existingLog = logRepository.logs.firstWhere(
        (log) => log.id == logId,
        orElse: () => NetworkLog(
          id: logId,
          method: err.requestOptions.method,
          url: err.requestOptions.uri.toString(),
          requestTime: requestTime,
        ),
      );

      final updatedLog = existingLog.copyWith(
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage,
        responseHeaders: err.response != null
            ? _convertHeaders(err.response!.headers.map)
            : null,
        responseBody: err.response?.data,
        responseTime: responseTime,
        responseSize:
            err.response != null ? _calculateSize(err.response!.data) : null,
        duration: duration,
        error: _formatError(err),
      );

      logRepository.updateLog(updatedLog);
    }

    handler.next(err);
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Map<String, dynamic> _convertHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.join(', '));
      }
      return MapEntry(key, value.toString());
    });
  }

  int _calculateSize(dynamic data) {
    if (data == null) return 0;
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    try {
      return jsonEncode(data).length;
    } catch (_) {
      return data.toString().length;
    }
  }

  String _formatError(DioException err) {
    final buffer = StringBuffer();

    buffer.writeln(
        'This exception was thrown because the response has a status code of ${err.response?.statusCode ?? "unknown"} and RequestOptions.validateStatus was configured to throw for this status code.');
    buffer.writeln();

    if (err.response?.statusCode != null) {
      final code = err.response!.statusCode!;
      String meaning;

      if (code == 400) {
        meaning =
            'Bad Request - the server cannot process the request due to client error';
      } else if (code == 401) {
        meaning = 'Unauthorized - authentication is required';
      } else if (code == 403) {
        meaning = 'Forbidden - the server refuses to authorize the request';
      } else if (code == 404) {
        meaning =
            'Not Found - the request contains bad syntax or cannot be fulfilled';
      } else if (code == 500) {
        meaning =
            'Internal Server Error - the server encountered an unexpected condition';
      } else if (code >= 400 && code < 500) {
        meaning =
            'Client error - the request contains bad syntax or cannot be fulfilled';
      } else if (code >= 500) {
        meaning = 'Server error - the server failed to fulfill a valid request';
      } else {
        meaning = 'Unknown error';
      }

      buffer.writeln('The status code of $code has the following meaning:');
      buffer.writeln('"$meaning"');
      buffer.writeln();
    }

    buffer.writeln(
        'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status');
    buffer.writeln();
    buffer.writeln(
        'In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.');

    return buffer.toString();
  }
}
