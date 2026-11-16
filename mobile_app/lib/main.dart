import 'package:flutter/material.dart';
import 'screens/classroom_preview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_service.dart';
import 'screens/recorded_lectures_screen.dart';

void main() => runApp(const SopanLearningApp());

const navy = Color(0xFF101D3A);
const gold = Color(0xFFE3B341);
const background = Color(0xFFF5F7FB);

class SopanLearningApp extends StatelessWidget {
  const SopanLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sopan Learning',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD7DCE5)),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    debugPrint('LOGIN UI: Login button pressed');

    try {
      debugPrint('LOGIN UI: Calling ApiService.login');

      await ApiService.login(
        username: _username.text,
        password: _password.text,
      );

      debugPrint('LOGIN UI: API login succeeded');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } catch (e) {
      // Never log credentials or authentication tokens.
      debugPrint('LOGIN UI: Failed with ${e.runtimeType}');
      debugPrint('LOGIN UI: Error = $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 76,
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: gold,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SOPAN LEARNING',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue your learning journey.',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _username,
                          enabled: !_loading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: _inputDecoration(
                            'Username',
                            Icons.person_outline,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your username.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_loading,
                          obscureText: _hidePassword,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _signIn(),
                          decoration:
                              _inputDecoration(
                                'Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter your password.'
                              : null,
                        ),
                         if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _loading ? null : _signIn,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text('CREATE NEW ACCOUNT'),
                        ),
                    ],),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _language = 'English';
  final _languages = const ['English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil'];

