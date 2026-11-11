import 'package:flutter/material.dart';
import '../api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool loading = true;
  String? error;
  Map<String, int> roomCounts = {};
  Map<String, int> facultyCounts = {};
  final int totalSlots = 30;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.getLatestTimetable();
      final entries = result['entries'] as List<dynamic>;

      final rooms = <String, int>{};
      final faculty = <String, int>{};
      for (final e in entries) {
        final room = e['room'] as String;
        final fac = e['faculty'] as String;
        rooms[room] = (rooms[room] ?? 0) + 1;
        faculty[fac] = (faculty[fac] ?? 0) + 1;
      }

      setState(() {
        roomCounts = rooms;
        facultyCounts = faculty;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<MapEntry<String, int>> _sorted(Map<String, int> map) {
    final list = map.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  int _maxFacultyLoad() {
    if (facultyCounts.isEmpty) return 1;
    return facultyCounts.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildBar({required String label, required int value, required int max, required Color color}) {
    final fraction = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$value / $max'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
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
                  onRefresh: loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Room Utilization',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Out of 30 possible weekly slots per room',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ..._sorted(roomCounts).map((e) => _buildBar(
                            label: e.key,
                            value: e.value,
                            max: totalSlots,
                            color: Colors.indigo,
                          )),
                      const SizedBox(height: 28),
                      const Text('Faculty Weekly Load',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Number of class sessions taught per week',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ..._sorted(facultyCounts).map((e) => _buildBar(
                            label: e.key,
                            value: e.value,
                            max: _maxFacultyLoad(),
                            color: Colors.teal,
                          )),
                    ],
                  ),
                ),
    );
  }
}
