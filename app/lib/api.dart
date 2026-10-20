// FlixGo — client for the FlixGo download server (see server/).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// code: 'auth' | 'net' | 'wifi' | 'cancelled' | 'server' (message from server)
class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, [this.message = '']);
  @override
  String toString() => '$code: $message';
}

class JobStatus {
  final String status; // queued | running | ready | error
  final double progress; // 0..1
  final String? title, error, ext;
  JobStatus(this.status, this.progress, this.title, this.error, this.ext);
}

class Api {
  final String base;
  final String key;
  Api(String address, this.key) : base = normalize(address);

  static String normalize(String a) {
    a = a.trim();
    if (a.isEmpty) return '';
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(a)) {
      a = 'https://$a';
    }
    while (a.endsWith('/')) {
      a = a.substring(0, a.length - 1);
    }
    return a;
  }

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (key.isNotEmpty) 'X-API-Key': key,
      };

  Uri _u(String path) => Uri.parse('$base$path');

  // Render's free tier can take ~1 minute to wake up, so the timeout is long.
  Future<http.Response> _send(Future<http.Response> Function() f,
      {Duration timeout = const Duration(seconds: 90)}) async {
    try {
      return await f().timeout(timeout);
    } on TimeoutException {
      throw ApiException('net');
    } on SocketException {
      throw ApiException('net');
    } on http.ClientException {
      throw ApiException('net');
    } on HandshakeException {
      throw ApiException('net');
    } on FormatException {
      throw ApiException('net');
    }
  }

  dynamic _json(http.Response r) {
    if (r.statusCode == 401) throw ApiException('auth');
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (r.statusCode >= 400) {
      final d = body is Map ? body['detail'] : null;
      throw ApiException('server', d is String ? d : 'HTTP ${r.statusCode}');
    }
    return body;
  }

  /// Returns a short description of the server, or throws.
  Future<Map<String, dynamic>> ping() async {
    final r = await _send(() => http.get(_u('/api/ping'), headers: _h));
    final b = _json(r);
    return b is Map<String, dynamic> ? b : <String, dynamic>{};
  }

  Future<String> createJob(String url, String kind, String quality) async {
    final r = await _send(() => http.post(_u('/api/jobs'),
        headers: _h,
        body: jsonEncode({'url': url, 'kind': kind, 'quality': quality})));
    final b = _json(r);
    final id = b is Map ? b['id'] : null;
    if (id is! String) throw ApiException('server', 'bad response');
    return id;
  }

  Future<JobStatus> status(String id) async {
    final r = await _send(() => http.get(_u('/api/jobs/$id'), headers: _h),
        timeout: const Duration(seconds: 30));
    final b = _json(r);
    if (b is! Map) throw ApiException('server', 'bad response');
    return JobStatus(
      '${b['status']}',
      (b['progress'] is num ? (b['progress'] as num).toDouble() : 0.0)
          .clamp(0.0, 1.0),
      b['title'] as String?,
      b['error'] as String?,
      b['ext'] as String?,
    );
  }

  /// Streams the finished file to [dest]. Returns the number of bytes written.
  Future<int> download(String id, String dest,
      {required void Function(int received, int? total) onProgress,
      required bool Function() cancelled}) async {
    final client = http.Client();
    final file = File(dest);
    IOSink? sink;
    try {
      final req = http.Request('GET', _u('/api/jobs/$id/file'));
      req.headers.addAll(_h);
      final resp =
          await client.send(req).timeout(const Duration(seconds: 60));
      if (resp.statusCode == 401) throw ApiException('auth');
      if (resp.statusCode >= 400) {
        throw ApiException('server', 'HTTP ${resp.statusCode}');
      }
      final total = resp.contentLength;
      sink = file.openWrite();
      var got = 0;
      await for (final chunk
          in resp.stream.timeout(const Duration(seconds: 60))) {
        if (cancelled()) throw ApiException('cancelled');
        sink.add(chunk);
        got += chunk.length;
        onProgress(got, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      return got;
    } on TimeoutException {
      throw ApiException('net');
    } on SocketException {
      throw ApiException('net');
    } on http.ClientException {
      throw ApiException('net');
    } catch (e) {
      rethrow;
    } finally {
      client.close();
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
    }
  }
}