  String get _username =>
      ApiService.currentUser?['username']?.toString() ?? 'Student';

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() {
    ApiService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOPAN LEARNING',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _message('No new notifications.'),
            icon: const Icon(Icons.notifications_none),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
              if (v == 'profile') {
                _open(const ProfileScreen());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'WELCOME BACK!',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, $_username',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your learning journey starts here.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [navy, Color(0xFF263F70)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.live_tv, color: gold, size: 34),
                const SizedBox(height: 12),
                const Text(
                  'LIVE LEARNING',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn directly from your trainer.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View your schedule and open configured meeting links.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _open(const LiveClassesScreen()),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join a Class'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Learning Language',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: _inputDecoration('Language', Icons.translate),
            items: _languages
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _language = v);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Learning',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _featureCard(
                  Icons.menu_book_rounded,
                  'My Courses',
                  'Explore lessons',
                  () => _open(const CourseListScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _featureCard(
                  Icons.play_circle_outline,
                  'Live Classes',
                  'View schedule',
                  () => _open(const LiveClassesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _quickLink(
            Icons.video_library_outlined,
            'Recorded Lessons',
            'Revisit lessons at your own pace',
            () => _open(const RecordedLecturesScreen()),
          ),
          _quickLink(
            Icons.history_rounded,
            'Class History',
            'View previous classes',
            () => _message('Class history is not connected yet.'),
          ),
          _quickLink(
            Icons.person_outline,
            'My Profile',
            'Manage your student account',
            () => _open(const ProfileScreen()),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              _open(const CourseListScreen());
              break;
            case 2:
              _open(const LiveClassesScreen());
              break;
            case 3:
              _open(const ProfileScreen());
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_camera_front_outlined),
            label: 'Live Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: navy, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickLink(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9EDF6),
          child: Icon(icon, color: navy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getCourses();
  }

  void _reload() => setState(() => _future = ApiService.getCourses());

  Future<void> _refresh() async {
    final next = ApiService.getCourses();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _StatusList(
                icon: Icons.hourglass_top,
                title: 'Loading courses...',
              );
            }
            if (snapshot.hasError) {
              return _StatusList(
                icon: Icons.cloud_off,
                title: 'Unable to load courses',
                message: '${snapshot.error}',
                actionLabel: 'Try Again',
                onAction: _reload,
              );
            }
            final courses = snapshot.data ?? [];
            if (courses.isEmpty) {
              return const _StatusList(
                icon: Icons.menu_book_outlined,
                title: 'No active courses available yet.',
                message: 'Courses will appear here when available.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = (course['title'] ?? 'Course ${index + 1}')
                    .toString();
                final description = (course['description'] ?? '').toString();
                final language = (course['language'] ?? '').toString();

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE9EDF6),
                      child: Icon(Icons.menu_book_rounded, color: navy),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(description),
                          if (language.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Language: $language',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(course: course),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key, required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final title = (course['title'] ?? 'Course Details').toString();
    final description = (course['description'] ?? '').toString();
    final id = (course['id'] ?? 'N/A').toString();
    final language = (course['language'] ?? 'Not specified').toString();
    final active = course['is_active'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [navy, Color(0xFF263F70)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_rounded, color: gold, size: 44),
                SizedBox(height: 18),
                Text(
                  'YOUR LEARNING JOURNEY',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 24),
          _detailRow(Icons.tag, 'Course ID', id),
          _detailRow(Icons.translate, 'Course Language', language),
          _detailRow(
            Icons.check_circle,
            'Course Status',
            active ? 'Active' : 'Inactive',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveClassesScreen()),
            ),
            icon: const Icon(Icons.video_call),
            label: const Text('Explore Live Classes'),
            const SizedBox(height: 12),

FilledButton.icon(
  onPressed: () {
    final courseId = int.tryParse(course['id'].toString());

    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid course ID.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordedLecturesScreen(
          courseId: courseId,
          courseName: title,
        ),
      ),
    );
  },
  icon: const Icon(Icons.video_library),
  label: const Text('View Recorded Lectures'),
),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to My Courses'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9EDF6),
          child: Icon(icon, color: navy),
        ),
        title: Text(label, style: const TextStyle(color: Colors.blueGrey)),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getClassrooms();
  }

  void _reload() => setState(() => _future = ApiService.getClassrooms());

  Future<void> _refresh() async {
    final next = ApiService.getClassrooms();
    setState(() => _future = next);
    await next;
  }

  String _status(Map<String, dynamic> item) {
    if (item['is_active'] != true) return 'Inactive';
    final start = DateTime.tryParse(
      item['scheduled_at']?.toString() ?? '',
    )?.toLocal();
    if (start == null) return 'Schedule unavailable';

    final duration =
        int.tryParse(item['duration_minutes']?.toString() ?? '') ?? 60;
    final end = start.add(Duration(minutes: duration));
    final now = DateTime.now();
    if (now.isBefore(start)) return 'Upcoming';
    if (now.isBefore(end)) return 'In progress';
    return 'Past';
  }

  String _formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'Schedule unavailable';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${date.year} at $hour:$minute $period';
  }

  Future<void> _openMeeting(Map<String, dynamic> item) async {
    final status = _status(item);

    if (status != 'Upcoming' && status != 'In progress') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class is not currently joinable.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClassroomPreviewScreen(classroom: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        actions: [
          IconButton(
            tooltip: 'Refresh classes',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _StatusList(
                icon: Icons.hourglass_top,
                title: 'Loading live classes...',
              );
            }
            if (snapshot.hasError) {
              return _StatusList(
                icon: Icons.cloud_off,
                title: 'Unable to load live classes',
                message: '${snapshot.error}',
                actionLabel: 'Try Again',
                onAction: _reload,
              );
            }

            final classes = [...?snapshot.data]
              ..sort((a, b) {
                final first =
                    DateTime.tryParse(a['scheduled_at']?.toString() ?? '') ??
                    DateTime(2100);
                final second =
                    DateTime.tryParse(b['scheduled_at']?.toString() ?? '') ??
                    DateTime(2100);
                return first.compareTo(second);
              });

            if (classes.isEmpty) {
              return const _StatusList(
                icon: Icons.video_camera_front_outlined,
                title: 'No live classes available',
                message: 'Scheduled classes will appear here.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Your Classes',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Check the schedule and join a configured meeting.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 16),
                for (final item in classes) _classCard(item),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Live Class').toString();
    final course = (item['course'] ?? 'N/A').toString();
    final status = _status(item);
    final active = item['is_active'] == true;
    final start = DateTime.tryParse(
      item['scheduled_at']?.toString() ?? '',
    )?.toLocal();
    final joinableTime = status == 'Upcoming' || status == 'In progress';
    final canJoin = active && joinableTime;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE9EDF6),
                  child: Icon(Icons.video_call, color: navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _info(Icons.menu_book, 'Course ID: $course'),
            _info(Icons.calendar_today, _formatDate(item['scheduled_at'])),
            _info(Icons.schedule, '${item['duration_minutes'] ?? 60} minutes'),
            _info(Icons.info_outline, status),
            if (start != null && status == 'Past')
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'This scheduled session has ended.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canJoin ? () => _openMeeting(item) : null,
                icon: const Icon(Icons.video_call),
                label: Text(
                  canJoin
                      ? 'Join Class'
                      : (status == 'Past'
                            ? 'Class Ended'
                            : !active
                            ? 'Class Inactive'
                            : 'Class Not Joinable'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        Icon(icon, size: 58, color: Colors.blueGrey),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Center(child: Text(message!, textAlign: TextAlign.center)),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
