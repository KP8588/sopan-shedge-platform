
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();

  String _language = 'en';
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  static const navy = Color(0xFF142B50);
  static const gold = Color(0xFFD6AD55);

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.register(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        referralCode: _referral.text,
        preferredLanguage: _language,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.school, size: 65, color: navy),
                    const SizedBox(height: 12),
                    const Text(
                      'CREATE YOUR ACCOUNT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _username,
                      decoration: _decoration('Username', Icons.person),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter username'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email', Icons.email),
                      validator: (v) =>
                          v == null ||
                                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(v.trim())
                              ? 'Enter valid email'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('Phone', Icons.phone),
                      validator: (v) =>
                          v != null && v.length > 20
                              ? 'Maximum 20 characters'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: _decoration(
                        'Password',
                        Icons.lock,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _hidePassword = !_hidePassword,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 8
                              ? 'Password must be at least 8 characters'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: _decoration(
                        'Preferred Language',
                        Icons.translate,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                        DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                        DropdownMenuItem(value: 'kn', child: Text('Kannada')),
                        DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                        DropdownMenuItem(value: 'te', child: Text('Telugu')),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _language = v);
                              }
                            },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _referral,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _decoration(
                        'Referral Code (Optional)',
                        Icons.card_giftcard,
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: navy,
                        ),
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
