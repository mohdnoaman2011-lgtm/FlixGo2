import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int _tab = 0; // 0 نشطة، 1 مكتملة، 2 فاشلة

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final active = s.items.where((e) => e.active).toList();
    final list = switch (_tab) {
      0 => active,
      1 => s.items.where((e) => e.status == DlStatus.done).toList(),
      _ => s.items.where((e) => e.status == DlStatus.failed).toList(),
    };
    final speed = active
        .where((e) => e.status == DlStatus.downloading)
        .fold<double>(0, (a, e) => a + e.speed);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('التحميلات',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('السرعة الحالية ${fmtSpeed(speed).isEmpty ? '0' : fmtSpeed(speed)} · ${active.length} ملفات',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: [
          for (final e in ['نشطة', 'مكتملة', 'فاشلة'].asMap().entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _tab == e.key,
              onSelected: (_) => setState(() => _tab = e.key),
            ),
        ]),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
                child: Text('لا توجد عناصر هنا',
                    style: TextStyle(color: cs.onSurfaceVariant))),
          ),
        for (final it in list) _Tile(it),
        if (_tab == 2 && list.isNotEmpty)
          OutlinedButton(onPressed: s.clearFailed, child: const Text('مسح الفاشلة')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final DownloadItem it;
  const _Tile(this.it);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cs = Theme.of(context).colorScheme;
    final sub = switch (it.status) {
      DlStatus.preparing => 'جارٍ التجهيز · ${(it.progress * 100).round()}%',
      DlStatus.downloading =>
        '${fmtBytes(it.size * it.progress)} / ${fmtBytes(it.size)} · ${fmtSpeed(it.speed)}',
      DlStatus.paused => 'متوقف مؤقتاً · ${(it.progress * 100).round()}%',
      DlStatus.done =>
        '${fmtBytes(it.size)} · ${it.saved ? (it.audio ? 'في التنزيلات' : 'في المعرض') : 'داخل التطبيق فقط'}',
      DlStatus.failed => it.error ?? 'فشل التحميل',
    };
    return Panel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Thumb(audio: it.audio, width: 64, height: 64),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title.isEmpty ? it.url : it.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (it.active) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: it.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: it.audio ? const Color(0xFF2DD4BF) : cs.primary,
              ),
            ],
            const SizedBox(height: 6),
            Text(sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: it.status == DlStatus.failed ? cs.error : cs.onSurfaceVariant,
                    fontSize: 12)),
          ]),
        ),
        if (it.status == DlStatus.preparing || it.status == DlStatus.downloading)
          IconButton.filledTonal(
              onPressed: () => s.pause(it),
              tooltip: 'إيقاف مؤقت',
              icon: const Icon(Icons.pause_rounded)),
        if (it.status == DlStatus.paused || it.status == DlStatus.failed)
          IconButton.filledTonal(
              onPressed: () => s.resume(it),
              tooltip: it.status == DlStatus.paused ? 'استئناف' : 'إعادة المحاولة',
              icon: Icon(it.status == DlStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.refresh_rounded)),
        if (it.status != DlStatus.preparing && it.status != DlStatus.downloading)
          IconButton(
              onPressed: () => s.remove(it),
              tooltip: 'حذف',
              icon: const Icon(Icons.close_rounded)),
      ]),
    );
  }
}