import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

const profileNavy = Color(0xFF101D3A);
const profileGold = Color(0xFFE3B341);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getMe();
  }

  Future<void> _refresh() async {
    final future = ApiService.getMe();
    setState(() => _profileFuture = future);
    await future;
  }

  String _value(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString();
  }

  void _copyReferral(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Widget _detail(String label, String value, {IconData? icon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon ?? Icons.info_outline, color: profileNavy),
      title: Text(
        label,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: profileNavy,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: profileNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load your profile.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final response = snapshot.data ?? {};
          final rawUser = response['user'];
          final user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : <String, dynamic>{};

          final referralCode = _value(user, 'referral_code');

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [profileNavy, Color(0xFF263F70)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: profileGold,
                        child: Icon(Icons.person, color: profileNavy, size: 42),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _value(user, 'username'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _value(user, 'role'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _section('Personal Information', [
                  _detail(
                    'Username',
                    _value(user, 'username'),
                    icon: Icons.person_outline,
                  ),
                  _detail(
                    'Email',
                    _value(user, 'email'),
                    icon: Icons.email_outlined,
                  ),
                  _detail(
                    'Phone',
                    _value(user, 'phone'),
                    icon: Icons.phone_outlined,
                  ),
                  _detail(
                    'Learning Language',
                    _value(user, 'preferred_language'),
                    icon: Icons.translate,
                  ),
                ]),
                _section('Student Identification', [
                  _detail(
                    'Public Student ID',
                    _value(user, 'public_id'),
                    icon: Icons.badge_outlined,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.card_giftcard,
                      color: profileNavy,
                    ),
                    title: const Text(
                      'Referral Code',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                    ),
                    subtitle: Text(
                      referralCode,
                      style: const TextStyle(
                        color: profileNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Copy referral code',
                      onPressed: referralCode == 'Not provided'
                          ? null
                          : () => _copyReferral(referralCode),
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  _detail(
                    'Referred By',
                    _value(user, 'referred_by_username'),
                    icon: Icons.people_outline,
                  ),
                ]),
                _section('Account Status', [
                  _detail(
                    'Account',
                    user['is_active'] == true ? 'Active' : 'Inactive',
                    icon: Icons.verified_user_outlined,
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
