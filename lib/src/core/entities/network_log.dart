import 'dart:convert';

/// Represents a captured HTTP network request/response log.
///
/// Contains all details about the request including URL, method, headers,
/// body, status code, timing, and any errors.
class NetworkLog {
  /// Unique identifier for this log entry.
  final String id;

  /// HTTP method (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Full request URL including query parameters.
  final String url;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final Map<String, dynamic>? responseHeaders;
  final dynamic responseBody;
  final DateTime requestTime;
  final DateTime? responseTime;
  final int? responseSize;
  final String? error;
  final Duration? duration;

  NetworkLog({
    required this.id,
    required this.method,
    required this.url,
    this.statusCode,
    this.statusMessage,
    this.requestHeaders,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
    required this.requestTime,
    this.responseTime,
    this.responseSize,
    this.error,
    this.duration,
  });

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => statusCode != null && statusCode! >= 400;
  bool get isPending => statusCode == null && error == null;

  String get formattedRequestTime {
    final h = requestTime.hour.toString().padLeft(2, '0');
    final m = requestTime.minute.toString().padLeft(2, '0');
    final s = requestTime.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedDuration {
    if (duration == null) return '-';
    return '${duration!.inMilliseconds}ms';
  }

  String get formattedResponseSize {
    if (responseSize == null) return '-';
    if (responseSize! < 1024) return '${responseSize}B';
    if (responseSize! < 1024 * 1024) {
      return '${(responseSize! / 1024).toStringAsFixed(1)}KB';
    }
    return '${(responseSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedTimestamp {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[requestTime.month - 1];
    final day = requestTime.day.toString().padLeft(2, '0');
    final year = requestTime.year;
    return '$month $day, $year $formattedRequestTime';
  }

  NetworkLog copyWith({
    String? id,
    String? method,
    String? url,
    int? statusCode,
    String? statusMessage,
    Map<String, dynamic>? requestHeaders,
    dynamic requestBody,
    Map<String, dynamic>? responseHeaders,
    dynamic responseBody,
    DateTime? requestTime,
    DateTime? responseTime,
    int? responseSize,
    String? error,
    Duration? duration,
  }) {
    return NetworkLog(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      requestTime: requestTime ?? this.requestTime,
      responseTime: responseTime ?? this.responseTime,
      responseSize: responseSize ?? this.responseSize,
      error: error ?? this.error,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'requestTime': requestTime.toIso8601String(),
      'responseTime': responseTime?.toIso8601String(),
      'responseSize': responseSize,
      'error': error,
      'duration': duration?.inMilliseconds,
    };
  }

  factory NetworkLog.fromJson(Map<String, dynamic> json) {
    return NetworkLog(
      id: json['id'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      statusCode: json['statusCode'] as int?,
      statusMessage: json['statusMessage'] as String?,
      requestHeaders: json['requestHeaders'] as Map<String, dynamic>?,
      requestBody: json['requestBody'],
      responseHeaders: json['responseHeaders'] as Map<String, dynamic>?,
      responseBody: json['responseBody'],
      requestTime: DateTime.parse(json['requestTime'] as String),
      responseTime: json['responseTime'] != null
          ? DateTime.parse(json['responseTime'] as String)
          : null,
      responseSize: json['responseSize'] as int?,
      error: json['error'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }

  String toCurl() {
    final buffer = StringBuffer('curl');

    buffer.write(' -X $method');

    if (requestHeaders != null) {
      requestHeaders!.forEach((key, value) {
        buffer.write(" -H '$key: $value'");
      });
    }

    if (requestBody != null) {
      String bodyStr;
      if (requestBody is Map || requestBody is List) {
        bodyStr = jsonEncode(requestBody);
      } else {
        bodyStr = requestBody.toString();
      }
      buffer.write(" -d '$bodyStr'");
    }

    buffer.write(" '$url'");

    return buffer.toString();
  }
}
