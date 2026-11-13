import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/track.dart';

class AudioController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Track> _allTracks = Track.demoTracks();
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _volume = 0.85;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 4, seconds: 12);
  Color _adaptiveAccent = const Color(0xFF8B5CF6);
  Timer? _demoTicker;

  List<Track> get tracks {
    if (_searchQuery.trim().isEmpty) return _allTracks;
    final q = _searchQuery.toLowerCase();
    return _allTracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q))
        .toList();
  }

  List<Track> get continueListening => _allTracks.take(4).toList();
  Track get currentTrack => _allTracks[_currentIndex];
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  double get volume => _volume;
  Duration get position => _position;
  Duration get duration => _duration;
  Color get adaptiveAccent => _adaptiveAccent;

  Future<void> init() async {
    _adaptiveAccent = currentTrack.accentColor;

    _player.positionStream.listen((pos) {
      if (currentTrack.uri != null) {
        _position = pos;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      if (currentTrack.uri != null) {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          nextTrack();
        }
        notifyListeners();
      }
    });

    await _scanLocalAudio();
  }

  Future<void> _scanLocalAudio() async {
    if (kIsWeb) return;
    try {
      final hasPermission = await _audioQuery.checkAndRequest(retryRequest: true);
      if (!hasPermission) return;

      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      final validSongs = songs.where((s) => (s.duration ?? 0) > 15000).toList();
      if (validSongs.isEmpty) return;

      const palettePool = [
        [Color(0xFF8B5CF6), Color(0xFF3B0764), Color(0xFF06B6D4)],
        [Color(0xFF06B6D4), Color(0xFF0E7490), Color(0xFF8B5CF6)],
        [Color(0xFFEC4899), Color(0xFF831843), Color(0xFF8B5CF6)],
        [Color(0xFF10B981), Color(0xFF064E3B), Color(0xFF06B6D4)],
      ];

      _allTracks = List.generate(validSongs.length, (i) {
        final s = validSongs[i];
        final colors = palettePool[i % palettePool.length];
        return Track(
          id: s.id.toString(),
          title: s.title,
          artist: s.artist ?? 'Unknown Artist',
          album: s.album ?? 'Local Library',
          uri: s.uri,
          localMediaId: s.id,
          duration: Duration(milliseconds: s.duration ?? 180000),
          accentColor: colors.first,
          gradientColors: colors,
          lyrics: Track.demoTracks()[i % Track.demoTracks().length].lyrics,
        );
      });

      _currentIndex = 0;
      _duration = currentTrack.duration;
      _adaptiveAccent = currentTrack.accentColor;
      notifyListeners();
    } catch (_) {
      // Falls back seamlessly to built-in lossless preview catalog
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> selectTrack(Track track) async {
    final idx = _allTracks.indexWhere((t) => t.id == track.id);
    if (idx == -1) return;

    HapticFeedback.mediumImpact();
    _currentIndex = idx;
    _position = Duration.zero;
    _duration = track.duration;
    _adaptiveAccent = track.accentColor;
    notifyListeners();

    await _extractAdaptiveColor(track);

    if (track.uri != null) {
      _demoTicker?.cancel();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(track.uri!)));
      await _player.play();
      _isPlaying = true;
    } else {
      await _player.stop();
      _isPlaying = true;
      _startDemoTicker();
    }
    notifyListeners();
  }

  Future<void> _extractAdaptiveColor(Track track) async {
    if (track.localMediaId == null) {
      _adaptiveAccent = track.accentColor;
      return;
    }
    try {
      final bytes = await _audioQuery.queryArtwork(
        track.localMediaId!,
        ArtworkType.AUDIO,
        size: 200,
      );
      if (bytes != null) {
        final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(bytes),
          maximumColorCount: 8,
        );
        _adaptiveAccent = palette.vibrantColor?.color ??
            palette.lightVibrantColor?.color ??
            track.accentColor;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _startDemoTicker() {
    _demoTicker?.cancel();
    _demoTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_isPlaying) return;
      _position += const Duration(milliseconds: 250);
      if (_position >= _duration) {
        nextTrack();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> togglePlayPause() async {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _isPlaying = false;
      if (currentTrack.uri != null) await _player.pause();
    } else {
      _isPlaying = true;
      if (currentTrack.uri != null) {
        await _player.play();
      } else {
        _startDemoTicker();
      }
    }
    notifyListeners();
  }

  Future<void> nextTrack() async {
    HapticFeedback.selectionClick();
    final next = (_currentIndex + 1) % _allTracks.length;
    await selectTrack(_allTracks[next]);
  }

  Future<void> previousTrack() async {
    HapticFeedback.selectionClick();
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1 + _allTracks.length) % _allTracks.length;
    await selectTrack(_allTracks[prev]);
  }

  Future<void> seek(Duration target) async {
    _position = target;
    if (currentTrack.uri != null) {
      await _player.seek(target);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    HapticFeedback.selectionClick();
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void cycleLoopMode() {
    HapticFeedback.selectionClick();
    _loopMode = LoopMode.values[(_loopMode.index + 1) % LoopMode.values.length];
    _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    if ((value - _volume).abs() >= 0.08) {
      HapticFeedback.selectionClick();
    }
    _volume = value.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTicker?.cancel();
    _player.dispose();
    super.dispose();
  }
}
