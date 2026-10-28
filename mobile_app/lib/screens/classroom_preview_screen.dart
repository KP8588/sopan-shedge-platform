import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../services/api_service.dart';

const _bg = Color(0xFF0B1428);
const _navy = Color(0xFF101D3A);
const _panel = Color(0xFF172440);
const _gold = Color(0xFFE3B341);
const _muted = Color(0xFF9AA8C2);

/// Full basic live-classroom UI. Replace the existing screen with this file.
/// It preserves the current Django LiveKit-token endpoint and classroom map input.
class ClassroomPreviewScreen extends StatefulWidget {
  const ClassroomPreviewScreen({super.key, required this.classroom});
  final Map<String, dynamic> classroom;

  @override
  State<ClassroomPreviewScreen> createState() => _ClassroomPreviewScreenState();
}

class _ClassroomPreviewScreenState extends State<ClassroomPreviewScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = false;
  bool _connected = false;
  bool _trainer = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _showPeople = false;
  bool _leaving = false;
  String? _error;
  String _status = 'Ready to join';

  String get _classId => widget.classroom['id']?.toString() ?? '';
  String get _title => widget.classroom['title']?.toString() ?? 'Sopan Live Classroom';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _join() async {
    if (_connecting || _connected) return;
    final id = int.tryParse(_classId);
    final auth = ApiService.authToken;
    if (id == null || id <= 0) {
      setState(() => _error = 'This classroom has an invalid ID.');
      return;
    }
    if (auth == null || auth.isEmpty) {
      setState(() => _error = 'Your session expired. Sign in again and retry.');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
      _status = 'Requesting secure access…';
    });
    try {
      final base = ApiService.baseUrl.replaceFirst(RegExp(r'/+$'), '');
      final response = await http.post(
        Uri.parse('$base/api/classrooms/$id/livekit-token/'),
        headers: {'Accept': 'application/json', 'Authorization': 'Token $auth'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Classroom access failed (HTTP ${response.statusCode}).');
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) throw Exception('Invalid server response.');
      final serverUrl = body['serverUrl']?.toString().trim() ?? '';
      final token = body['token']?.toString().trim() ?? '';
      _trainer = body['isTrainer'] == true;
      if (serverUrl.isEmpty || token.isEmpty) throw Exception('Missing classroom credentials in response.');

      if (mounted) setState(() => _status = 'Connecting to live classroom…');
      final room = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      _room = room;
      room.addListener(_onRoomChanged);
      _listener = room.createListener();
      _listener!.on<RoomDisconnectedEvent>((event) {
        if (!mounted || _leaving) return;
        setState(() {
          _connected = false;
          _status = 'Disconnected. Tap Retry to reconnect.';
        });
      });
      _listener!.on<ParticipantConnectedEvent>((event) {
        if (mounted) setState(() {});
      });
      _listener!.on<ParticipantDisconnectedEvent>((event) {
        if (mounted) setState(() {});
      });
      await room.connect(serverUrl, token);
      // Both trainers and students should publish their own media. The Django
      // token endpoint must grant canPublish=true to approved students too.
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connected = true;
        _micOn = true;
        _cameraOn = true;
        _status = _trainer ? 'You are live as trainer' : 'Connected · student camera and microphone enabled';
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
    if (mounted) setState(() {});
  }

  List<Participant> get _remote => _room?.remoteParticipants.values.toList(growable: false) ?? [];

  VideoTrack? _videoOf(Participant? participant) {
    if (participant == null) return null;
    for (final publication in participant.trackPublications.values) {
      final track = publication.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  VideoTrack? get _mainVideo {
    if (_trainer) {
      final localTrack = _videoOf(_room?.localParticipant);
      if (localTrack != null) return localTrack;
    }
    for (final participant in _remote) {
      final track = _videoOf(participant);
      if (track != null) return track;
    }
    return null;
  }

  Future<void> _toggleMic() async {
    final local = _room?.localParticipant;
    if (local == null || !_connected) return;
    final value = !_micOn;
    try {
      await local.setMicrophoneEnabled(value);
      if (mounted) setState(() => _micOn = value);
    } catch (_) {
      _snack('Could not change microphone. Check browser/device permission.');
    }
  }

  Future<void> _toggleCamera() async {
    final local = _room?.localParticipant;
    if (local == null || !_connected) return;
    final value = !_cameraOn;
    try {
      await local.setCameraEnabled(value);
      if (mounted) setState(() => _cameraOn = value);
    } catch (_) {
      _snack('Could not change camera. Check browser/device permission.');
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _disposeRoom() async {
    _listener?.dispose();
    _listener = null;
    final room = _room;
    _room = null;
    if (room == null) return;
    room.removeListener(_onRoomChanged);
    try { await room.disconnect(); } catch (_) {}
    try { await room.dispose(); } catch (_) {}
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await _disposeRoom();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmLeave() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave classroom?'),
        content: const Text('You will disconnect from the live lesson.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Leave')),
        ],
      ),
    );
    if (yes == true) await _leave();
  }

  @override
  void dispose() {
    _listener?.dispose();
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Class ID: $_classId', style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
        actions: [
          if (_connected) const Padding(padding: EdgeInsets.only(right: 4), child: Center(child: Chip(avatar: Icon(Icons.circle, size: 8, color: Color(0xFF53D6A0)), label: Text('LIVE'), backgroundColor: Color(0xFF173D36), labelStyle: TextStyle(color: Color(0xFFB7F4D8))))),
          IconButton(tooltip: 'Participants', onPressed: _connected ? () => setState(() => _showPeople = !_showPeople) : null, icon: const Icon(Icons.people_alt_outlined)),
        ],
      ),
      body: SafeArea(
        child: !_connected
            ? _joinScreen()
            : Column(children: [Expanded(child: wide ? _desktopMeeting() : _mobileMeeting()), _controlBar()]),
      ),
    );
  }

  Widget _joinScreen() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF2A3A5C))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_trainer ? Icons.video_camera_front_rounded : Icons.school_rounded, color: _gold, size: 56),
              const SizedBox(height: 14),
              Text(_trainer ? 'Trainer camera starts when you join' : 'Ready to join class?', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Check your connection before entering.', style: TextStyle(color: _muted)),
            ]),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _joinDeviceBadge(Icons.mic_none_rounded, 'Microphone'),
            const SizedBox(width: 12),
            _joinDeviceBadge(Icons.videocam_outlined, 'Camera'),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFA1A1))),
          ],
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _connecting ? null : _join,
            icon: _connecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.video_call_rounded),
            label: Text(_connecting ? _status : (_error == null ? 'Join class' : 'Retry connection')),
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 16)),
          )),
          const SizedBox(height: 8),
          Text(_trainer ? 'Trainer mode · camera and microphone enabled on join' : 'Student mode · camera and microphone available', style: const TextStyle(color: _muted, fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );

  Widget _joinDeviceBadge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A3A5C))),
    child: Row(children: [Icon(icon, color: _muted, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70))]),
  );

  List<Participant> get _allParticipants => <Participant>[
        if (_room?.localParticipant != null) _room!.localParticipant!,
        ..._remote,
      ];

  String _participantLabel(Participant participant) {
    final isLocal = identical(participant, _room?.localParticipant);
    if (isLocal) return _trainer ? 'You · Trainer' : 'You · Student';
    return participant.identity.isEmpty ? 'Participant' : participant.identity;
  }

  Widget _participantTile(Participant participant, {bool large = false}) {
    final isLocal = identical(participant, _room?.localParticipant);
    final track = _videoOf(participant);
    final label = _participantLabel(participant);
    return _videoTile(
      track,
      label,
      large: large,
      small: !large,
      micOn: isLocal ? _micOn : null,
      cameraOn: isLocal ? _cameraOn : null,
    );
  }

  Widget _mobileMeeting() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        const Icon(Icons.shield_outlined, color: Color(0xFF53D6A0), size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(_status, style: const TextStyle(color: _muted, fontSize: 12))),
        Text('${_remote.length + 1} people', style: const TextStyle(color: _muted, fontSize: 11)),
      ]),
    ),
    Expanded(
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _allParticipants.length == 1
              ? _participantTile(_allParticipants.first, large: true)
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _allParticipants.length == 2 ? 1 : 2,
                    childAspectRatio: _allParticipants.length == 2 ? 0.82 : 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allParticipants.length,
                  itemBuilder: (context, index) => _participantTile(_allParticipants[index]),
                ),
        ),
        if (_showPeople) Positioned.fill(child: _peoplePanel()),
      ]),
    ),
  ]);

  Widget _desktopMeeting() => Stack(children: [
    Padding(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        Expanded(
          child: _allParticipants.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _allParticipants.length <= 2 ? _allParticipants.length : 3,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _allParticipants.length,
                  itemBuilder: (context, index) => _participantTile(_allParticipants[index], large: _allParticipants.length == 1),
                ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF53D6A0), size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(_status, style: const TextStyle(color: _muted, fontSize: 12))),
          Text('${_remote.length + 1} participants', style: const TextStyle(color: _muted, fontSize: 12)),
        ]),
      ]),
    ),
    if (_showPeople) Positioned(right: 18, top: 18, bottom: 18, width: 280, child: _peoplePanel()),
  ]);

  Widget _videoTile(VideoTrack? track, String name, {bool large = false, bool small = false, bool? micOn, bool? cameraOn}) => ClipRRect(
    borderRadius: BorderRadius.circular(large ? 22 : 16),
    child: Container(
      decoration: BoxDecoration(color: _panel, border: Border.all(color: const Color(0xFF2A3A5C)), borderRadius: BorderRadius.circular(large ? 22 : 16)),
      child: Stack(fit: StackFit.expand, children: [
        if (track != null && (cameraOn != false)) VideoTrackRenderer(track, fit: VideoViewFit.cover)
        else Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A2B50), Color(0xFF101A30)])), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: small ? 24 : 42, backgroundColor: const Color(0xFF2A3D62), child: Icon(Icons.person_rounded, color: _gold, size: small ? 25 : 42)),
          const SizedBox(height: 8),
          Text(cameraOn == false ? 'Camera off' : 'Waiting for video…', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]))),
        Positioned(left: 10, right: 10, bottom: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.circle, color: Color(0xFF53D6A0), size: 7), const SizedBox(width: 7), Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)), if (micOn != null) Icon(micOn ? Icons.mic : Icons.mic_off, color: Colors.white70, size: 15)]))),
      ]),
    ),
  );

  Widget _peoplePanel() => Container(
    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF344568))),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 10, 6, 8), child: Row(children: [const Expanded(child: Text('Participants', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))), IconButton(onPressed: () => setState(() => _showPeople = false), icon: const Icon(Icons.close, color: Colors.white70))])),
      const Divider(color: Color(0xFF344568), height: 1),
      Expanded(child: ListView(padding: const EdgeInsets.all(10), children: [
        _person(_trainer ? 'You (Trainer)' : 'You (Student)', true),
        for (final p in _remote) _person(p.identity, false),
      ])),
      const Padding(padding: EdgeInsets.all(12), child: Text('Camera and microphone depend on your device permissions and classroom access.', style: TextStyle(color: _muted, fontSize: 12))),
    ]),
  );

  Widget _person(String name, bool local) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(radius: 17, backgroundColor: const Color(0xFF2A3D62), child: Icon(local ? Icons.person : Icons.school_outlined, color: _gold, size: 18)),
    title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(local ? 'You' : 'Connected', style: const TextStyle(color: _muted, fontSize: 11)),
    trailing: local && _trainer ? Icon(_micOn ? Icons.mic : Icons.mic_off, color: Colors.white70, size: 17) : null,
  );

  Widget _controlBar() => Container(
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
    decoration: const BoxDecoration(color: _navy, border: Border(top: BorderSide(color: Color(0xFF273756)))),
    child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _control(_micOn ? Icons.mic_rounded : Icons.mic_off_rounded, _micOn ? 'Mute' : 'Unmute', _toggleMic, active: _micOn),
      const SizedBox(width: 14),
      _control(_cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, _cameraOn ? 'Camera on' : 'Camera off', _toggleCamera, active: _cameraOn),
      const SizedBox(width: 14),
      _control(Icons.people_alt_outlined, 'People', () => setState(() => _showPeople = !_showPeople), active: _showPeople),
      const SizedBox(width: 14),
      _control(Icons.call_end_rounded, 'Leave', _confirmLeave, danger: true),
    ])),
  );

  Widget _control(IconData icon, String label, VoidCallback action, {bool active = false, bool danger = false}) => Semantics(
    button: true,
    label: label,
    child: InkWell(onTap: _leaving ? null : action, borderRadius: BorderRadius.circular(14), child: SizedBox(width: 68, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48, height: 46, decoration: BoxDecoration(color: danger ? const Color(0xFFCE454D) : active ? const Color(0xFF2D4268) : const Color(0xFF26334D), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 22)),
      const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]))),
  );
}
