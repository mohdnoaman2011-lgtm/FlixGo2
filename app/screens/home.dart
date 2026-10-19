import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _c = TextEditingController();
  bool _audio = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData('text/plain');
    if (d?.text != null) setState(() => _c.text = d!.text!.trim());
  }

  Future<void> _go() async {
    final err = await context.read<AppState>().add(_c.text, _audio);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'بدأ التحميل، تابعه من تبويب التحميلات')));
    if (err == null) _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final recent = s.items.where((e) => e.status == DlStatus.done).take(2);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(children: [
          Image.asset('assets/flixgo-icon.png', width: 30, height: 30),
          const SizedBox(width: 8),
          const Text('FlixGo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        const Text('ماذا تريد أن تحمّل؟',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('رابط الفيديو أو الصوت',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(hintText: 'الصق الرابط هنا'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  onPressed: _paste,
                  tooltip: 'لصق الرابط',
                  icon: const Icon(Icons.content_paste_rounded)),
            ]),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('فيديو')),
                ButtonSegment(value: true, label: Text('صوت فقط')),
              ],
              selected: {_audio},
              onSelectionChanged: (v) => setState(() => _audio = v.first),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, children: [
              for (final h in [1080, 720, 480, 0])
                ChoiceChip(
                  label: Text(h == 0 ? 'تلقائي' : '${h}p'),
                  selected: s.height == h,
                  onSelected: _audio ? null : (_) => s.update(height: h),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _go,
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('تحميل',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('المنصات المدعومة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(label: Text('يوتيوب')),
          Chip(label: Text('تيك توك')),
          Chip(label: Text('إنستغرام')),
          Chip(label: Text('فيسبوك')),
          Chip(label: Text('وغيرها')),
        ]),
        const SizedBox(height: 24),
        const Text('آخر التحميلات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Text('لا توجد تحميلات بعد',
              style: TextStyle(color: cs.onSurfaceVariant)),
        for (final it in recent)
          Panel(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Thumb(audio: it.audio, width: 52, height: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(fmtBytes(it.size),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}
