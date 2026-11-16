import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  // Development only.
  // With adb reverse tcp:8000 tcp:8000, Android can use this address.
  // For a physical phone without adb reverse, use your PC's LAN IP.
  // For production, replace with your HTTPS backend URL.
  static const String baseUrl = 'http://127.0.0.1:8000';
  // static const String baseUrl = 'http://10.139.43.7:8000';

  static const Duration _requestTimeout = Duration(seconds: 15);

  static String? authToken;
  static Map<String, dynamic>? currentUser;

  // ---------------------------------------------------------------------------
  // REGISTER
  // Backend: POST /api/auth/register/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String phone = '',
    String referralCode = '',
    String preferredLanguage = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register/');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'email': email.trim(),
              'password': password,
              'phone': phone.trim(),
              'referral_code': referralCode.trim().toUpperCase(),
              'preferred_language': preferredLanguage,
            }),
          )
          .timeout(_requestTimeout);

      final data = _decodeMap(response.body, 'registration');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(data, 'Registration failed.'));
      }

      if (data['success'] != true ||
          data['token'] == null ||
          data['token'].toString().isEmpty) {
        throw Exception(
          _errorMessage(data, 'Registration response is incomplete.'),
        );
      }

      authToken = data['token'].toString();

      final user = data['user'];
      currentUser = user is Map
          ? Map<String, dynamic>.from(user)
          : <String, dynamic>{'username': username.trim()};

      return data;
    } on TimeoutException {
      throw Exception('Registration timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Could not connect to the Django server.');
    } on FormatException {
      throw Exception('The server returned invalid registration data.');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // Backend: POST /api/auth/login/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login/');

    debugPrint('LOGIN: Starting request');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('LOGIN: HTTP ${response.statusCode}');

      final data = _decodeMap(response.body, 'login');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true &&
          data['token'] != null &&
          data['token'].toString().isNotEmpty) {
        authToken = data['token'].toString();

        final user = data['user'];
        currentUser = user is Map
            ? Map<String, dynamic>.from(user)
            : <String, dynamic>{'username': username.trim()};

        debugPrint('LOGIN: Authentication successful');
        return data;
      }

      throw Exception(_errorMessage(data, 'Login failed.'));
    } on TimeoutException {
      throw Exception('Login timed out. Check the connection to the backend.');
    } on http.ClientException {
      throw Exception('Could not connect to the Django server.');
    } on FormatException {
      throw Exception('The server returned invalid login data.');
    }
  }

  // ---------------------------------------------------------------------------
  // CURRENT USER
  // Backend: GET /api/auth/me/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getMe() async {
    final data = await _getMap(
      '/api/auth/me/',
      operation: 'Loading your account',
    );

    final user = data['user'];
    if (user is Map) {
      currentUser = Map<String, dynamic>.from(user);
    }

    return data;
  }

  // ---------------------------------------------------------------------------
  // MY REFERRAL ACCOUNT
  // Backend: GET /api/auth/referrals/me/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getMyReferrals() async {
    _requireLogin();

    final data = await _getMap(
      '/api/auth/referrals/me/',
      operation: 'Loading your referral account',
    );

    return data;
  }

  // ---------------------------------------------------------------------------
  // ADMIN REFERRAL TREE
  // Backend: GET /api/auth/referrals/tree/
  // The backend must enforce administrator permissions.
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getAdminReferralTree() async {
    _requireLogin();

    final data = await _getMap(
      '/api/auth/referrals/tree/',
      operation: 'Loading the referral hierarchy',
    );

    return _extractList(data, 'results');
  }

  // ---------------------------------------------------------------------------
  // ADMIN COMMISSION LEDGER
  // Backend: GET /api/auth/commissions/
  // This reads ledger entries; it does not create commissions.
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getAdminCommissions() async {
    _requireLogin();

    final data = await _getMap(
      '/api/auth/commissions/',
      operation: 'Loading commission records',
    );

    return _extractList(data, 'results');
  }

  // ---------------------------------------------------------------------------
  // LIVEKIT CLASSROOM TOKEN
  // Backend: POST /api/classrooms/<id>/livekit-token/
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getLiveKitToken(int classroomId) async {
    if (classroomId <= 0) {
      throw ArgumentError.value(
        classroomId,
        'classroomId',
        'Classroom ID must be positive.',
      );
    }

    _requireLogin();

    final uri = Uri.parse(
      '$baseUrl/api/classrooms/$classroomId/livekit-token/',
    );

    debugPrint('LIVEKIT: Requesting token for classroom $classroomId');

    try {
      final response = await http
          .post(uri, headers: _headers())
          .timeout(_requestTimeout);

      debugPrint('LIVEKIT: HTTP ${response.statusCode}');

      final data = _decodeMap(response.body, 'LiveKit');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(data, 'Could not join this classroom.'));
      }

      final serverUrl = data['serverUrl'];
      final accessToken = data['token'];
      final roomName = data['roomName'];
      final isTrainer = data['isTrainer'];

      if (serverUrl is! String ||
          serverUrl.isEmpty ||
          accessToken is! String ||
          accessToken.isEmpty ||
          roomName is! String ||
          roomName.isEmpty ||
          isTrainer is! bool) {
        throw Exception(
          'Django returned incomplete classroom connection details.',
        );
      }

      debugPrint('LIVEKIT: Classroom token received successfully');

      return {
        'serverUrl': serverUrl,
        'token': accessToken,
        'roomName': roomName,
        'isTrainer': isTrainer,
      };
    } on TimeoutException {
      throw Exception('Requesting classroom access timed out.');
    } on http.ClientException {
      throw Exception('Could not connect to Django for classroom access.');
    } on FormatException {
      throw Exception('Django returned invalid classroom data.');
    }
  }

  // ---------------------------------------------------------------------------
  // COURSES
  // Backend: GET /api/courses/
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getCourses() async {
    final data = await _getResponse(
      '/api/courses/',
      operation: 'Loading courses',
    );

    final results = _extractListFromResponse(data);

    return results.where((item) => item['is_active'] != false).toList();
  }

  // ---------------------------------------------------------------------------
  // LIVE CLASSROOMS
  // Backend: GET /api/classrooms/
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getClassrooms() async {
    final data = await _getResponse(
      '/api/classrooms/',
      operation: 'Loading live classes',
    );

    return _extractListFromResponse(data);
  }


  // ---------------------------------------------------------------------------
  // RECORDED LECTURES
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getRecordedLectures({
    int? courseId,
  }) async {
    _requireLogin();

    final query = courseId == null ? '' : '?course=$courseId';

    final data = await _getResponse(
      '/api/courses/lectures/$query',
      operation: 'Loading recorded lectures',
    );

    return _extractListFromResponse(data);
  }

  static Future<Map<String, dynamic>> getRecordedLecture(int id) async {
    _requireLogin();

    final data = await _getMap(
      '/api/courses/lectures/$id/',
      operation: 'Loading lecture details',
    );

    return data;
  }

  static Future<List<Map<String, dynamic>>> getLectureProgress() async {
    _requireLogin();

    final data = await _getResponse(
      '/api/courses/lecture-progress/',
      operation: 'Loading lecture progress',
    );

    return _extractListFromResponse(data);
  }

  static Future<Map<String, dynamic>> saveLectureProgress({
    required int lectureId,
    required int positionSeconds,
    bool completed = false,
  }) async {
    _requireLogin();

    final uri = Uri.parse(
      '$baseUrl/api/courses/lectures/$lectureId/progress/',
    );

    final response = await http
        .post(
          uri,
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'position_seconds': positionSeconds,
            'completed': completed,
          }),
        )
        .timeout(_requestTimeout);

    final data = _decodeMap(response.body, 'lecture progress');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(data, 'Could not save lecture progress.'),
      );
    }

    return data;
  }


  // ---------------------------------------------------------------------------
  // SHARED HTTP HELPERS
  // ---------------------------------------------------------------------------

  static Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};

    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  static void _requireLogin() {
    final token = authToken;

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in to continue.');
    }
  }

  static Future<Map<String, dynamic>> _getMap(
    String path, {
    required String operation,
  }) async {
    final data = await _getResponse(path, operation: operation);

    if (data is! Map<String, dynamic>) {
      throw Exception('$operation failed: unexpected server response.');
    }

    return data;
  }

  static Future<dynamic> _getResponse(
    String path, {
    required String operation,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http
          .get(uri, headers: _headers())
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _tryErrorMessage(
          response.body,
          '$operation failed (HTTP ${response.statusCode}).',
        );
        throw Exception(message);
      }

      return jsonDecode(response.body);
    } on TimeoutException {
      throw Exception('$operation timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Could not connect to Django while $operation.');
    } on FormatException {
      throw Exception('Django returned invalid data while $operation.');
    }
  }

  static Map<String, dynamic> _decodeMap(String body, String operation) {
    final dynamic decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw FormatException('Unexpected $operation response from the server.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  static List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic results = data[key];

    if (results is! List) {
      throw Exception('Unexpected list data received from Django.');
    }

    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<Map<String, dynamic>> _extractListFromResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map && decoded['results'] is List) {
      return (decoded['results'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  
    if (decoded is Map && decoded.containsKey('id')) {
      return [Map<String, dynamic>.from(decoded)];
    }

    throw Exception('Unexpected list data received from Django.');
  }

  static String _tryErrorMessage(String body, String fallback) {
    try {
      final data = _decodeMap(body, 'error');
      return _errorMessage(data, fallback);
    } catch (_) {
      return fallback;
    }
  }

  static String _errorMessage(Map<String, dynamic> data, String fallback) {
    for (final key in ['detail', 'message', 'error']) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is List && value.isNotEmpty) {
        return value.join(' ');
      }
    }

    // Django REST Framework commonly returns field-specific errors,
    // for example {"email": ["This field is required."]}.
    final messages = <String>[];

    for (final entry in data.entries) {
      final value = entry.value;

      if (value is List) {
        messages.add('${entry.key}: ${value.join(' ')}');
      } else if (value is String && value.trim().isNotEmpty) {
        messages.add('${entry.key}: ${value.trim()}');
      }
    }

    if (messages.isNotEmpty) {
      return messages.join('\n');
    }

    return fallback;
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  static void logout() {
    authToken = null;
    currentUser = null;
  }
}
