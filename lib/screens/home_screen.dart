import 'package:flutter/material.dart';
import 'departments_screen.dart';
import 'faculty_screen.dart';
import 'subjects_screen.dart';
import 'rooms_screen.dart';
import 'sections_screen.dart';
import 'generate_screen.dart';
import 'analytics_screen.dart';
import 'leave_screen.dart';
import 'electives_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Timetable - Admin'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(icon: Icons.business, title: 'Departments', subtitle: 'Manage departments',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentsScreen()))),
          _MenuCard(icon: Icons.people, title: 'Faculty', subtitle: 'Manage faculty',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyScreen()))),
          _MenuCard(icon: Icons.book, title: 'Subjects', subtitle: 'Manage subjects',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectsScreen()))),
          _MenuCard(icon: Icons.meeting_room, title: 'Rooms', subtitle: 'Manage rooms',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomsScreen()))),
          _MenuCard(icon: Icons.groups, title: 'Sections', subtitle: 'Manage sections',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SectionsScreen()))),
          _MenuCard(icon: Icons.school, title: 'NEP 2020 Electives', subtitle: 'Cross-department elective choices',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectivesScreen()))),
          _MenuCard(icon: Icons.auto_awesome, title: 'Generate Timetable', subtitle: 'Run the genetic algorithm',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateScreen()))),
          _MenuCard(icon: Icons.bar_chart, title: 'Analytics', subtitle: 'Room utilization & faculty load',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
          _MenuCard(icon: Icons.event_busy, title: 'Handle Leave', subtitle: 'Auto-reschedule a faculty day off',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen()))),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
