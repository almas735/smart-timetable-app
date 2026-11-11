import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api_service.dart';
import 'home_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'student_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<String?> _registerForNotifications(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return 'No token was returned by Firebase';
      await ApiService.registerFcmToken(userId, token);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      if (!mounted) return;

      final notifError = await _registerForNotifications(user['id']);
      if (!mounted) return;
      if (notifError != null) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Notification setup failed'),
            content: SingleChildScrollView(child: SelectableText(notifError)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
        if (!mounted) return;
      }

      Widget destination;
      switch (user['role']) {
        case 'admin':
          destination = const HomeScreen();
          break;
        case 'faculty':
          destination = FacultyDashboardScreen(user: user);
          break;
        case 'student':
          destination = StudentDashboardScreen(user: user);
          break;
        default:
          destination = const HomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, size: 72, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'Smart Timetable',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
