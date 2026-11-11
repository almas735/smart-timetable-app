import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const StudentDashboardScreen({super.key, required this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const periodsPerDay = 6;

  bool loading = true;
  String? error;
  Map<String, Map<int, dynamic>> schedule = {};

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.getLatestTimetable();
      final entries = result['entries'] as List<dynamic>;
      final mySectionId = widget.user['section_id'];

      final grouped = <String, Map<int, dynamic>>{};
      for (final e in entries) {
        if (e['section_id'] == mySectionId) {
          grouped.putIfAbsent(e['day'], () => {});
          grouped[e['day']]![e['period']] = e;
        }
      }

      setState(() {
        schedule = grouped;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Timetable - ${widget.user['name']}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: logout)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadSchedule,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: days.map((day) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                              const Divider(),
                              ...List.generate(periodsPerDay, (i) {
                                final period = i + 1;
                                final entry = schedule[day]?[period];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                          width: 50,
                                          child: Text('P$period',
                                              style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Expanded(
                                        child: entry == null
                                            ? const Text('Free', style: TextStyle(color: Colors.grey))
                                            : Text('${entry['subject']} - ${entry['faculty']} (${entry['room']})'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
