enum DlStatus { preparing, downloading, paused, done, failed }

class DownloadItem {
  final String id;
  final String url;
  final bool audio;
  final int height;
  String title;
  DlStatus status;
  double progress; // 0..1
  double speed; // bytes/s
  int size;
  bool favorite;
  bool saved; // نُسخ إلى المعرض/التنزيلات
  String? jobId;
  String? path;
  String? error;
  final DateTime createdAt;

  DownloadItem({
    required this.id,
    required this.url,
    required this.audio,
    required this.height,
    this.title = '',
    this.status = DlStatus.preparing,
    this.progress = 0,
    this.speed = 0,
    this.size = 0,
    this.favorite = false,
    this.saved = false,
    this.jobId,
    this.path,
    this.error,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get active =>
      status == DlStatus.preparing ||
      status == DlStatus.downloading ||
      status == DlStatus.paused;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'audio': audio,
        'height': height,
        'title': title,
        'status': status.name,
        'size': size,
        'favorite': favorite,
        'saved': saved,
        'jobId': jobId,
        'path': path,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
        id: j['id'],
        url: j['url'],
        audio: j['audio'],
        height: j['height'],
        title: j['title'] ?? '',
        status: DlStatus.values.byName(j['status']),
        size: j['size'] ?? 0,
        favorite: j['favorite'] ?? false,
        saved: j['saved'] ?? false,
        jobId: j['jobId'],
        path: j['path'],
        error: j['error'],
        createdAt: DateTime.parse(j['createdAt']),
      );
}
