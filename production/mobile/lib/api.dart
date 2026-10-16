import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class ApiFailure implements Exception {
  const ApiFailure(this.code, {this.status = 0});
  final String code;
  final int status;
  bool get uncertain => status == 0 || status >= 500 || status == 429;
}

abstract interface class RexTransport {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  });
  void close();
}

class RexApi implements RexTransport {
  RexApi(
    String url, {
    bool allowLoopbackHttp = false,
    this.requestTimeout = const Duration(seconds: 12),
  }) : base = Uri.parse(url) {
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(requestTimeout);
    }
    if (base.scheme != 'https' &&
        !(allowLoopbackHttp &&
            base.scheme == 'http' &&
            const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host))) {
      throw const ApiFailure('secure_endpoint_required');
    }
    if (base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const ApiFailure('invalid_endpoint');
    }
    _http.connectionTimeout = const Duration(seconds: 8);
  }

  final Uri base;
  final Duration requestTimeout;
  final HttpClient _http = HttpClient();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _request(method, path, token: token, body: body);
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure('connection_failed');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final relative = Uri.parse(path);
    final target = base.resolveUri(relative);
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasQuery ||
        relative.hasFragment ||
        target.origin != base.origin ||
        relative.pathSegments.any(
          (segment) =>
              segment == '..' ||
              segment == '.' ||
              segment.contains('/') ||
              segment.contains('\\'),
        )) {
      throw const ApiFailure('invalid_path');
    }
    final elapsed = Stopwatch()..start();
    Duration remaining() {
      final left = requestTimeout - elapsed.elapsed;
      if (left <= Duration.zero) throw TimeoutException('request deadline');
      return left;
    }

    HttpClientRequest? request;
    StreamIterator<List<int>>? chunks;
    var expired = false;
    try {
      final opening = _http.openUrl(method, target);
      // Future.timeout does not cancel its source. Abort a late-opened request
      // too, so an expired operation cannot retain a live pooled connection.
      unawaited(
        opening.then<void>((value) {
          if (expired) value.abort();
        }, onError: (Object _, StackTrace __) {}),
      );
      request = await opening.timeout(remaining());
      request.followRedirects = false;
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(remaining());
      chunks = StreamIterator(response);
      final bytes = <int>[];
      while (await chunks.moveNext().timeout(remaining())) {
        if (bytes.length + chunks.current.length > 65536) {
          throw const ApiFailure('invalid_response');
        }
        bytes.addAll(chunks.current);
      }
      if (response.statusCode == 204) return {};
      final successful =
          response.statusCode >= 200 && response.statusCode < 300;
      Map<String, dynamic> result;
      try {
        result = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      } catch (_) {
        throw ApiFailure(
          successful ? 'invalid_response' : 'request_failed',
          status: successful ? 0 : response.statusCode,
        );
      }
      if (!successful) {
        throw ApiFailure(
          result['error'] is String
              ? result['error'] as String
              : 'request_failed',
          status: response.statusCode,
        );
      }
      return result;
    } on TimeoutException {
      expired = true;
      request?.abort();
      rethrow;
    } finally {
      // Cancelling the response subscription tears down stalled/oversized
      // bodies instead of leaving reads running after the caller has failed.
      await chunks?.cancel();
    }
  }

  @override
  void close() => _http.close(force: true);
}

String actionId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
