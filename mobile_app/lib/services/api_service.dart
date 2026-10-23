
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  // For Flutter Web running in Chrome on this computer.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String? authToken;
  static Map<String, dynamic>? currentUser;

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login/'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Unexpected login response from the server.');
      }

      final data = Map<String, dynamic>.from(decoded);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true &&
          data['token'] != null) {
        authToken = data['token'].toString();

        final user = data['user'];
        currentUser = user is Map
            ? Map<String, dynamic>.from(user)
            : <String, dynamic>{'username': username.trim()};

        return data;
      }

      throw Exception(_errorMessage(data, 'Login failed.'));
    } on TimeoutException {
      throw Exception('Login timed out. Please try again.');
    } on http.ClientException {
      throw Exception(
        'Could not connect to Django. Check that the backend is running.',
      );
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    }
  }

  static Future<List<Map<String, dynamic>>> getCourses() async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/courses/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Could not load courses (HTTP ${response.statusCode}).',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      dynamic results;

      if (decoded is List) {
        results = decoded;
      } else if (decoded is Map) {
        results = decoded['results'];
      }

      if (results is! List) {
        throw Exception('Unexpected course data received from Django.');
      }

      return results
          .whereType<Map>()
          .map((course) => Map<String, dynamic>.from(course))
          .where((course) => course['is_active'] != false)
          .toList();
    } on TimeoutException {
      throw Exception('Loading courses timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Could not connect to Django.');
    } on FormatException {
      throw Exception('Django returned invalid course data.');
    }
  }

  static void logout() {
    authToken = null;
    currentUser = null;
  }

  static String _errorMessage(
    Map<String, dynamic> data,
    String fallback,
  ) {
    for (final key in ['detail', 'message', 'error']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    if (data['non_field_errors'] is List) {
      return (data['non_field_errors'] as List).join(' ');
    }

    return fallback;
  }
}
