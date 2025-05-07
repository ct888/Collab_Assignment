import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:seek_here/Model/music.dart';
import 'package:seek_here/utils/spotify_launcher.dart';

class MusicPlayerWidget extends StatefulWidget {
  final MusicTrack track;
  final bool isPlaying;
  final VoidCallback onTogglePlayback;
  final VoidCallback onClose;

  const MusicPlayerWidget({
    Key? key,
    required this.track,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _position = 0;
  double _duration = 30.0; // Spotify preview is typically 30 seconds
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.track.hasPreview) {
      _initAudioPlayer();
    } else {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void didUpdateWidget(MusicPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the track changed or play state changed
    if (oldWidget.track.id != widget.track.id ||
        oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _playAudio();
      } else {
        _pauseAudio();
      }
    }
  }

  void _initAudioPlayer() async {
    // Set up listeners
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position.inSeconds.toDouble();
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      widget.onTogglePlayback();
      setState(() {
        _position = 0;
      });
    });

    try {
      if (widget.track.previewUrl != null &&
          widget.track.previewUrl!.isNotEmpty) {
        await _audioPlayer.setSourceUrl(widget.track.previewUrl!);
        if (widget.isPlaying) {
          _playAudio();
        }
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _isInitialized = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track info row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.track.albumImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Track details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.track.artists.join(', '),
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.track.albumName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            if (widget.track.hasPreview) ...[
              const SizedBox(height: 16),
              // Progress bar
              Column(
                children: [
                  Slider(
                    value: _position.clamp(0, _duration),
                    min: 0,
                    max: _duration,
                    onChanged: (value) async {
                      setState(() {
                        _position = value;
                      });
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                  // Time indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _isInitialized ? widget.onTogglePlayback : null,
                  ),
                ],
              ),
            ] else
            // Show message when no preview is available
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    "No preview available for this track.\nOpen in Spotify to listen to the full song.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // Spotify button - prominent for tracks without preview
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed:
                    () => SpotifyLauncher.openSpotify(
                  context,
                  spotifyUri: widget.track.spotifyUri,
                  fallbackUrl: widget.track.externalUrl,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  widget.track.hasPreview
                      ? 'Listen Full Track on Spotify'
                      : 'Open in Spotify',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954), // Spotify green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Emotional category indicator
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final Duration duration = Duration(seconds: seconds.toInt());
    final String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String secondsStr = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$secondsStr';
  }
}