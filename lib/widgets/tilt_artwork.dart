import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/track.dart';
import '../theme/liquid_glass.dart';

class TiltArtwork extends StatefulWidget {
  final Track track;
  final double size;
  final bool enableGyro;

  const TiltArtwork({
    super.key,
    required this.track,
    this.size = 290,
    this.enableGyro = true,
  });

  @override
  State<TiltArtwork> createState() => _TiltArtworkState();
}

class _TiltArtworkState extends State<TiltArtwork>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  Offset _gyroOffset = Offset.zero;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  late final AnimationController _springController;
  Offset _springStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _tilt = Offset.lerp(_springStart, Offset.zero, _springController.value)!;
        });
      });

    if (widget.enableGyro && !kIsWeb) {
      _gyroSub = gyroscopeEventStream().listen((event) {
        if (!mounted) return;
        setState(() {
          _gyroOffset = Offset(
            (_gyroOffset.dx * 0.85 + event.y * 0.04).clamp(-0.18, 0.18),
            (_gyroOffset.dy * 0.85 + event.x * 0.04).clamp(-0.18, 0.18),
          );
        });
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _springController.stop();
    setState(() {
      final dx = (_tilt.dx + details.delta.dx / (widget.size * 0.5)).clamp(-0.35, 0.35);
      final dy = (_tilt.dy - details.delta.dy / (widget.size * 0.5)).clamp(-0.35, 0.35);
      _tilt = Offset(dx, dy);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _springStart = _tilt;
    final sim = SpringSimulation(LiquidSpring.standard, 0.0, 1.0, 0.0);
    _springController.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    final rotY = (_tilt.dx + _gyroOffset.dx) * 0.45;
    final rotX = (_tilt.dy + _gyroOffset.dy) * 0.45;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(rotX)
          ..rotateY(rotY),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.track.accentColor.withValues(alpha: 0.42),
                blurRadius: 56,
                spreadRadius: -6,
                offset: Offset(rotY * 45, 22 - rotX * 45),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ArtworkVisual(track: widget.track, size: widget.size),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + rotY * 2, -1.0 - rotX * 2),
                        end: Alignment(1.0 + rotY * 2, 1.0 - rotX * 2),
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.0,
                    ),
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

class ArtworkVisual extends StatelessWidget {
  final Track track;
  final double size;

  const ArtworkVisual({super.key, required this.track, required this.size});

  @override
  Widget build(BuildContext context) {
    if (track.localMediaId != null && !kIsWeb) {
      return QueryArtworkWidget(
        id: track.localMediaId!,
        type: ArtworkType.AUDIO,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _ProceduralAlbumArt(track: track),
      );
    }
    return _ProceduralAlbumArt(track: track);
  }
}

class _ProceduralAlbumArt extends StatelessWidget {
  final Track track;

  const _ProceduralAlbumArt({required this.track});

  @override
  Widget build(BuildContext context) {
    final hash = track.id.hashCode;
    final angle = (hash % 360) * math.pi / 180;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(math.cos(angle), math.sin(angle)),
          end: Alignment(-math.cos(angle), -math.sin(angle)),
          colors: track.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
