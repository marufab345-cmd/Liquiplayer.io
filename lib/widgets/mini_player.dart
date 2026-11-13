import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import '../providers/audio_controller.dart';
import '../screens/full_player_screen.dart';
import '../theme/liquid_glass.dart';
import 'tilt_artwork.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  double _dragX = 0.0;
  late final AnimationController _snapController;
  double _snapStart = 0.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _dragX = _snapStart * (1.0 - _snapController.value);
        });
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: const FullPlayerScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final track = audio.currentTrack;
    final progress = audio.duration.inMilliseconds > 0
        ? (audio.position.inMilliseconds / audio.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final opacity = (1.0 - (_dragX.abs() / 180.0)).clamp(0.25, 1.0);

    return GestureDetector(
      onTap: () => _openFullPlayer(context),
      onHorizontalDragUpdate: (details) {
        _snapController.stop();
        setState(() {
          _dragX += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragX < -75) {
          audio.nextTrack();
        } else if (_dragX > 75) {
          audio.previousTrack();
        }
        _snapStart = _dragX;
        final sim = SpringSimulation(LiquidSpring.standard, 0.0, 1.0, 0.0);
        _snapController.animateWith(sim);
      },
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Opacity(
          opacity: opacity,
          child: LiquidGlass(
            borderRadius: 22,
            blurSigma: 24,
            opacity: 0.08,
            tintColor: audio.adaptiveAccent,
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'album-art-${track.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: ArtworkVisual(track: track, size: 46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TactileBounce(
                      onTap: audio.togglePlayPause,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(
                          audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TactileBounce(
                      onTap: audio.nextTrack,
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.2,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(audio.adaptiveAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
