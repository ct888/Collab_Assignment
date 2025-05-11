import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seek_here/Model/video.dart';
import 'package:seek_here/ViewModel/videoViewModel.dart';
import 'package:seek_here/utils/logger.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
  final VoidCallback onClose;
  final VoidCallback? onVideoEnded;

  const VideoPlayerWidget({
    super.key,
    required this.videoId,
    required this.onClose,
    this.onVideoEnded,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _isPlaying = true;
  bool _showControls = false;
  Timer? _controlsTimer;
  final AppLogger _logger = AppLogger();
  bool _disposed = false;
  bool _isFullScreen = false; // Start in portrait mode (not full screen)
  bool _showDetails = false;

  // For swipe detection
  double _initialDragPos = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _logger.info('VideoPlayerWidget initState: videoId: ${widget.videoId}');
    WidgetsBinding.instance.addObserver(this);

    // Start in portrait mode by default
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Normal UI mode initially (not immersive)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initialize player
    _initializePlayer(); // Removed microtask delay, initialize directly
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _logger.info(
        'Video ID changed from ${oldWidget.videoId} to ${widget.videoId}',
      );
      _cleanupController();
      _initializePlayer(); // Initialize directly
    }
  }

  void _cleanupController() {
    if (_controller == null) return;

    try {
      _logger.info(
        'Cleaning up controller for videoId: ${_controller?.initialVideoId}',
      );
      _controller?.removeListener(_videoListener);
      // It's generally safer to pause before dispose, though dispose might handle it
      _controller?.pause();
      // Dispose might throw if called after widget disposal, handle gracefully
      _controller?.dispose();
      _controller = null;
    } catch (e, stacktrace) {
      _logger.error('Error cleaning up controller: $e\n$stacktrace');
      // Ensure controller is nullified even if dispose fails
      _controller = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ensure widget is still mounted and controller exists
    if (!mounted || _disposed || _controller == null || !_isPlayerReady) return;

    try {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState
            .inactive: // Also pause when inactive (e.g., split screen)
        case AppLifecycleState.detached: // Treat detached as paused for cleanup
          _logger.info('App lifecycle state changed to $state, pausing video.');
          _controller?.pause();
          break;
        case AppLifecycleState.resumed:
          // Only resume if it was playing before pausing and player is ready
          if (_isPlaying) {
            _logger.info(
              'App lifecycle state changed to resumed, resuming video.',
            );
            _controller?.play();
          } else {
            _logger.info(
              'App lifecycle state changed to resumed, video was paused.',
            );
          }
          break;
        // No specific action needed for hidden as of Flutter 3.13
        case AppLifecycleState.hidden:
          _logger.info('App lifecycle state changed to hidden.');
          break;
      }
    } catch (e, stacktrace) {
      _logger.error(
        'Error handling lifecycle state change ($state): $e\n$stacktrace',
      );
    }
  }

  void _initializePlayer() {
    if (_disposed) {
      _logger.info('InitializePlayer: Attempted to initialize while disposed.');
      return;
    }
    if (_controller != null) {
      _logger.warning(
        'InitializePlayer: Controller already exists. Cleaning up old one.',
      );
      _cleanupController();
    }

    _logger.info('Initializing player for videoId: ${widget.videoId}');
    // Reset state variables related to the player
    _isPlayerReady = false;
    _isPlaying = true; // Assume autoplay unless changed

    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideControls: true, // Keep YT controls hidden, we use custom ones
          enableCaption: true,
          useHybridComposition: true, // Often needed for compatibility
          // Consider adding:
          // disableDragSeek: true, // If you want to disable YT's drag seek
          // hideThumbnail: true, // Hide thumbnail once playback starts
          // controlsVisibleAtStart: false, // Ensure custom controls logic manages visibility
        ),
      )..addListener(_videoListener); // Chain addListener

      // Update the state immediately after creating the controller
      // This helps build the initial UI elements that depend on the controller
      if (mounted) {
        setState(() {});
      }
      _logger.info('Player controller created for videoId: ${widget.videoId}');
    } catch (e, stacktrace) {
      _logger.error('Error initializing player: $e\n$stacktrace');
      // Attempt to close gracefully if initialization fails
      if (mounted && !_disposed) {
        widget.onClose();
      }
    }
  }

  void _videoListener() {
    // Early exit if state is invalid
    if (!mounted || _disposed || _controller == null) {
      // Optionally log if listener fires in invalid state
      // _logger.warning('VideoListener fired but widget state is invalid.');
      return;
    }

    try {
      final controller = _controller!; // Use ! after null check
      final value = controller.value;

      // Check if readiness state changed
      if (value.isReady && !_isPlayerReady) {
        _logger.info('Player is ready for videoId: ${widget.videoId}');
        // Update state only if it changed and widget is mounted
        if (mounted) {
          setState(() => _isPlayerReady = true);
          // Start controls timer if autoplaying and ready
          if (_isPlaying) _showControlsTemporarily();
        }
      } else if (!value.isReady && _isPlayerReady) {
        _logger.warning(
          'Player became not ready for videoId: ${widget.videoId}',
        );
        if (mounted) {
          setState(() => _isPlayerReady = false);
        }
      }

      // Check if playing state changed (only if ready)
      if (_isPlayerReady) {
        final currentPlaying = value.isPlaying;
        if (currentPlaying != _isPlaying) {
          _logger.info(
            'Player playing state changed: $_isPlaying -> $currentPlaying',
          );
          if (mounted) {
            setState(() => _isPlaying = currentPlaying);
            // If playback starts automatically or manually, show controls
            if (_isPlaying) _showControlsTemporarily();
          }
        }

        // Check for video end state
        if (value.playerState == PlayerState.ended) {
          _logger.info('Video ended: ${widget.videoId}');
          _handleVideoEnded();
        }

        // Check for errors
        if (value.hasError) {
          _logger.error(
            'Youtube Player Error: ${value.errorCode} for videoId: ${widget.videoId}',
          );
          // Optionally handle specific error codes
          // Consider showing an error message or attempting recovery
          if (mounted && !_disposed) {
            // Maybe show error state or close
            // widget.onClose(); // Or show error message
          }
        }
      }
    } catch (e, stacktrace) {
      // Catch errors within the listener itself
      _logger.error('Error in video listener: $e\n$stacktrace');
      // Consider more robust error handling, e.g., closing the player
      if (mounted && !_disposed) {
        // widget.onClose();
      }
    }
  }

  void _handleVideoEnded() {
    if (!mounted || _disposed) return;
    _logger.info('Handling video ended event.');

    try {
      // Prioritize the external callback if provided
      if (widget.onVideoEnded != null) {
        _logger.info('Calling onVideoEnded callback.');
        widget.onVideoEnded!();
      } else {
        // Default behavior: play next video
        _logger.info(
          'No onVideoEnded callback, attempting to play next video.',
        );
        _playNextVideo();
      }
    } catch (e, stacktrace) {
      _logger.error('Error handling video ended: $e\n$stacktrace');
      // Fallback: close the player if an error occurs during handling
      if (mounted && !_disposed) {
        widget.onClose();
      }
    }
  }

  void _playPreviousVideo() {
    if (!mounted || _disposed) return;
    _logger.info('Attempting to play previous video...');

    try {
      final videoViewModel = Provider.of<VideoViewModel>(
        context,
        listen: false,
      );
      final currentList = videoViewModel.videos;
      if (currentList.isEmpty) {
        _logger.warning('Video list is empty, cannot play previous.');
        if (mounted && !_disposed) widget.onClose();
        return;
      }

      final currentIndex = currentList.indexWhere(
        (video) => video.videoId == widget.videoId,
      );

      _logger.info('Current video index: $currentIndex');

      if (currentIndex > 0) {
        final previousVideo = currentList[currentIndex - 1];
        _logger.info(
          'Found previous video: ${previousVideo.videoId} - ${previousVideo.title}',
        );
        videoViewModel.selectVideo(previousVideo);
      } else {
        _logger.info(
          'No previous video found or current video is first in list.',
        );
        // Optional: Show a toast or brief message
      }
    } catch (e, stacktrace) {
      _logger.error('Error playing previous video: $e\n$stacktrace');
    }
  }

  void _playNextVideo() {
    if (!mounted || _disposed) return;
    _logger.info('Attempting to play next video...');

    try {
      // Use try-catch for Provider access as it can throw if not found
      final videoViewModel = Provider.of<VideoViewModel>(
        context,
        listen: false,
      );
      final currentList = videoViewModel.videos; // Get the list once
      if (currentList.isEmpty) {
        _logger.warning('Video list is empty, cannot play next.');
        if (mounted && !_disposed) widget.onClose();
        return;
      }

      final currentIndex = currentList.indexWhere(
        (video) => video.videoId == widget.videoId,
      );

      _logger.info('Current video index: $currentIndex');

      if (currentIndex != -1 && currentIndex < currentList.length - 1) {
        final nextVideo = currentList[currentIndex + 1];
        _logger.info(
          'Found next video: ${nextVideo.videoId} - ${nextVideo.title}',
        );
        // Let the ViewModel handle the selection, which should trigger didUpdateWidget
        videoViewModel.selectVideo(nextVideo);
      } else {
        _logger.info(
          'No next video found or current video not in list. Closing player.',
        );
        // Ensure close is called only if mounted and not disposed
        if (mounted && !_disposed) {
          widget.onClose();
        }
      }
    } catch (e, stacktrace) {
      _logger.error('Error playing next video: $e\n$stacktrace');
      // Fallback: close the player on error
      if (mounted && !_disposed) {
        widget.onClose();
      }
    }
  }

  void _togglePlayPause() {
    if (!mounted || _disposed || !_isPlayerReady || _controller == null) {
      _logger.warning('Toggle play/pause called but conditions not met.');
      return;
    }

    try {
      if (_isPlaying) {
        _logger.info('Pausing video.');
        _controller?.pause();
      } else {
        _logger.info('Playing video.');
        _controller?.play();
      }
      // State update happens in the listener, no need to setState here for _isPlaying
      // setState(() => _isPlaying = !_isPlaying); // Remove this line
    } catch (e, stacktrace) {
      _logger.error('Error toggling play/pause: $e\n$stacktrace');
    }
    // Keep controls visible after interaction
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!mounted || _disposed) return;

    // If controls are already showing, just reset the timer
    if (!_showControls) {
      setState(() => _showControls = true);
    }

    // Cancel any existing timer
    _controlsTimer?.cancel();

    // Start a new timer
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      // Check again if mounted and if video is playing before hiding
      if (mounted && !_disposed && _isPlaying && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleDetails() {
    if (!mounted || _disposed) return;
    setState(() => _showDetails = !_showDetails);
    _showControlsTemporarily(); // Keep controls visible when toggling details
  }

  void _toggleFullScreen() {
    if (!mounted || _disposed) return;

    final enteringFullscreen = !_isFullScreen;
    _logger.info('${enteringFullscreen ? "Entering" : "Exiting"} fullscreen.');

    setState(() => _isFullScreen = enteringFullscreen);

    if (enteringFullscreen) {
      // Switch to landscape mode for full screen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      // Hide status bar and navigation in full screen mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Switch back to portrait mode when exiting full screen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // Show status bar and navigation when exiting full screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // Keep controls visible after toggling fullscreen
    _showControlsTemporarily();
  }

  // This function is specifically for the 'X' button shown only in fullscreen
  // It exits fullscreen AND closes the player.
  void _exitFullScreenAndClose() {
    _logger.info('Exit fullscreen and close requested.');
    // If already in full screen mode, exit it first programmatically
    if (_isFullScreen) {
      _logger.info('Currently in fullscreen, setting orientation to portrait.');
      // Ensure we're not disposed before setting state/chrome
      if (!mounted || _disposed) return;
      setState(() => _isFullScreen = false);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // Then call the main close callback provided to the widget
    // Ensure close is called only if mounted and not disposed
    if (mounted && !_disposed) {
      _logger.info('Calling onClose callback.');
      widget.onClose();
    }
  }

  void _handleSwipeDetection(DragStartDetails details) {
    if (!mounted || _disposed) return;
    // Only allow vertical swipe if not in fullscreen? Or always? Decide based on UX.
    // Let's allow always for now.
    _initialDragPos = details.globalPosition.dy;
    _isDragging = true;
    _logger.info('Vertical drag started at $_initialDragPos');
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (!mounted || _disposed || !_isDragging) return;

    final currentPos = details.globalPosition.dy;
    final diff = _initialDragPos - currentPos; // Positive diff means swipe UP

    _logger.info('Vertical drag update: current=$currentPos, diff=$diff');

    // Define a threshold for swipe activation
    const double swipeThreshold = 50.0;

    // If swiped up significantly
    if (diff > swipeThreshold) {
      _logger.info(
        'Swipe up detected (diff: $diff > $swipeThreshold), playing next video.',
      );
      _isDragging = false; // Prevent multiple triggers from one swipe
      _playNextVideo();
    }
    // Handle swipe down for previous video
    else if (diff < -swipeThreshold) {
      _logger.info(
        'Swipe down detected (diff: $diff < -$swipeThreshold), playing previous video.',
      );
      _isDragging = false;
      _playPreviousVideo();
    }
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (_isDragging) {
      _logger.info('Vertical drag ended.');
      _isDragging = false;
    }
  }

  @override
  void deactivate() {
    _logger.info('VideoPlayerWidget deactivate.');
    // Pause the video when the widget is deactivated (e.g., navigating away)
    // Add checks for mounted and controller existence
    if (mounted &&
        !_disposed &&
        _controller != null &&
        _controller!.value.isPlaying) {
      try {
        _logger.info('Pausing controller in deactivate.');
        _controller?.pause();
      } catch (e, stacktrace) {
        _logger.error(
          'Error pausing controller in deactivate: $e\n$stacktrace',
        );
      }
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _logger.info('Disposing VideoPlayerWidget for videoId: ${widget.videoId}');
    _disposed = true; // Mark as disposed early
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel(); // Cancel timer safely

    // Important: Reset orientation and UI mode *before* cleaning up controller
    // This prevents issues if cleanup relies on certain screen states
    try {
      _logger.info('Resetting SystemChrome settings in dispose.');
      // Only reset if it was in fullscreen, otherwise might cause flicker
      // if (_isFullScreen) { // Let's reset regardless to be safe
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // }
    } catch (e, stacktrace) {
      _logger.error('Error resetting SystemChrome in dispose: $e\n$stacktrace');
    }

    // Now clean up the controller
    _cleanupController();

    super.dispose();
    _logger.info('VideoPlayerWidget disposed.');
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // If controller is null even briefly after init, show loading.
    if (_controller == null && !_disposed) {
      // It's possible initialization fails, controller remains null.
      // Check if we are already disposed to avoid building unnecessarily.
      _logger.info('Build: Controller is null, showing loading state.');
      // Consider if an error state is more appropriate if init failed.
      return _buildLoadingState();
    }
    // If disposed, return an empty container
    if (_disposed) {
      _logger.info('Build: Widget is disposed, returning empty Container.');
      return Container(color: Colors.black); // Or SizedBox.shrink()
    }

    // Use try-catch for Provider access as it might not be ready or available
    VideoItem? videoItem;
    try {
      // Use context.watch<VideoViewModel>() if you need rebuilds on ViewModel changes
      // Use Provider.of<VideoViewModel>(context, listen: false) if only accessing methods/data once
      final videoViewModel = Provider.of<VideoViewModel>(
        context,
        listen: false,
      );
      // Use try/catch or check length before accessing firstWhere
      videoItem = videoViewModel.videos.firstWhere(
        (v) => v.videoId == widget.videoId,
        // Use orElse to provide a default or handle not found case
        orElse: () {
          _logger.warning(
            'VideoItem not found in ViewModel for ID: ${widget.videoId}',
          );
          // Return a placeholder or throw error? Placeholder is safer UI-wise.
          return VideoItem(
            id: widget.videoId, // Use widget.videoId for consistency
            videoId: widget.videoId,
            title: 'Loading...',
            description: 'Video details not found.',
            thumbnailUrl: '', // Provide sensible defaults
            channelTitle: 'Unknown Channel',
            publishedAt: DateTime.now(),
            emotionCategory: 'general', // Default emotion
          );
        },
      );
    } catch (e, stacktrace) {
      _logger.error(
        'Error accessing VideoViewModel or finding video: $e\n$stacktrace',
      );
      // If ViewModel access fails, we probably should show an error state.
      return _buildErrorState('Failed to load video data.');
    }

    // If videoItem is somehow still null (e.g., orElse returned null - bad practice)
    if (videoItem == null) {
      _logger.error('Build: videoItem is null after ViewModel access.');
      return _buildErrorState('Video data is unavailable.');
    }

    // Main UI construction
    try {
      return Scaffold(
        extendBodyBehindAppBar: true,
        // AppBar is only visible when NOT in fullscreen
        appBar: _isFullScreen ? null : _buildPortraitAppBar(videoItem),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/bg/player_bg.png',
              ), // Path to your image
              fit: BoxFit.cover, // Cover the entire container
            ),
          ),
          child: GestureDetector(
            // Tapping anywhere on the body shows/hides controls
            onTap: () {
              if (!mounted || _disposed) return;
              setState(() => _showControls = !_showControls);
              if (_showControls) {
                _showControlsTemporarily(); // Start timer if showing
              } else {
                _controlsTimer?.cancel(); // Cancel timer if hiding manually
              }
            },
            // Vertical drag for next video
            onVerticalDragStart: _handleSwipeDetection,
            onVerticalDragUpdate: _handleSwipeUpdate,
            onVerticalDragEnd: _handleSwipeEnd,
            // Use a Stack to layer player, controls, details, etc.
            child: Stack(
              fit: StackFit.expand, // Make stack children fill the space
              children: [
                // --- Video Player ---
                Center(
                  // Center the player within the available space
                  child:
                      (_controller != null && !_disposed)
                          ? YoutubePlayer(
                            controller: _controller!,
                            // Hide the default controls, progress indicator handled by custom overlay
                            showVideoProgressIndicator:
                                false, // Use custom progress bar
                            aspectRatio: 16 / 9, // Or adjust as needed
                            // progressIndicatorColor: _getEmotionColor(videoItem.emotionCategory), // Moved to custom bar
                            onReady: () {
                              _logger.info(
                                'YoutubePlayer onReady callback triggered.',
                              );
                              // The listener handles _isPlayerReady state, but good for logging
                              if (mounted && !_disposed) {
                                // Ensure player is ready state is accurate if listener missed it
                                if (!_isPlayerReady) {
                                  setState(() => _isPlayerReady = true);
                                }
                                // Show controls when ready if autoplaying
                                if (_isPlaying) _showControlsTemporarily();
                              }
                            },
                            // Add error builder for youtube_player_flutter errors
                            onEnded: (metadata) {
                              _logger.info(
                                'YoutubePlayer onEnded callback triggered.',
                              );
                              // Handled by listener, but good for logging. Redundant.
                              // _handleVideoEnded();
                            },

                            // Consider adding buffer indicator handling?
                            // bottomActions: [], // Ensure default bottom actions are hidden if needed
                          )
                          : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ), // Show loading if controller disposed unexpectedly
                ),

                // --- Swipe Indicator (subtle hint) ---
                // Only show when controls are visible? Or always subtly?
                // Let's show when controls are shown.
                if (_showControls) _buildSwipeUpIndicator(),

                // --- Loading Indicator (while player initializing) ---
                // Show if the controller exists but isn't ready yet
                if (_controller != null && !_isPlayerReady)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // --- Video Details Overlay (conditionally shown) ---
                // Use AnimatedOpacity for smooth fade in/out
                AnimatedOpacity(
                  opacity: _showDetails ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  // Ignore pointer events when hidden
                  child: IgnorePointer(
                    ignoring: !_showDetails,
                    child: _buildVideoDetailsOverlay(videoItem),
                  ),
                ),

                // --- Controls Overlay (conditionally shown) ---
                // Use AnimatedOpacity for smooth fade in/out
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  // Ignore pointer events when hidden
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    // Pass necessary data to the controls builder
                    child: _buildControlsOverlay(videoItem, _controller?.value),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stacktrace) {
      // Catch errors during the build process itself
      _logger.error('Error building main UI: $e\n$stacktrace');
      // Show a generic error state if the build fails
      return _buildErrorState('An unexpected error occurred.');
    }
  }

  // --- Helper Build Methods ---

  AppBar _buildPortraitAppBar(VideoItem videoItem) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close,
          color: Colors.black,
        ), // Use close icon for closing player
        onPressed: widget.onClose, // Close the player entirely
        tooltip: 'Close Player',
      ),
      title: Text(
        videoItem.title,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Button to toggle video details
        IconButton(
          icon: Icon(
            _showDetails
                ? Icons.info
                : Icons.info_outline, // Change icon based on state
            color: Colors.black,
          ),
          onPressed: _toggleDetails,
          tooltip: _showDetails ? 'Hide Details' : 'Show Details',
        ),
        // Button to enter fullscreen (only shown in portrait AppBar)
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.black),
          onPressed: _toggleFullScreen,
          tooltip: 'Enter Fullscreen',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    _logger.info('Building Loading State UI');
    // Consistent loading state, handles fullscreen exit if needed
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Show a simplified AppBar even in loading state if not fullscreen
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose, // Allow closing even when loading
                  tooltip: 'Close Player', // Added tooltip
                ),
                title: const Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg/player_bg.png'), // Path to your image
            fit: BoxFit.cover, // Cover the entire container
          ),
        ),
        child: Stack(
          children: [
            const Center(child: CircularProgressIndicator(color: Colors.white)),
            // Provide an exit button if stuck in fullscreen loading
            if (_isFullScreen)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: IconButton(
                    // Use the combined exit function
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _exitFullScreenAndClose,
                    tooltip: 'Close Player',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    _logger.info('Building Error State UI: $errorMessage');
    // Consistent error state, handles fullscreen exit
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Show a simplified AppBar even in error state if not fullscreen
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose, // Allow closing from error state
                  tooltip: 'Close Player', // Added tooltip
                ),
                title: const Text(
                  'Error',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg/player_bg.png'), // Path to your image
            fit: BoxFit.cover, // Cover the entire container
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage, // Display specific error message
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                    ),
                    // *** REMOVED tooltip from ElevatedButton.icon ***
                    // tooltip: 'Close Player',
                  ),
                ],
              ),
            ),
            // Provide an exit button if stuck in fullscreen error
            if (_isFullScreen)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed:
                        _exitFullScreenAndClose, // Use the combined exit function
                    tooltip: 'Close Player',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeUpIndicator() {
    return Positioned(
      bottom: _isFullScreen ? 60 : 100, // Increased from 40/80 to 60/100
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 20,
          ), // Additional bottom padding
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Swipe down indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ), // Slightly increased vertical padding
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swipe_down, color: Colors.white70, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Previous',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Right side - Swipe up indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ), // Slightly increased vertical padding
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Next',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.swipe_up, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetailsOverlay(VideoItem videoItem) {
    return Container(
      // Semi-transparent background covering the whole area
      color: Colors.black.withAlpha(175),
      child: SafeArea(
        // Respect safe areas within the overlay
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Row: Title, Channel, Close Button ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min, // Prevent excessive height
                      children: [
                        Text(
                          videoItem.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 3, // Limit title lines
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          videoItem.channelTitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Display publish date nicely
                        Text(
                          'Published: ${_formatDate(videoItem.publishedAt)}', // Helper function needed
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button for the details overlay specifically
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _toggleDetails, // Action to hide details
                    tooltip: 'Hide Details',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[700]),
              const SizedBox(height: 12),

              // --- Description ---
              Expanded(
                // Allow description to take remaining space
                child: SingleChildScrollView(
                  // Make description scrollable
                  child: Text(
                    videoItem.description.isNotEmpty
                        ? videoItem.description
                        : 'No description available.', // Placeholder
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Emotion Category Tag ---
              Align(
                // Align tag to the start or end as preferred
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getEmotionColor(
                      videoItem.emotionCategory,
                    ).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    videoItem.emotionCategory.isNotEmpty
                        ? videoItem.emotionCategory.toUpperCase()
                        : 'GENERAL', // Default tag text
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    // Use intl package for better formatting if available
    // Basic fallback:
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // *** Controls Overlay using Stack (No change needed here based on errors) ***
  Widget _buildControlsOverlay(
    VideoItem videoItem,
    YoutubePlayerValue? playerValue,
  ) {
    // Use playerValue passed from the builder if available
    final currentPosition = playerValue?.position ?? Duration.zero;
    final totalDuration = playerValue?.metaData.duration ?? Duration.zero;
    final volume = playerValue?.volume ?? 100.0; // Default volume
    // *** MODIFIED: Use volume to determine mute state ***
    final bool effectivelyMuted = volume <= 0;

    return Container(
      // Background scrim, less opaque than details overlay
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        // Use Stack for positioning elements
        children: [
          // --- Top Controls (only in fullscreen) ---
          if (_isFullScreen)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                // Apply safe area to top controls
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button (exits fullscreen AND closes player)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _exitFullScreenAndClose,
                        tooltip: 'Close Player',
                      ),
                      // Title (truncated)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            videoItem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 2.0, color: Colors.black54),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center, // Center title text
                          ),
                        ),
                      ),

                      // Top-right actions (like details toggle)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showDetails ? Icons.info : Icons.info_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _toggleDetails,
                            tooltip:
                                _showDetails ? 'Hide Details' : 'Show Details',
                          ),
                          // No fullscreen toggle needed here, as exit is handled by close/toggle below
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Center Controls (Play/Pause, Seek) ---
          // Positioned in the exact center of the Stack
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind Button
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 45,
                  ),
                  padding: const EdgeInsets.all(12), // Increase tappable area
                  onPressed:
                      _isPlayerReady
                          ? () {
                            final newPosition =
                                currentPosition - const Duration(seconds: 10);
                            _controller?.seekTo(
                              newPosition < Duration.zero
                                  ? Duration.zero
                                  : newPosition,
                            );
                            _showControlsTemporarily(); // Keep controls visible
                          }
                          : null,
                  tooltip: 'Rewind 10 seconds',
                ),
                const SizedBox(width: 24), // Spacing
                // Play/Pause Button
                IconButton(
                  // Larger central button
                  iconSize: 70.0,
                  padding:
                      EdgeInsets
                          .zero, // Remove default padding for precise sizing
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: _isPlayerReady ? _togglePlayPause : null,
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                ),
                const SizedBox(width: 24), // Spacing
                // Forward Button
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 45,
                  ),
                  padding: const EdgeInsets.all(12), // Increase tappable area
                  onPressed:
                      _isPlayerReady
                          ? () {
                            final newPosition =
                                currentPosition + const Duration(seconds: 10);
                            // Ensure seeking doesn't go beyond duration if known
                            if (totalDuration > Duration.zero &&
                                newPosition > totalDuration) {
                              _controller?.seekTo(totalDuration);
                            } else {
                              _controller?.seekTo(newPosition);
                            }
                            _showControlsTemporarily(); // Keep controls visible
                          }
                          : null,
                  tooltip: 'Forward 10 seconds',
                ),
              ],
            ),
          ),

          // --- Bottom Controls (Progress, Fullscreen, Next) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              // Apply safe area to bottom controls
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Take minimum vertical space
                  children: [
                    // --- Progress Bar ---
                    if (playerValue !=
                        null) // Only show if playerValue is available
                      _buildVideoProgressBar(
                        playerValue,
                        videoItem.emotionCategory,
                      ),

                    const SizedBox(
                      height: 4,
                    ), // Space between progress bar and buttons
                    // --- Bottom Row Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Volume Control
                        // Fullscreen / Exit Fullscreen Button
                        IconButton(
                          icon: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFullScreen, // Always calls toggle
                          tooltip:
                              _isFullScreen
                                  ? 'Exit Fullscreen'
                                  : 'Enter Fullscreen',
                        ),

                        // Right side: Fullscreen Toggle & Next Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Previous Button
                            _buildPreviousVideoButton(),

                            // Right side: Next Button
                            _buildNextVideoButton(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousVideoButton() {
    return Consumer<VideoViewModel>(
      builder: (context, videoViewModel, child) {
        final currentList = videoViewModel.videos;
        final currentIndex = currentList.indexWhere(
          (video) => video.videoId == widget.videoId,
        );
        // Determine if there is a previous video
        final bool hasPreviousVideo = currentIndex > 0;

        return TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: hasPreviousVideo ? Colors.white : Colors.grey[600],
          ),
          icon: Icon(Icons.skip_previous, size: 24),
          label: const Text("Previous", style: TextStyle(fontSize: 14)),
          onPressed:
              (_isPlayerReady && hasPreviousVideo)
                  ? () {
                    _playPreviousVideo();
                    _showControlsTemporarily();
                  }
                  : null,
        );
      },
    );
  }

  // Extracted Next Video Button Builder
  Widget _buildNextVideoButton() {
    // Use a Builder to get context for Provider if needed, or access ViewModel directly
    // No Provider needed here if list access is stable
    return Consumer<VideoViewModel>(
      // Use Consumer for reactivity if needed
      builder: (context, videoViewModel, child) {
        final currentList = videoViewModel.videos;
        final currentIndex = currentList.indexWhere(
          (video) => video.videoId == widget.videoId,
        );
        // Determine if there is a next video
        final bool hasNextVideo =
            currentIndex != -1 && currentIndex < currentList.length - 1;

        return TextButton.icon(
          // Style differently based on whether next video exists
          style: TextButton.styleFrom(
            foregroundColor: hasNextVideo ? Colors.white : Colors.grey[600],
          ),
          icon: Icon(
            Icons.skip_next,
            size: 24, // Slightly larger icon
          ),
          label: const Text("Next", style: TextStyle(fontSize: 14)),
          // Disable onPressed if no next video or player not ready
          onPressed:
              (_isPlayerReady && hasNextVideo)
                  ? () {
                    _playNextVideo();
                    _showControlsTemporarily(); // Show controls on interaction
                  }
                  : null, // null disables the button
        );
      },
    );
  }

  Widget _buildVideoProgressBar(
    YoutubePlayerValue value,
    String emotionCategory,
  ) {
    final currentPosition = value.position;
    final totalDuration = value.metaData.duration;

    // Handle potential zero duration
    final maxDurationValue =
        (totalDuration.inMilliseconds > 0)
            ? totalDuration.inMilliseconds.toDouble()
            : 1.0; // Avoid division by zero, use 1 as placeholder max
    final currentPositionValue = currentPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, maxDurationValue); // Ensure value stays within bounds

    final bufferedPosition = value.buffered * totalDuration.inMilliseconds;
    final bufferedValue = bufferedPosition.clamp(0.0, maxDurationValue);

    // Helper to format duration strings
    String formatDuration(Duration duration) {
      if (duration == Duration.zero) {
        return '0:00'; // Handle zero duration display
      }
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      if (hours > 0) {
        return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
      } else {
        return '$minutes:${twoDigits(seconds)}';
      }
    }

    final emotionColor = _getEmotionColor(emotionCategory); // Get color once

    return Row(
      children: [
        // Current Time
        Text(
          formatDuration(currentPosition),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 8), // Spacing
        // --- Custom Slider with Buffering ---
        Expanded(
          child: SliderTheme(
            // Define overall slider appearance
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0, // Slimmer track
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 7.0,
              ), // Slightly larger thumb
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 14.0,
              ), // Larger overlay for easier grab
              activeTrackColor:
                  emotionColor, // Use emotion color for played part
              inactiveTrackColor: Colors.grey.withValues(
                alpha: 0.4,
              ), // Color for the unloaded part
              thumbColor: emotionColor, // Thumb matches active color
              overlayColor: emotionColor.withAlpha(
                80,
              ), // Overlay matches active color
              // Define a secondary active track color for buffering
              secondaryActiveTrackColor: Colors.white.withValues(
                alpha: 0.6,
              ), // Color for buffered part
            ),
            child: Slider(
              value: currentPositionValue,
              min: 0.0,
              max: maxDurationValue,
              // Add the buffered value
              secondaryTrackValue: bufferedValue,
              // Enable only when player is ready and duration is valid
              onChanged:
                  (_isPlayerReady && totalDuration > Duration.zero)
                      ? (newValue) {
                        _controller?.seekTo(
                          Duration(milliseconds: newValue.round()),
                        );
                        // Keep controls visible while scrubbing, but don't restart timer yet
                        _controlsTimer?.cancel();
                      }
                      : null, // Disable if not ready or duration unknown
              // When user stops scrubbing, restart the hide timer
              onChangeEnd: (newValue) {
                if (_isPlayerReady && totalDuration > Duration.zero) {
                  _showControlsTemporarily();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8), // Spacing
        // Total Time
        Text(
          formatDuration(totalDuration),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  // --- Utility Methods ---

  Color _getEmotionColor(String emotion) {
    const colorMap = {
      'happy': Colors.yellow,
      'bored': Colors.grey,
      'love': Colors.pink,
      'surprised': Colors.orange,
      'angry': Colors.red,
      'sad': Colors.blue,
      'hopeless': Colors.grey,
      'jealous': Colors.green,
      'anxious': Colors.purple,
      'overwhelmed': Colors.deepOrange,
      'confused': Colors.brown,
    };
    return colorMap[emotion.toLowerCase()]?.shade400 ?? Colors.blueGrey;
  }
}
