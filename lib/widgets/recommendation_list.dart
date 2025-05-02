import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/video.dart';
import '../../models/music.dart';

class VideoRecommendationList extends StatelessWidget {
  final List<VideoItem> videos;
  final Function(VideoItem) onVideoSelected;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const VideoRecommendationList({
    super.key,
    required this.videos,
    required this.onVideoSelected,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${videos.length} Video${videos.length != 1 ? 's' : ''} Found',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(8.0),
            itemCount: videos.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the bottom
              if (index == videos.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final video = videos[index];
              return VideoCard(video: video, onTap: () => onVideoSelected(video));
            },
          ),
        ),
      ],
    );
  }
}

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with emotion category badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  child: Image.network(
                    video.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Added loading placeholder
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.error_outline, size: 40),
                        ),
                      );
                    },
                  ),
                ),
                // Emotion category badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEmotionColor(video.emotionCategory),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      video.emotionCategory.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video title
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Channel and publish date
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.channelTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(video.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description preview
                  if (video.description.isNotEmpty)
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotionCategory) {
    switch (emotionCategory.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'calm':
        return Colors.blue;
      case 'sad':
        return Colors.indigo;
      case 'anxious':
        return Colors.purple;
      case 'angry':
        return Colors.red;
      case 'stressed':
        return Colors.orange;
      case 'motivated':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}

class MusicGridCard extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final String coverImage;
  final Color coverColor;
  final VoidCallback onTap;
  final bool hasPreview;
  final Function() onPlayPressed;

  const MusicGridCard({
    Key? key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverImage,
    required this.coverColor,
    required this.onTap,
    required this.hasPreview,
    required this.onPlayPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image area with overlay controls
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or fallback
                  coverImage.isNotEmpty
                      ? Image.network(
                        coverImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildCoverFallback(),
                      )
                      : _buildCoverFallback(),

                  // Top-left controls overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        // Play/Open button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              hasPreview
                                  ? Icons.play_circle_outline
                                  : Icons.open_in_new,
                              color: Colors.white,
                            ),
                            onPressed: onPlayPressed,
                            tooltip:
                                hasPreview ? "Play preview" : "Open in Spotify",
                            iconSize: 24,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Song info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$duration • $artist',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: coverColor,
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }
}

class MusicRecommendationGrid extends StatefulWidget {
  final List<MusicTrack> tracks;
  final Function(MusicTrack) onTrackSelected;
  final Function() onLoadMore;
  final Function() onRefresh;
  final bool isLoadingMore;
  final bool hasMoreItems;

  const MusicRecommendationGrid({
    Key? key,
    required this.tracks,
    required this.onTrackSelected,
    required this.onLoadMore,
    required this.onRefresh,
    this.isLoadingMore = false,
    this.hasMoreItems = true,
  }) : super(key: key);

  @override
  State<MusicRecommendationGrid> createState() => _MusicRecommendationGridState();
}

class _MusicRecommendationGridState extends State<MusicRecommendationGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 
        _scrollController.position.maxScrollExtent - 500 &&
        widget.hasMoreItems &&
        !widget.isLoadingMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${widget.tracks.length} Music Result${widget.tracks.length != 1 ? 's' : ''}:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        // Grid of music cards with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.onRefresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = widget.tracks[index];

                        // Generate a color based on the track name if no album art
                        final coverColor = _getColorFromName(track.name);

                        return MusicGridCard(
                          title: track.name,
                          artist: track.artists.join(', '),
                          duration: _formatDuration(
                            track.name.length,
                          ), // Using name length as mock duration
                          coverImage: track.albumImageUrl,
                          coverColor: coverColor,
                          hasPreview: track.hasPreview,
                          onTap: () => widget.onTrackSelected(track),
                          onPlayPressed: () => widget.onTrackSelected(track),
                        );
                      },
                      childCount: widget.tracks.length,
                    ),
                  ),
                ),
                // Loading indicator at the bottom
                SliverToBoxAdapter(
                  child: widget.isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : !widget.hasMoreItems && widget.tracks.isNotEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("You've reached the end"),
                              ),
                            )
                          : const SizedBox(height: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to format duration (mock implementation)
  String _formatDuration(int seconds) {
    // Create a mock duration based on string length
    final minutes = 3 + (seconds % 3);
    final secs = (10 + (seconds * 7) % 50).toString().padLeft(2, '0');
    return '$minutes:$secs MIN';
  }

  // Helper method to get a color from a string
  Color _getColorFromName(String name) {
    final colors = [
      Colors.purple.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.amber.shade600,
      Colors.pink.shade400,
      Colors.deepOrange.shade400,
    ];

    // Use the string hash to pick a color
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}
