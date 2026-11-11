import 'package:flutter/material.dart';
import '../api_service.dart';
import 'timetable_view_screen.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  bool generating = false;
  String? error;
  Map<String, dynamic>? result;

  Future<void> generate() async {
    setState(() {
      generating = true;
      error = null;
      result = null;
    });
    try {
      final response = await ApiService.generateTimetable();
      setState(() {
        result = response;
        generating = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Timetable')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This runs the genetic algorithm against all your departments, faculty, subjects, rooms, and sections, and produces a clash-free weekly timetable.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'This takes 4-7 minutes - the algorithm is genuinely searching thousands of possible schedules. This is expected, not a hang.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: generating ? null : generate,
              icon: generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(generating ? 'Generating... please wait' : 'Generate Timetable'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 24),
            if (error != null) Text('Error: $error', style: const TextStyle(color: Colors.red)),
            if (result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final metrics = result!['metrics'] as Map<String, dynamic>;
    final hardConflicts = (metrics['section_conflicts'] as int) +
        (metrics['faculty_conflicts'] as int) +
        (metrics['room_conflicts'] as int);

    return Card(
      color: hardConflicts == 0 ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(hardConflicts == 0 ? Icons.check_circle : Icons.warning,
                    color: hardConflicts == 0 ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hardConflicts == 0
                        ? 'Conflict-free timetable generated!'
                        : 'Generated with $hardConflicts conflict(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Total class sessions scheduled: ${result!['total_entries']}'),
            const SizedBox(height: 4),
            Text('Section double-bookings: ${metrics['section_conflicts']}'),
            Text('Faculty double-bookings: ${metrics['faculty_conflicts']}'),
            Text('Room double-bookings: ${metrics['room_conflicts']}'),
            Text('Lab/room mismatches: ${metrics['lab_mismatches']}'),
            Text('Capacity issues: ${metrics['capacity_issues']}'),
            Text('Same-day subject repeats: ${metrics['same_day_repeats']} (soft preference)'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TimetableViewScreen(timetableId: result!['timetable_id']),
                ),
              ),
              icon: const Icon(Icons.calendar_month),
              label: const Text('View Full Timetable'),
            ),
          ],
        ),
      ),
    );
  }
}
