import 'package:flutter/material.dart';
import '../api_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  List<dynamic> faculty = [];
  bool loadingFaculty = true;
  int? selectedFacultyId;
  String selectedDay = days[0];
  bool processing = false;
  Map<String, dynamic>? result;
  String? error;

  @override
  void initState() {
    super.initState();
    loadFaculty();
  }

  Future<void> loadFaculty() async {
    try {
      final list = await ApiService.getFaculty();
      setState(() {
        faculty = list;
        loadingFaculty = false;
        if (list.isNotEmpty) selectedFacultyId = list[0]['id'];
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loadingFaculty = false;
      });
    }
  }

  Future<void> reschedule() async {
    if (selectedFacultyId == null) return;
    setState(() {
      processing = true;
      error = null;
      result = null;
    });
    try {
      final response = await ApiService.rescheduleForLeave(selectedFacultyId!, selectedDay);
      setState(() {
        result = response;
        processing = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handle Faculty Leave')),
      body: loadingFaculty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mark a faculty member as on leave for a day. The system will automatically move their affected classes to a different day - checking faculty, room, and section availability the same way the generator does - and flag any it genuinely cannot move.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    initialValue: selectedFacultyId,
                    decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder()),
                    items: faculty
                        .map<DropdownMenuItem<int>>(
                            (f) => DropdownMenuItem(value: f['id'], child: Text(f['name'])))
                        .toList(),
                    onChanged: (v) => setState(() => selectedFacultyId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Day of leave', border: OutlineInputBorder()),
                    items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => selectedDay = v!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: processing ? null : reschedule,
                    icon: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.event_busy),
                    label: Text(processing ? 'Rescheduling...' : 'Reschedule Affected Classes'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  const SizedBox(height: 24),
                  if (error != null) Text('Error: $error', style: const TextStyle(color: Colors.red)),
                  if (result != null) _buildResult(),
                ],
              ),
            ),
    );
  }

  Widget _buildResult() {
    final moved = result!['moved'] as List<dynamic>;
    final unresolved = result!['unresolved'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result!['message'], style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (moved.isNotEmpty) ...[
              const Text('Moved:', style: TextStyle(fontWeight: FontWeight.w600)),
              ...moved.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${m['subject']} (${m['section']}): ${m['from_day']} P${m['from_period']} -> ${m['to_day']} P${m['to_period']} in ${m['room']}',
                    ),
                  )),
            ],
            if (unresolved.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Could not be moved automatically:',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              ...unresolved.map((u) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${u['subject']} (${u['section']}) - needs manual handling'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
