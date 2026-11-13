import 'package:flutter/material.dart';

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine(this.timestamp, this.text);
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? uri;
  final int? localMediaId;
  final Duration duration;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<LyricLine> lyrics;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.uri,
    this.localMediaId,
    required this.duration,
    required this.accentColor,
    required this.gradientColors,
    this.lyrics = const [],
  });

  static List<Track> demoTracks() {
    return const [
      Track(
        id: '1',
        title: 'Midnight Obsidian',
        artist: 'Kiasmos & Olafur',
        album: 'Blurred EP',
        duration: Duration(minutes: 4, seconds: 12),
        accentColor: Color(0xFF8B5CF6),
        gradientColors: [Color(0xFF8B5CF6), Color(0xFF3B0764), Color(0xFF06B6D4)],
        lyrics: [
          LyricLine(Duration(seconds: 0), 'Sub-bass hums beneath the glass'),
          LyricLine(Duration(seconds: 6), 'Reflections bend in midnight black'),
          LyricLine(Duration(seconds: 12), 'Every pulse a neon trace'),
          LyricLine(Duration(seconds: 18), 'Floating weightless out of phase'),
          LyricLine(Duration(seconds: 25), 'Hold the frequency in light'),
          LyricLine(Duration(seconds: 32), 'Dissolving static into night'),
        ],
      ),
      Track(
        id: '2',
        title: 'Cyanide Drift',
        artist: 'Nils Frahm',
        album: 'Tripping with Nils',
        duration: Duration(minutes: 3, seconds: 48),
        accentColor: Color(0xFF06B6D4),
        gradientColors: [Color(0xFF06B6D4), Color(0xFF0E7490), Color(0xFF8B5CF6)],
        lyrics: [
          LyricLine(Duration(seconds: 0), 'Cold electric ocean tide'),
          LyricLine(Duration(seconds: 8), 'Analog keys begin to glide'),
          LyricLine(Duration(seconds: 16), 'Echoes bounce across the frame'),
          LyricLine(Duration(seconds: 24), 'Nothing ever sounds the same'),
        ],
      ),
      Track(
        id: '3',
        title: 'Hyperion Pulse',
        artist: 'Rival Consoles',
        album: 'Persona',
        duration: Duration(minutes: 5, seconds: 04),
        accentColor: Color(0xFFEC4899),
        gradientColors: [Color(0xFFEC4899), Color(0xFF831843), Color(0xFF8B5CF6)],
        lyrics: [
          LyricLine(Duration(seconds: 0), 'Fractured rhythm in the dark'),
          LyricLine(Duration(seconds: 10), 'Every transient leaves a mark'),
          LyricLine(Duration(seconds: 20), 'Pure obsidian surround'),
          LyricLine(Duration(seconds: 30), 'Sculpted geometry of sound'),
        ],
      ),
      Track(
        id: '4',
        title: 'Aetherial',
        artist: 'Max Cooper',
        album: 'Unspoken Words',
        duration: Duration(minutes: 4, seconds: 35),
        accentColor: Color(0xFF10B981),
        gradientColors: [Color(0xFF10B981), Color(0xFF064E3B), Color(0xFF06B6D4)],
        lyrics: [
          LyricLine(Duration(seconds: 0), 'Particles align in space'),
          LyricLine(Duration(seconds: 9), 'Harmonics interlace'),
          LyricLine(Duration(seconds: 18), 'Silence frames the lightest tone'),
        ],
      ),
    ];
  }
}
