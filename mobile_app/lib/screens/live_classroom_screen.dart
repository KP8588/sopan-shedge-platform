import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveClassroomScreen extends StatefulWidget {
  const LiveClassroomScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.roomName,
    required this.isTrainer,
  });

  final String serverUrl;
  final String token;
  final String roomName;
  final bool isTrainer;

  @override
  State<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends State<LiveClassroomScreen> {
  late final Room _room;

  bool _connecting = true;
  bool _connected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    _room.addListener(_onRoomChanged);
    _connect();
  }

  Future<void> _connect() async {
    try {
      if (widget.serverUrl.isEmpty ||
          widget.token.isEmpty ||
          widget.roomName.isEmpty) {
        throw Exception('Missing classroom connection details.');
      }

      await _room.connect(widget.serverUrl, widget.token);

      if (widget.isTrainer) {
        await _room.localParticipant?.setCameraEnabled(true);
        await _room.localParticipant?.setMicrophoneEnabled(true);
      }

      if (!mounted) return;

      setState(() {
        _connected = true;
        _connecting = false;
        _micEnabled = widget.isTrainer;
        _cameraEnabled = widget.isTrainer;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _connecting = false;
        _connected = false;
        _error = e.toString();
      });
    }
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic() async {
    try {
      final enabled = !_micEnabled;
      await _room.localParticipant?.setMicrophoneEnabled(enabled);

      if (mounted) {
        setState(() => _micEnabled = enabled);
      }
    } catch (e) {
      _showMessage('Could not change microphone: $e');
    }
  }

  Future<void> _toggleCamera() async {
    try {
      final enabled = !_cameraEnabled;
      await _room.localParticipant?.setCameraEnabled(enabled);

      if (mounted) {
        setState(() => _cameraEnabled = enabled);
      }
    } catch (e) {
      _showMessage('Could not change camera: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _leaveClass() async {
    await _room.disconnect();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _room.removeListener(_onRoomChanged);
    _room.disconnect();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantCount =
        _room.remoteParticipants.length + (_connected ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101E3D),
        foregroundColor: Colors.white,
        title: const Text('Sopan Learning'),
        actions: [
          IconButton(
            tooltip: 'Leave classroom',
            onPressed: _leaveClass,
            icon: const Icon(Icons.call_end),
          ),
        ],
      ),
      body: SafeArea(
        child: _connecting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting to your classroom...'),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off,
                        size: 56,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not join the classroom',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _connecting = true;
                          });
                          _connect();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101E3D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connected · $participantCount participant(s)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isTrainer
                              ? 'Trainer mode'
                              : 'Student mode · Listen to the lesson',
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cast_for_education,
                              size: 88,
                              color: Color(0xFFE7B83F),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'You are in the classroom',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isTrainer
                                  ? 'Your camera and microphone controls are below.'
                                  : 'You can listen to the trainer when they publish audio.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Remote participants: ${_room.remoteParticipants.length}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    color: const Color(0xFF101E3D),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: _micEnabled ? Icons.mic : Icons.mic_off,
                          label: _micEnabled ? 'Mute' : 'Unmute',
                          onPressed: widget.isTrainer ? _toggleMic : null,
                        ),
                        _ControlButton(
                          icon: _cameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: _cameraEnabled ? 'Camera off' : 'Camera on',
                          onPressed: widget.isTrainer ? _toggleCamera : null,
                        ),
                        _ControlButton(
                          icon: Icons.call_end,
                          label: 'Leave',
                          color: Colors.redAccent,
                          onPressed: _leaveClass,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
