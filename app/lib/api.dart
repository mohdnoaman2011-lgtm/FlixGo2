import 'package:dio/dio.dart';

class Api {
  String base = '';
  final Dio _d = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<String> start(String url, bool audio, int height) async {
    final r = await _d.post('$base/download',
        data: {'url': url, 'mode': audio ? 'audio' : 'video', 'height': height});
    return r.data['id'] as String;
  }

  Future<Map<String, dynamic>> job(String id) async {
    final r = await _d.get('$base/jobs/$id');
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> fetch(String id, String path,
      {void Function(int, int)? onProgress, CancelToken? cancel}) {
    return _d.download('$base/file/$id', path,
        onReceiveProgress: onProgress,
        cancelToken: cancel,
        options: Options(receiveTimeout: Duration.zero));
  }

  static String message(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['detail'] != null) return d['detail'].toString();
      return 'تعذّر الاتصال بالخادم، تحقق من العنوان في الإعدادات';
    }
    return e.toString();
  }
}
