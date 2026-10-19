import 'package:flutter/material.dart';

String fmtBytes(num b) {
  if (b <= 0) return '—';
  const u = ['ب', 'ك.ب', 'م.ب', 'غ.ب'];
  var i = 0;
  var v = b.toDouble();
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i < 2 ? 0 : 1)} ${u[i]}';
}

String fmtSpeed(double s) => s <= 0 ? '' : '${fmtBytes(s)}/ث';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class Thumb extends StatelessWidget {
  final bool audio;
  final double? width;
  final double height;
  const Thumb({super.key, required this.audio, this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(audio ? Icons.music_note_rounded : Icons.play_arrow_rounded,
          color: cs.primary, size: height > 80 ? 36 : 26),
    );
  }
}
