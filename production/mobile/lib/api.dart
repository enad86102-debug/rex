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
  RexApi(String url, {bool allowLoopbackHttp = false}) : base = Uri.parse(url) {
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
  final HttpClient _http = HttpClient();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _request(
        method,
        path,
        token: token,
        body: body,
      ).timeout(const Duration(seconds: 12));
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
    final request = await _http.openUrl(method, base.resolve(path));
    request.followRedirects = false; // Never forward a bearer to another host.
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    if (body != null) {
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    if (response.statusCode == 204) {
      await response.drain<void>();
      return {};
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 65536) throw const ApiFailure('invalid_response');
    }
    final result = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiFailure(
        result['error'] as String? ?? 'request_failed',
        status: response.statusCode,
      );
    }
    return result;
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
