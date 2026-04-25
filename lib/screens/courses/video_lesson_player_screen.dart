import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/app_theme.dart';

class VideoLessonPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;

  const VideoLessonPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  @override
  State<VideoLessonPlayerScreen> createState() =>
      _VideoLessonPlayerScreenState();
}

class _VideoLessonPlayerScreenState extends State<VideoLessonPlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final uri = Uri.tryParse(widget.videoUrl);
      if (uri == null) {
        setState(() {
          _error = 'Invalid video URL';
          _loading = false;
        });
        return;
      }

      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      await controller.setLooping(false);
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load video';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                  )
                : _controller == null
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                          const SizedBox(height: 18),
                          ValueListenableBuilder(
                            valueListenable: _controller!,
                            builder: (context, VideoPlayerValue value, _) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    VideoProgressIndicator(
                                      _controller!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: AppTheme.primary500,
                                        bufferedColor: Colors.white24,
                                        backgroundColor: Colors.white10,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            final pos = value.position -
                                                const Duration(seconds: 10);
                                            await _controller!.seekTo(
                                              pos < Duration.zero
                                                  ? Duration.zero
                                                  : pos,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.replay_10,
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            if (value.isPlaying) {
                                              await _controller!.pause();
                                            } else {
                                              await _controller!.play();
                                            }
                                            setState(() {});
                                          },
                                          icon: Icon(
                                            value.isPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 42,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await _controller!.seekTo(
                                              value.position +
                                                  const Duration(seconds: 10),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.forward_10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
      ),
    );
  }
}
