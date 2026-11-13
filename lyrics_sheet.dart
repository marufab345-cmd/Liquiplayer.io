import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_controller.dart';

class LyricsSheet extends StatelessWidget {
  const LyricsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final lyrics = audio.currentTrack.lyrics;
    final pos = audio.position;

    int activeIndex = 0;
    for (int i = 0; i < lyrics.length; i++) {
      if (pos >= lyrics[i].timestamp) {
        activeIndex = i;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.11,
      minChildSize: 0.11,
      maxChildSize: 0.72,
      snap: true,
      snapSizes: const [0.11, 0.72],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0C).withValues(alpha: 0.78),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.0,
                  ),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LIVE LYRICS & QUEUE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Colors.white60,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: audio.adaptiveAccent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(lyrics.length, (i) {
                    final isActive = i == activeIndex;
                    return GestureDetector(
                      onTap: () => audio.seek(lyrics[i].timestamp),
                      child: AnimatedScale(
                        scale: isActive ? 1.04 : 0.96,
                        alignment: Alignment.centerLeft,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 280),
                            style: TextStyle(
                              fontSize: isActive ? 24 : 18,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.5,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.28),
                              shadows: isActive
                                  ? [
                                      Shadow(
                                        color: audio.adaptiveAccent
                                            .withValues(alpha: 0.7),
                                        blurRadius: 18,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(lyrics[i].text),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
