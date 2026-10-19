import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final Api api = Api();
  final List<DownloadItem> items = [];
  final Map<String, CancelToken> _tokens = {};
  late SharedPreferences _p;

  bool ready = false;
  bool dark = true;
  bool wifiOnly = false;
  bool autoSave = true; // حفظ تلقائي في المعرض بعد انتهاء التحميل
  int height = 720; // 0 = تلقائي
  String server = 'http://10.0.2.2:8000'; // عنوان المحاكي؛ غيّره إلى IP الخادم

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    dark = _p.getBool('dark') ?? true;
    wifiOnly = _p.getBool('wifiOnly') ?? false;
    autoSave = _p.getBool('autoSave') ?? true;
    height = _p.getInt('height') ?? 720;
    server = _p.getString('server') ?? server;
    api.base = server;
    final raw = _p.getString('items');
    if (raw != null) {
      for (final j in jsonDecode(raw) as List) {
        final it = DownloadItem.fromJson(j);
        if (it.active) it.status = DlStatus.paused; // التطبيق أُغلق أثناء التحميل
        items.add(it);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _save() =>
      _p.setString('items', jsonEncode(items.map((e) => e.toJson()).toList()));

  void update({bool? dark, bool? wifiOnly, bool? autoSave, int? height, String? server}) {
    if (dark != null) {
      this.dark = dark;
      _p.setBool('dark', dark);
    }
    if (wifiOnly != null) {
      this.wifiOnly = wifiOnly;
      _p.setBool('wifiOnly', wifiOnly);
    }
    if (autoSave != null) {
      this.autoSave = autoSave;
      _p.setBool('autoSave', autoSave);
    }
    if (height != null) {
      this.height = height;
      _p.setInt('height', height);
    }
    if (server != null) {
      this.server = server.trim().replaceAll(RegExp(r'/+$'), '');
      api.base = this.server;
      _p.setString('server', this.server);
    }
    notifyListeners();
  }

  /// يعيد نص الخطأ إن وُجد، أو null عند نجاح البدء.
  Future<String?> add(String url, bool audio) async {
    url = url.trim();
    if (!url.startsWith('http')) return 'الصق رابطاً صالحاً يبدأ بـ http';
    if (wifiOnly) {
      final c = await Connectivity().checkConnectivity();
      if (!c.contains(ConnectivityResult.wifi) &&
          !c.contains(ConnectivityResult.ethernet)) {
        return 'اتصل بشبكة Wi‑Fi أو أوقف خيار «Wi‑Fi فقط»';
      }
    }
    final it = DownloadItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      audio: audio,
      height: height,
    );
    items.insert(0, it);
    _save();
    notifyListeners();
    _run(it);
    return null;
  }

  Future<void> _run(DownloadItem it) async {
    final ct = CancelToken();
    _tokens[it.id] = ct;
    try {
      it
        ..status = DlStatus.preparing
        ..error = null
        ..progress = 0;
      notifyListeners();

      it.jobId ??= await api.start(it.url, it.audio, it.height);
      while (true) {
        if (ct.isCancelled) return;
        final j = await api.job(it.jobId!);
        if (j['title'] != null) it.title = j['title'];
        if (j['status'] == 'error') throw j['error'] ?? 'فشل التحميل';
        it.progress = (j['progress'] as num).toDouble();
        it.speed = (j['speed'] as num).toDouble();
        notifyListeners();
        if (j['status'] == 'done') break;
        await Future.delayed(const Duration(seconds: 1));
      }

      it
        ..status = DlStatus.downloading
        ..progress = 0;
      notifyListeners();

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/FlixGo')..createSync(recursive: true);
      final safe = it.title.replaceAll(RegExp(r'[\\/:*?"<>|\n\r]'), '_');
      final tail = it.id.substring(it.id.length - 5);
      final path =
          '${folder.path}/${safe.isEmpty ? 'media' : safe}_$tail.${it.audio ? 'mp3' : 'mp4'}';
      final sw = Stopwatch()..start();
      await api.fetch(it.jobId!, path, cancel: ct, onProgress: (r, t) {
        if (t > 0) {
          it
            ..progress = r / t
            ..size = t
            ..speed = r / (sw.elapsedMilliseconds / 1000 + 0.001);
          notifyListeners();
        }
      });
      it
        ..path = path
        ..size = File(path).lengthSync()
        ..progress = 1
        ..speed = 0
        ..status = DlStatus.done;
      if (autoSave) await saveToDevice(it);
    } catch (e) {
      if (ct.isCancelled) return; // إيقاف مؤقت
      it
        ..status = DlStatus.failed
        ..error = Api.message(e);
    } finally {
      if (_tokens[it.id] == ct) _tokens.remove(it.id);
      _save();
      notifyListeners();
    }
  }

  /// الفيديو يُحفظ في معرض الصور (ألبوم FlixGo)، والصوت في مجلد التنزيلات
  /// لأن المعرض لا يدعم الملفات الصوتية. يعيد false عند الفشل أو رفض الإذن.
  Future<bool> saveToDevice(DownloadItem it) async {
    if (it.path == null) return false;
    try {
      if (it.audio) {
        final name = it.path!.split('/').last.replaceAll('.mp3', '');
        await FileSaver.instance.saveFile(
          name: name,
          filePath: it.path!,
          ext: 'mp3',
          mimeType: MimeType.mp3,
        );
      } else {
        if (!await Gal.hasAccess(toAlbum: true) &&
            !await Gal.requestAccess(toAlbum: true)) {
          return false;
        }
        await Gal.putVideo(it.path!, album: 'FlixGo');
      }
      it.saved = true;
      _save();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void pause(DownloadItem it) {
    it
      ..status = DlStatus.paused
      ..speed = 0;
    _tokens[it.id]?.cancel();
    _save();
    notifyListeners();
  }

  void resume(DownloadItem it) => _run(it);

  void toggleFavorite(DownloadItem it) {
    it.favorite = !it.favorite;
    _save();
    notifyListeners();
  }

  Future<void> remove(DownloadItem it) async {
    _tokens[it.id]?.cancel();
    if (it.path != null) {
      final f = File(it.path!);
      if (f.existsSync()) f.deleteSync();
    }
    items.remove(it);
    await _save();
    notifyListeners();
  }

  void clearFailed() {
    items.removeWhere((e) => e.status == DlStatus.failed);
    _save();
    notifyListeners();
  }
}