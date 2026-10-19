import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _server(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.server);
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('عنوان الخادم'),
        content: TextField(
            controller: c,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: 'http://192.168.1.10:8000')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (v != null && v.trim().isNotEmpty) s.update(server: v);
  }

  Future<void> _quality(BuildContext context, AppState s) async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('الجودة الافتراضية'),
        children: [
          for (final h in [1080, 720, 480, 0])
            SimpleDialogOption(
                onPressed: () => Navigator.pop(context, h),
                child: Text(h == 0 ? 'تلقائي' : '${h}p')),
        ],
      ),
    );
    if (v != null) s.update(height: v);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final failed = s.items.where((e) => e.status == DlStatus.failed).length;
    Widget head(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        );
    Widget val(String t) => Text(t, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('الإعدادات',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        head('التحميل'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              title: const Text('عنوان الخادم'),
              subtitle: Text(s.server, textDirection: TextDirection.ltr),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _server(context, s),
            ),
            ListTile(
              title: const Text('الجودة الافتراضية'),
              trailing: val(s.height == 0 ? 'تلقائي' : '${s.height}p'),
              onTap: () => _quality(context, s),
            ),
            SwitchListTile(
              title: const Text('حفظ تلقائي في المعرض'),
              subtitle: const Text('الفيديو في معرض الصور، والصوت في التنزيلات'),
              value: s.autoSave,
              onChanged: (v) => s.update(autoSave: v),
            ),
            SwitchListTile(
              title: const Text('Wi‑Fi فقط'),
              value: s.wifiOnly,
              onChanged: (v) => s.update(wifiOnly: v),
            ),
          ]),
        ),
        head('المظهر'),
        Panel(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text('الوضع الداكن'),
            value: s.dark,
            onChanged: (v) => s.update(dark: v),
          ),
        ),
        head('عام'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              title: const Text('مسح التحميلات الفاشلة'),
              trailing: val('$failed'),
              onTap: s.clearFailed,
            ),
            ListTile(title: const Text('الإصدار'), trailing: val('1.0')),
          ]),
        ),
      ],
    );
  }
}