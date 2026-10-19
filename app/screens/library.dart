import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _q = '';
  int _f = 0; // 0 الكل، 1 فيديو، 2 صوت، 3 المفضلة

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final all = s.items.where((e) => e.status == DlStatus.done).toList();
    final list = all.where((e) {
      if (_q.isNotEmpty && !e.title.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      return switch (_f) {
        1 => !e.audio,
        2 => e.audio,
        3 => e.favorite,
        _ => true,
      };
    }).toList();
    final total = all.fold<int>(0, (a, e) => a + e.size);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('المكتبة',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(
              hintText: 'ابحث في ملفاتك', prefixIcon: Icon(Icons.search_rounded)),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          for (final e in ['الكل', 'فيديو', 'صوت', 'المفضلة'].asMap().entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _f == e.key,
              onSelected: (_) => setState(() => _f = e.key),
            ),
        ]),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
                child: Text('المكتبة فارغة',
                    style: TextStyle(color: cs.onSurfaceVariant))),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .95,
          children: [for (final it in list) _Card(it)],
        ),
        const SizedBox(height: 16),
        Panel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المساحة المستخدمة', style: TextStyle(fontSize: 13)),
              Text(fmtBytes(total),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final DownloadItem it;
  const _Card(this.it);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => OpenFilex.open(it.path!),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(child: Thumb(audio: it.audio, height: 110)),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'fav') {
                    s.toggleFavorite(it);
                  } else if (v == 'del') {
                    s.remove(it);
                  } else {
                    final ok = await s.saveToDevice(it);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? (it.audio ? 'حُفظ في التنزيلات' : 'حُفظ في معرض الصور')
                            : 'تعذّر الحفظ، تحقق من الأذونات')));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'fav',
                      child: Text(it.favorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة')),
                  PopupMenuItem(
                      value: 'save',
                      child: Text(it.audio ? 'حفظ في التنزيلات' : 'حفظ في المعرض')),
                  const PopupMenuItem(value: 'del', child: Text('حذف')),
                ],
                icon: Icon(
                    it.favorite ? Icons.star_rounded : Icons.more_vert_rounded,
                    color: it.favorite ? Colors.amber : cs.onSurfaceVariant),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(it.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(fmtBytes(it.size),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ]),
    );
  }
}