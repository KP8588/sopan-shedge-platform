
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'recorded_lecture_player_screen.dart';

class RecordedLecturesScreen extends StatefulWidget {
  final int? courseId;
  final String courseName;

  const RecordedLecturesScreen({
    super.key,
    this.courseId,
    this.courseName = 'Recorded Lessons',
  });

  @override
  State<RecordedLecturesScreen> createState() =>
      _RecordedLecturesScreenState();
}

class _RecordedLecturesScreenState
    extends State<RecordedLecturesScreen> {
  late Future<List<Map<String, dynamic>>> _lecturesFuture;

  @override
  void initState() {
    super.initState();
    _lecturesFuture = ApiService.getRecordedLectures(
      courseId: widget.courseId,
    );
  }

  String _duration(dynamic value) {
    final seconds = int.tryParse(value.toString()) ?? 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m ${remaining}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: const Color(0xFF142D5E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lecturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _lecturesFuture =
                              ApiService.getRecordedLectures(
                            courseId: widget.courseId,
                          );
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final lectures = snapshot.data ?? [];

          if (lectures.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_library_outlined, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'No recorded lectures available yet.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFF214A91),
                      size: 34,
                    ),
                  ),
                  title: Text(
                    lecture['title']?.toString() ?? 'Untitled lecture',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture['description']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _duration(lecture['duration_seconds'] ?? 0),
                          style: const TextStyle(
                            color: Color(0xFF214A91),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordedLecturePlayerScreen(
                          lecture: lecture,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
