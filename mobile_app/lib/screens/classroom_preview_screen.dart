import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../services/api_service.dart';

const _bg = Color(0xFF0B1428);
const _navy = Color(0xFF101D3A);
const _panel = Color(0xFF172440);
const _gold = Color(0xFFE3B341);
const _muted = Color(0xFF9AA8C2);
const _green = Color(0xFF53D6A0);
const _red = Color(0xFFCE454D);

class ClassroomPreviewScreen extends StatefulWidget {
  const ClassroomPreviewScreen({super.key, required this.classroom});

  final Map<String, dynamic> classroom;

  @override
  State<ClassroomPreviewScreen> createState() => _ClassroomPreviewScreenState();
}

class _ClassroomPreviewScreenState extends State<ClassroomPreviewScreen>
    with WidgetsBindingObserver {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _connecting = false;
  bool _connected = false;
  bool _trainer = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _showPeople = false;
  bool _leaving = false;
  bool _showAllParticipants = false;

  String? _error;
  String _status = 'Ready to join';
  String? _activeSpeakerIdentity;

  // Optional local UI state. Actual system PiP requires native Android setup.
  bool _appBackgrounded = false;

  String get _classId => widget.classroom['id']?.toString() ?? '';

  String get _title =>
      widget.classroom['title']?.toString() ?? 'Sopan Live Classroom';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    setState(() {
      _appBackgrounded =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached;
    });
  }

  Future<void> _join() async {
    if (_connecting || _connected || _leaving) return;

    final id = int.tryParse(_classId);
    final auth = ApiService.authToken;

    if (id == null || id <= 0) {
      setState(() => _error = 'This classroom has an invalid ID.');
      return;
    }

    if (auth == null || auth.isEmpty) {
      setState(() {
        _error = 'Your session expired. Sign in again and retry.';
      });
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
      _status = 'Requesting secure accessâ€¦';
    });

    Room? newRoom;

    try {
      final base = ApiService.baseUrl.replaceFirst(RegExp(r'/+$'), '');

      final response = await http
          .post(
            Uri.parse('$base/api/classrooms/$id/livekit-token/'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Token $auth',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Classroom access failed (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid server response.');
      }

      final serverUrl = decoded['serverUrl']?.toString().trim() ?? '';
      final token = decoded['token']?.toString().trim() ?? '';
      final isTrainer = decoded['isTrainer'] == true;

      if (serverUrl.isEmpty || token.isEmpty) {
        throw Exception('Missing classroom credentials in response.');
      }

      if (!mounted) return;

      setState(() {
        _status = 'Connecting to live classroomâ€¦';
      });

      newRoom = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      _room = newRoom;
      _trainer = isTrainer;

      newRoom.addListener(_onRoomChanged);

      final listener = newRoom.createListener();
      _listener = listener;

      listener.on<RoomDisconnectedEvent>((event) {
        if (!mounted || _leaving) return;

        setState(() {
          _connected = false;
          _status = 'Disconnected. Tap Retry to reconnect.';
        });
      });

      listener.on<ParticipantConnectedEvent>((event) {
        if (mounted) setState(() {});
      });

      listener.on<ParticipantDisconnectedEvent>((event) {
        if (mounted) setState(() {});
      });

      await newRoom.connect(serverUrl, token);

      if (!mounted) {
        await _disposeRoom();
        return;
      }

      // Both trainers and students may publish if the server token grants
      // canPublish. The server must enforce the intended permissions.
      await newRoom.localParticipant?.setCameraEnabled(true);
      await newRoom.localParticipant?.setMicrophoneEnabled(true);

      if (!mounted) {
        await _disposeRoom();
        return;
      }

      setState(() {
        _connecting = false;
        _connected = true;
        _micOn = true;
        _cameraOn = true;
        _status = _trainer
            ? 'Connected as trainer'
            : 'Connected to live classroom';
      });
    } catch (e) {
      await _disposeRoom();

      if (!mounted) return;

      setState(() {
        _connecting = false;
        _connected = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _status = 'Connection problem';
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted) return;

    final room = _room;
    if (room == null) return;

    final speakers = room.activeSpeakers
        .where((participant) => !identical(participant, room.localParticipant))
        .toList();

    setState(() {
      _activeSpeakerIdentity = speakers.isEmpty
          ? null
          : speakers.first.identity;
    });
  }

  List<Participant> get _remote =>
      _room?.remoteParticipants.values.toList(growable: false) ??
      <Participant>[];

  List<Participant> get _allParticipants => <Participant>[
    if (_room?.localParticipant != null) _room!.localParticipant!,
    ..._remote,
  ];

  VideoTrack? _videoOf(Participant? participant) {
    if (participant == null) return null;

    for (final publication in participant.trackPublications.values) {
      final track = publication.track;
      if (track is VideoTrack) return track;
    }

    return null;
  }

  Participant? get _trainerParticipant {
    final room = _room;
    if (room == null) return null;

    // Prefer an explicit trainer identity if your backend/token system uses
    // a documented identity convention. Do not assume arbitrary identities
    // represent trainers.
    final local = room.localParticipant;

    if (_trainer && local != null) {
      return local;
    }

    // Participant attributes/metadata can be used for trainer identification
    // once your server publishes a stable, verified role field.
    return null;
  }

  Participant? get _mainParticipant {
    final trainer = _trainerParticipant;
    if (trainer != null && _videoOf(trainer) != null) {
      return trainer;
    }

    final activeIdentity = _activeSpeakerIdentity;

    if (activeIdentity != null) {
      for (final participant in _allParticipants) {
        if (participant.identity == activeIdentity &&
            _videoOf(participant) != null) {
          return participant;
        }
      }
    }

    // If a student has joined, show the first available remote video rather
    // than always enlarging the student's own camera.
    for (final participant in _remote) {
      if (_videoOf(participant) != null) return participant;
    }

    return _room?.localParticipant;
  }

  VideoTrack? get _mainVideo => _videoOf(_mainParticipant);

  String get _mainParticipantLabel {
    final participant = _mainParticipant;

    if (participant == null) return 'Waiting for video';

    if (identical(participant, _room?.localParticipant)) {
      return _trainer ? 'You Â· Trainer' : 'You Â· Student';
    }

    return participant.identity.isEmpty
        ? 'Class participant'
        : participant.identity;
  }

  Future<void> _toggleMic() async {
    final local = _room?.localParticipant;
    if (local == null || !_connected || _leaving) return;

    final next = !_micOn;

    try {
      await local.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micOn = next);
    } catch (_) {
      _snack('Could not change microphone. Check device permissions.');
    }
  }

  Future<void> _toggleCamera() async {
    final local = _room?.localParticipant;
    if (local == null || !_connected || _leaving) return;

    final next = !_cameraOn;

    try {
      await local.setCameraEnabled(next);
      if (mounted) setState(() => _cameraOn = next);
    } catch (_) {
      _snack('Could not change camera. Check device permissions.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _disposeRoom() async {
    _listener?.dispose();
    _listener = null;

    final room = _room;
    _room = null;

    if (room == null) return;

    room.removeListener(_onRoomChanged);

    try {
      await room.disconnect();
    } catch (_) {}

    try {
      await room.dispose();
    } catch (_) {}
  }

  Future<void> _leave() async {
    if (_leaving) return;

    setState(() {
      _leaving = true;
      _status = 'Leaving classroomâ€¦';
    });

    await _disposeRoom();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmLeave() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave classroom?'),
        content: const Text('You will disconnect from the live lesson.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (yes == true && mounted) {
      await _leave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _listener?.dispose();
    _listener = null;

    final room = _room;
    _room = null;

    if (room != null) {
      room.removeListener(_onRoomChanged);
      unawaited(room.disconnect());
      unawaited(room.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Class ID: $_classId',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (_connected)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(
                child: Chip(
                  avatar: Icon(Icons.circle, size: 8, color: _green),
                  label: Text('LIVE'),
                  backgroundColor: Color(0xFF173D36),
                  labelStyle: TextStyle(color: Color(0xFFB7F4D8)),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Participants',
            onPressed: _connected
                ? () => setState(() => _showPeople = !_showPeople)
                : null,
            icon: const Icon(Icons.people_alt_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: !_connected
            ? _joinScreen()
            : Column(
                children: [
                  Expanded(child: wide ? _desktopMeeting() : _mobileMeeting()),
                  _controlBar(),
                ],
              ),
      ),
    );
  }

  Widget _joinScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2A3A5C)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_rounded, color: _gold, size: 56),
                    const SizedBox(height: 14),
                    Text(
                      _trainer ? 'Trainer classroom' : 'Ready to join class?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your connection before entering.',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _joinDeviceBadge(Icons.mic_none_rounded, 'Microphone'),
                  const SizedBox(width: 12),
                  _joinDeviceBadge(Icons.videocam_outlined, 'Camera'),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFA1A1)),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _connecting ? null : _join,
                  icon: _connecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.video_call_rounded),
                  label: Text(
                    _connecting
                        ? _status
                        : (_error == null ? 'Join class' : 'Retry connection'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Camera and microphone access depends on '
                'your device permissions and classroom access.',
                style: const TextStyle(color: _muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _joinDeviceBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3A5C)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _mobileMeeting() {
    final main = _mainParticipant;
    final others = _allParticipants
        .where((participant) => !identical(participant, main))
        .toList();

    return Column(
      children: [
        _meetingStatusBar(),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: _videoTile(
                        _mainVideo,
                        _mainParticipantLabel,
                        large: true,
                        activeSpeaker: _activeSpeakerIdentity == main?.identity,
                        cameraOn: main == _room?.localParticipant
                            ? _cameraOn
                            : null,
                      ),
                    ),
                  ),
                  if (others.isNotEmpty)
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: others.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final participant = others[index];

                          return SizedBox(
                            width: 165,
                            child: _participantTile(participant),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              if (_showPeople) Positioned.fill(child: _peoplePanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desktopMeeting() {
    final main = _mainParticipant;
    final others = _allParticipants
        .where((participant) => !identical(participant, main))
        .toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _videoTile(
                        _mainVideo,
                        _mainParticipantLabel,
                        large: true,
                        activeSpeaker: _activeSpeakerIdentity == main?.identity,
                        cameraOn: main == _room?.localParticipant
                            ? _cameraOn
                            : null,
                      ),
                    ),
                    if (others.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 205,
                        child: ListView.separated(
                          itemCount: others.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => SizedBox(
                            height: 135,
                            child: _participantTile(others[index]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _meetingStatusBar(),
            ],
          ),
        ),
        if (_showPeople)
          Positioned(
            right: 18,
            top: 18,
            bottom: 18,
            width: 280,
            child: _peoplePanel(),
          ),
      ],
    );
  }

  Widget _meetingStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: _green, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _status,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Text(
            '${_remote.length + 1} people',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _participantTile(Participant participant, {bool large = false}) {
    final isLocal = identical(participant, _room?.localParticipant);

    final active = _activeSpeakerIdentity == participant.identity;

    return _videoTile(
      _videoOf(participant),
      _participantLabel(participant),
      large: large,
      small: !large,
      activeSpeaker: active,
      micOn: isLocal ? _micOn : null,
      cameraOn: isLocal ? _cameraOn : null,
    );
  }

  String _participantLabel(Participant participant) {
    final isLocal = identical(participant, _room?.localParticipant);

    if (isLocal) {
      return _trainer ? 'You Â· Trainer' : 'You Â· Student';
    }

    return participant.identity.isEmpty ? 'Participant' : participant.identity;
  }

  Widget _videoTile(
    VideoTrack? track,
    String name, {
    bool large = false,
    bool small = false,
    bool activeSpeaker = false,
    bool? micOn,
    bool? cameraOn,
  }) {
    final radius = large ? 22.0 : 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(
            color: activeSpeaker ? _green : const Color(0xFF2A3A5C),
            width: activeSpeaker ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (track != null && cameraOn != false)
              VideoTrackRenderer(track, fit: VideoViewFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2B50), Color(0xFF101A30)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: small ? 24 : 42,
                        backgroundColor: const Color(0xFF2A3D62),
                        child: Icon(
                          Icons.person_rounded,
                          color: _gold,
                          size: small ? 25 : 42,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cameraOn == false
                            ? 'Camera off'
                            : 'Waiting for videoâ€¦',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (activeSpeaker)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173D36),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.graphic_eq, color: _green, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Speaking',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: _green, size: 7),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (micOn != null)
                      Icon(
                        micOn ? Icons.mic : Icons.mic_off,
                        color: Colors.white70,
                        size: 15,
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

  Widget _peoplePanel() {
    return Container(
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF344568)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Participants',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showPeople = false),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF344568), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _person(_trainer ? 'You (Trainer)' : 'You (Student)', true),
                for (final participant in _remote)
                  _person(participant.identity, false),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Camera and microphone depend on device permissions '
              'and classroom access.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _person(String name, bool local) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: const Color(0xFF2A3D62),
        child: Icon(
          local ? Icons.person : Icons.school_outlined,
          color: _gold,
          size: 18,
        ),
      ),
      title: Text(
        name.isEmpty ? 'Participant' : name,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        local ? 'You' : 'Connected',
        style: const TextStyle(color: _muted, fontSize: 11),
      ),
      trailing: local
          ? Icon(
              _micOn ? Icons.mic : Icons.mic_off,
              color: Colors.white70,
              size: 17,
            )
          : null,
    );
  }

  Widget _controlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
      decoration: const BoxDecoration(
        color: _navy,
        border: Border(top: BorderSide(color: Color(0xFF273756))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _control(
              _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              _micOn ? 'Mute' : 'Unmute',
              _toggleMic,
              active: _micOn,
            ),
            const SizedBox(width: 8),
            _control(
              _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              _cameraOn ? 'Camera on' : 'Camera off',
              _toggleCamera,
              active: _cameraOn,
            ),
            const SizedBox(width: 8),
            _control(
              Icons.people_alt_outlined,
              'People',
              () => setState(() => _showPeople = !_showPeople),
              active: _showPeople,
            ),
            const SizedBox(width: 8),
            _control(
              Icons.call_end_rounded,
              'Leave',
              _confirmLeave,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _control(
    IconData icon,
    String label,
    VoidCallback action, {
    bool active = false,
    bool danger = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: _leaving ? null : action,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 44,
                decoration: BoxDecoration(
                  color: danger
                      ? _red
                      : active
                      ? const Color(0xFF2D4268)
                      : const Color(0xFF26334D),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
