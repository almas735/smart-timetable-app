import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pdf_export.dart';

class TimetableViewScreen extends StatefulWidget {
  final int timetableId;
  const TimetableViewScreen({super.key, required this.timetableId});

  @override
  State<TimetableViewScreen> createState() => _TimetableViewScreenState();
}

class _TimetableViewScreenState extends State<TimetableViewScreen> {
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const periodsPerDay = 6;

  bool loading = true;
  bool exporting = false;
  String? error;
  Map<String, Map<String, Map<int, dynamic>>> data = {};
  List<String> sectionNames = [];
  List<dynamic> allRooms = [];

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getTimetable(widget.timetableId),
        ApiService.getRooms(),
      ]);
      final result = results[0] as Map<String, dynamic>;
      final rooms = results[1] as List<dynamic>;
      final entries = result['entries'] as List<dynamic>;

      final grouped = <String, Map<String, Map<int, dynamic>>>{};
      for (final e in entries) {
        final section = e['section'] as String;
        grouped.putIfAbsent(section, () => {});
        grouped[section]!.putIfAbsent(e['day'], () => {});
        grouped[section]![e['day']]![e['period']] = e;
      }

      setState(() {
        data = grouped;
        sectionNames = grouped.keys.toList()..sort();
        allRooms = rooms;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> exportPdf() async {
    setState(() => exporting = true);
    try {
      await exportTimetablePdf(data, sectionNames);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  void _showEditDialog(dynamic entry) {
    String selectedDay = entry['day'];
    int selectedPeriod = entry['period'];
    int selectedRoomId = entry['room_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Move ${entry['subject']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry['section']} - ${entry['faculty']}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setDialogState(() => selectedDay = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedPeriod,
                decoration: const InputDecoration(labelText: 'Period'),
                items: List.generate(periodsPerDay, (i) => i + 1)
                    .map((p) => DropdownMenuItem(value: p, child: Text('Period $p')))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedPeriod = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedRoomId,
                decoration: const InputDecoration(labelText: 'Room'),
                items: allRooms
                    .map<DropdownMenuItem<int>>(
                        (r) => DropdownMenuItem(value: r['id'], child: Text(r['name'])))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedRoomId = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ApiService.updateTimetableEntry(
                    entry['entry_id'],
                    selectedDay,
                    selectedPeriod,
                    selectedRoomId,
                  );
                  await loadTimetable();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.red[700]),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generated Timetable')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generated Timetable')),
        body: Center(child: Text('Error: $error')),
      );
    }

    return DefaultTabController(
      length: sectionNames.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generated Timetable'),
          actions: [
            IconButton(
              icon: exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Export as PDF',
              onPressed: exporting ? null : exportPdf,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: sectionNames.map((s) => Tab(text: s)).toList(),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.indigo[50],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Tap any scheduled class to move it',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.indigo),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: sectionNames.map((section) => _buildDayList(section)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayList(String section) {
    final sectionData = data[section]!;

    return ListView(
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
                  final entry = sectionData[day]?[period];
                  return InkWell(
                    onTap: entry == null ? null : () => _showEditDialog(entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text('P$period', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: entry == null
                                ? const Text('Free', style: TextStyle(color: Colors.grey))
                                : Text('${entry['subject']} - ${entry['faculty']} (${entry['room']})'),
                          ),
                          if (entry != null)
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
