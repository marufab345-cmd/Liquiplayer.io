import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/audio_controller.dart';
import '../theme/liquid_glass.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/tilt_artwork.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  double _verticalDrag = 0.0;
  double _pinchScale = 1.0;
  late final AnimationController _dismissSpring;
  double _springStart = 0.0;

  @override
  void initState() {
    super.initState();
    _dismissSpring = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _verticalDrag = _springStart * (1.0 - _dismissSpring.value);
        });
      });
  }

  @override
  void dispose() {
    _dismissSpring.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final track = audio.currentTrack;
    final accent = audio.adaptiveAccent;

    final maxMs = audio.duration.inMilliseconds.clamp(1, 99999999);
    final currentMs = audio.position.inMilliseconds.clamp(0, maxMs);

    final dragScale =
        (1.0 - (_verticalDrag / 900.0)).clamp(0.84, 1.0) * _pinchScale;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0 || _verticalDrag > 0) {
            _dismissSpring.stop();
            setState(() {
              _verticalDrag = (_verticalDrag + details.delta.dy).clamp(0.0, 420.0);
            });
          }
        },
        onVerticalDragEnd: (_) {
          if (_verticalDrag > 125) {
            Navigator.of(context).pop();
          } else {
            _springStart = _verticalDrag;
            final sim = SpringSimulation(LiquidSpring.standard, 0.0, 1.0, 0.0);
            _dismissSpring.animateWith(sim);
          }
        },
        onScaleUpdate: (details) {
          if (details.scale < 1.0) {
            setState(() {
              _pinchScale = details.scale.clamp(0.75, 1.0);
            });
          }
        },
        onScaleEnd: (_) {
          if (_pinchScale < 0.85) {
            Navigator.of(context).pop();
          } else {
            setState(() => _pinchScale = 1.0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _verticalDrag * 0.65),
          child: Transform.scale(
            scale: dragScale,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 650),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 0.95,
                        colors: [
                          accent.withValues(alpha: 0.34),
                          const Color(0xFF030303),
                          const Color(0xFF000000),
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TactileBounce(
                              onTap: () => Navigator.of(context).pop(),
                              child: LiquidGlass(
                                borderRadius: 16,
                                opacity: 0.07,
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'NOW PLAYING',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.album,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            LiquidGlass(
                              borderRadius: 16,
                              opacity: 0.07,
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.spatial_audio_off_rounded,
                                color: Color(0xFF06B6D4),
                                size: 22,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(flex: 2),

                        Hero(
                          tag: 'album-art-${track.id}',
                          child: TiltArtwork(
                            track: track,
                            size: MediaQuery.of(context).size.width * 0.78,
                          ),
                        ),

                        const Spacer(flex: 2),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.artist,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: accent.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '24-BIT FLAC',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            activeTrackColor: accent,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.5,
                            ),
                            overlayColor: accent.withValues(alpha: 0.25),
                          ),
                          child: Slider(
                            min: 0,
                            max: maxMs.toDouble(),
                            value: currentMs.toDouble(),
                            onChanged: (v) =>
                                audio.seek(Duration(milliseconds: v.round())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(audio.position),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                _format(audio.duration),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        LiquidGlass(
                          borderRadius: 32,
                          blurSigma: 24,
                          opacity: 0.08,
                          tintColor: accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TactileBounce(
                                    onTap: audio.toggleShuffle,
                                    child: Icon(
                                      Icons.shuffle_rounded,
                                      size: 22,
                                      color: audio.isShuffle
                                          ? const Color(0xFF06B6D4)
                                          : Colors.white54,
                                    ),
                                  ),
                                  TactileBounce(
                                    onTap: audio.previousTrack,
                                    child: const Icon(
                                      Icons.skip_previous_rounded,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TactileBounce(
                                    onTap: audio.togglePlayPause,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            accent,
                                            const Color(0xFF06B6D4),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(alpha: 0.55),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        audio.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  TactileBounce(
                                    onTap: audio.nextTrack,
                                    child: const Icon(
                                      Icons.skip_next_rounded,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TactileBounce(
                                    onTap: audio.cycleLoopMode,
                                    child: Icon(
                                      audio.loopMode == LoopMode.one
                                          ? Icons.repeat_one_rounded
                                          : Icons.repeat_rounded,
                                      size: 22,
                                      color: audio.loopMode != LoopMode.off
                                          ? const Color(0xFF06B6D4)
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.volume_mute_rounded,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3.0,
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor:
                                            Colors.white.withValues(alpha: 0.14),
                                        thumbColor: Colors.white,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                      ),
                                      child: Slider(
                                        value: audio.volume,
                                        onChanged: audio.setVolume,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.volume_up_rounded,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 92),
                      ],
                    ),
                  ),
                ),

                const LyricsSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
