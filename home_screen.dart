import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/audio_controller.dart';
import '../theme/liquid_glass.dart';
import '../widgets/mini_player.dart';
import '../widgets/tilt_artwork.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselController = PageController(viewportFraction: 0.76);
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final tracks = audio.tracks;
    final featured = audio.continueListening;

    final overscrollStretch =
        _scrollOffset < 0 ? (1.0 + (_scrollOffset.abs() / 600)).clamp(1.0, 1.12) : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    audio.adaptiveAccent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Transform.scale(
                    scale: overscrollStretch,
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GOOD EVENING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                  color: audio.adaptiveAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your Soundscape',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                          LiquidGlass(
                            borderRadius: 50,
                            opacity: 0.08,
                            tintColor: audio.adaptiveAccent,
                            padding: const EdgeInsets.all(3),
                            child: const CircleAvatar(
                              radius: 21,
                              backgroundColor: Color(0xFF141418),
                              child: Icon(
                                Icons.waves_rounded,
                                color: Color(0xFF06B6D4),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: LiquidGlass(
                      borderRadius: 18,
                      opacity: 0.06,
                      tintColor: audio.adaptiveAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: TextField(
                        onChanged: audio.setSearchQuery,
                        style: const TextStyle(color: Colors.white, fontSize: 14.5),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search local tracks, artists, albums...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          icon: Icon(
                            Icons.search_rounded,
                            color: audio.adaptiveAccent,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
                        child: Text(
                          'Continue Listening',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          controller: _carouselController,
                          padEnds: false,
                          itemCount: featured.length,
                          itemBuilder: (context, index) {
                            final item = featured[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 20 : 10,
                                right: index == featured.length - 1 ? 20 : 4,
                              ),
                              child: _ContinueListeningCard(
                                track: item,
                                onTap: () => audio.selectTrack(item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 26, 20, 12),
                    child: Text(
                      'Lossless Library',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 175),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        final isSelected = track.id == audio.currentTrack.id;

                        return _StaggeredTrackTile(
                          index: index,
                          track: track,
                          isSelected: isSelected,
                          durationLabel: _formatDuration(track.duration),
                          onTap: () => audio.selectTrack(track),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(),
                  const SizedBox(height: 10),
                  LiquidGlass(
                    borderRadius: 24,
                    opacity: 0.05,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavIcon(
                          icon: Icons.home_filled,
                          label: 'Library',
                          active: true,
                          accent: audio.adaptiveAccent,
                        ),
                        const _NavIcon(
                          icon: Icons.album_outlined,
                          label: 'Albums',
                          active: false,
                          accent: Colors.white,
                        ),
                        const _NavIcon(
                          icon: Icons.equalizer_rounded,
                          label: 'Spatial EQ',
                          active: false,
                          accent: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueListeningCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _ContinueListeningCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TactileBounce(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ArtworkVisual(track: track, size: 260),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: LiquidGlass(
                borderRadius: 18,
                blurSigma: 18,
                opacity: 0.12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: track.accentColor,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredTrackTile extends StatelessWidget {
  final int index;
  final Track track;
  final bool isSelected;
  final String durationLabel;
  final VoidCallback onTap;

  const _StaggeredTrackTile({
    required this.index,
    required this.track,
    required this.isSelected,
    required this.durationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final delay = (index * 55).clamp(0, 450);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 18),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TactileBounce(
          onTap: onTap,
          child: LiquidGlass(
            borderRadius: 18,
            blurSigma: 16,
            opacity: isSelected ? 0.11 : 0.04,
            tintColor: isSelected ? track.accentColor : null,
            showTopReflection: isSelected,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ArtworkVisual(track: track, size: 50),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected ? track.accentColor : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist} • ${track.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  durationLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: Colors.white.withValues(alpha: 0.5),
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

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: active ? accent : Colors.white54,
        ),
        if (active) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ],
    );
  }
}
