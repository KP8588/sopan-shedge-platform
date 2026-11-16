
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/api_service.dart';

class RecordedLecturePlayerScreen extends StatefulWidget {
  final Map<String, dynamic> lecture;

  const RecordedLecturePlayerScreen({
    super.key,
    required this.lecture,
  });

  @override
  State<RecordedLecturePlayerScreen> createState() =>
      _RecordedLecturePlayerScreenState();
}

class _RecordedLecturePlayerScreenState
    extends State<RecordedLecturePlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  int _lastSavedPosition = -1;
  Timer? _saveTimer;

  int get _lectureId =>
      int.tryParse(widget.lecture['id'].toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final lecture = widget.lecture;

      final fileUrl = lecture['video_file_url']?.toString() ?? '';
      final externalUrl = lecture['video_url']?.toString() ?? '';
      final videoUrl = fileUrl.isNotEmpty ? fileUrl : externalUrl;

      if (videoUrl.isEmpty || _lectureId <= 0) {
        throw Exception('Video URL or lecture ID is missing.');
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      _controller = controller;

      await controller.initialize();

      final progress = await ApiService.getLectureProgress();

      final saved = progress.where(
        (item) =>
            item['lecture'].toString() == _lectureId.toString(),
      );

      if (saved.isNotEmpty) {
        final seconds = int.tryParse(
              saved.first['position_seconds'].toString(),
            ) ??
            0;

        if (seconds > 0 && !((saved.first['completed']) == true)) {
          final duration = controller.value.duration.inSeconds;
          await controller.seekTo(
            Duration(seconds: seconds.clamp(0, duration)),
          );
        }
      }

      controller.addListener(_onVideoChanged);

      _saveTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _saveProgress(),
      );

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onVideoChanged() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;

    if (value.isInitialized &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _saveProgress(completed: true);
    }

    setState(() {});
  }

  Future<void> _saveProgress({bool completed = false}) async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final position = controller.value.position.inSeconds;

    if (!completed && position == _lastSavedPosition) return;

    _lastSavedPosition = position;

    try {
      await ApiService.saveLectureProgress(
        lectureId: _lectureId,
        positionSeconds: position,
        completed: completed,
      );
    } catch (e) {
      debugPrint('Lecture progress save failed: $e');
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveProgress();
    _controller?.removeListener(_onVideoChanged);
    _controller?.dispose();
    super.dispose();
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.lecture['title']?.toString() ?? 'Recorded Lecture',
        ),
        backgroundColor: const Color(0xFF142D5E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : controller == null
                  ? const Center(child: Text('Player unavailable'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio:
                                controller.value.aspectRatio > 0
                                    ? controller.value.aspectRatio
                                    : 16 / 9,
                            child: VideoPlayer(controller),
                          ),
                        ),
                        const SizedBox(height: 16),
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF214A91),
                            bufferedColor: Colors.black26,
                            backgroundColor: Colors.black12,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_format(controller.value.position)),
                            Text(_format(controller.value.duration)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 36,
                              onPressed: () {
                                final target =
                                    controller.value.position -
                                        const Duration(seconds: 10);
                                controller.seekTo(
                                  target < Duration.zero
                                      ? Duration.zero
                                      : target,
                                );
                              },
                              icon: const Icon(Icons.replay_10),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              iconSize: 54,
                              onPressed: () {
                                if (controller.value.isPlaying) {
                                  controller.pause();
                                  _saveProgress();
                                } else {
                                  controller.play();
                                }
                              },
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: const Color(0xFF214A91),
                              ),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              iconSize: 36,
                              onPressed: () {
                                final target =
                                    controller.value.position +
                                        const Duration(seconds: 10);
                                final duration =
                                    controller.value.duration;
                                controller.seekTo(
                                  target > duration ? duration : target,
                                );
                              },
                              icon: const Icon(Icons.forward_10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.lecture['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.lecture['description']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
    );
  }
}
