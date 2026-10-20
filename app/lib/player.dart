// FlixGo — built-in player (uses the video_player package, handles video and audio).
// Downloads in this app are still simulated, so the player opens a sample file.
// To play a real downloaded file use: VideoPlayerController.file(File(path)).
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const kDemoVideo =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
const kDemoAudio = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

class PlayerPage extends StatefulWidget {
  final String title, subtitle, source, pageTitle, errorText, demoText;
  final bool audio, rtl;
  final Color accent;

  const PlayerPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.pageTitle,
    required this.errorText,
    required this.demoText,
    required this.audio,
    required this.rtl,
    required this.accent,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static const bg = Color(0xFF130E2B);
  static const track = Color(0xFF2A2060);
  static const card = Color(0xFF241B52);
  static const line = Color(0xFF3A2F78);
  static const ink = Color(0xFFF4F0FF);
  static const mute = Color(0xFFB3ABDB);
  static const aqua = Color(0xFF2DD4BF);
  static const violet = Color(0xFF6D4AFF);
  static const magenta = Color(0xFFC0266F);
  static const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  late final VideoPlayerController ctrl;
  bool ready = false, failed = false, muted = false;
  int speedIdx = 1;

  @override
  void initState() {
    super.initState();
    ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.source));
    ctrl.addListener(_onTick);
    ctrl.initialize().then((_) {
      if (!mounted) return;
      setState(() => ready = true);
      ctrl.play();
    }).catchError((Object _) {
      if (mounted) setState(() => failed = true);
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ctrl.removeListener(_onTick);
    ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!ready) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
  }

  void _skip(int seconds) {
    if (!ready) return;
    final total = ctrl.value.duration;
    var target = ctrl.value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    ctrl.seekTo(target);
  }

  void _cycleSpeed() {
    speedIdx = (speedIdx + 1) % speeds.length;
    ctrl.setPlaybackSpeed(speeds[speedIdx]);
    setState(() {});
  }

  void _toggleMute() {
    muted = !muted;
    ctrl.setVolume(muted ? 0.0 : 1.0);
    setState(() {});
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  String get _speedText =>
      '${speeds[speedIdx].toString().replaceAll(RegExp(r'\.0$'), '')}x';

  Widget _circle(IconData ic, VoidCallback f, String label,
      {double size = 48, double icon = 24, bool primary = false}) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: f,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary ? null : card,
            gradient: primary
                ? const LinearGradient(colors: [violet, magenta])
                : null,
            border: primary ? null : Border.all(color: line, width: 1.5),
            boxShadow: primary
                ? const [
                    BoxShadow(
                        color: Color(0x736D4AFF),
                        blurRadius: 26,
                        offset: Offset(0, 10))
                  ]
                : null,
          ),
          child: Icon(ic, color: primary ? Colors.white : ink, size: icon),
        ),
      ),
    );
  }

  Widget _media() {
    if (failed) {
      return Container(
        height: 197,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: line, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: mute, size: 40),
          const SizedBox(height: 10),
          Text(widget.errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mute, height: 1.5)),
        ]),
      );
    }
    if (!ready) {
      return Container(
        height: 197,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: card, borderRadius: BorderRadius.circular(20)),
        child: const CircularProgressIndicator(color: aqua),
      );
    }
    if (widget.audio) {
      return Center(
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(colors: [widget.accent, violet]),
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Colors.white, size: 96),
          ),
        ),
      );
    }
    final playing = ctrl.value.isPlaying;
    return GestureDetector(
      onTap: _toggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: ctrl.value.aspectRatio == 0 ? 16 / 9 : ctrl.value.aspectRatio,
          child: Stack(alignment: Alignment.center, children: [
            VideoPlayer(ctrl),
            if (!playing)
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0x73130E2B)),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 36),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = ctrl.value;
    final total = v.duration.inMilliseconds.toDouble();
    final pos = total > 0
        ? v.position.inMilliseconds.clamp(0, v.duration.inMilliseconds).toDouble()
        : 0.0;
    final playing = ready && v.isPlaying;

    return Directionality(
      textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _circle(Icons.arrow_back_rounded,
                          () => Navigator.of(context).maybePop(), 'back',
                          size: 44, icon: 22),
                      const SizedBox(width: 12),
                      Text(widget.pageTitle,
                          style: const TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 24),
                    _media(),
                    const SizedBox(height: 22),
                    Text(widget.title,
                        style: const TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: const TextStyle(color: mute, fontSize: 13)),
                    const SizedBox(height: 22),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            activeTrackColor: aqua,
                            inactiveTrackColor: track,
                            thumbColor: Colors.white,
                            overlayColor: const Color(0x292DD4BF),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: pos,
                            max: total > 0 ? total : 1,
                            onChanged: ready
                                ? (x) => ctrl
                                    .seekTo(Duration(milliseconds: x.round()))
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(v.position),
                                    style: const TextStyle(
                                        color: mute, fontSize: 12.5)),
                                Text(_fmt(v.duration),
                                    style: const TextStyle(
                                        color: mute, fontSize: 12.5)),
                              ]),
                        ),
                        const SizedBox(height: 22),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Semantics(
                                button: true,
                                label: 'speed',
                                child: GestureDetector(
                                  onTap: ready ? _cycleSpeed : null,
                                  child: Container(
                                    height: 44,
                                    constraints:
                                        const BoxConstraints(minWidth: 56),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: card,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                            color: line, width: 1.5)),
                                    child: Text(_speedText,
                                        style: const TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ),
                                ),
                              ),
                              _circle(Icons.replay_10_rounded,
                                  () => _skip(-10), '-10s'),
                              _circle(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  _toggle,
                                  playing ? 'pause' : 'play',
                                  size: 72,
                                  icon: 36,
                                  primary: true),
                              _circle(Icons.forward_10_rounded,
                                  () => _skip(10), '+10s'),
                              _circle(
                                  muted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  _toggleMute,
                                  'mute',
                                  size: 44,
                                  icon: 22),
                            ]),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(widget.demoText,
                          style: const TextStyle(color: mute, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
