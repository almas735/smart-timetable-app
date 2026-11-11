import 'package:flutter/material.dart';
import '../api_service.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  List<dynamic> sections = [];
  List<dynamic> departments = [];
  bool loading = true;
  String? error;

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
      final results = await Future.wait([
        ApiService.getSections(),
        ApiService.getDepartments(),
      ]);
      setState(() {
        sections = results[0];
        departments = results[1];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String departmentName(int id) {
    for (final d in departments) {
      if (d['id'] == id) return d['name'];
    }
    return 'Unknown department';
  }

  Future<void> addSection(String name, int semester, int strength, int departmentId) async {
    try {
      await ApiService.createSection(name, semester, strength, departmentId);
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  Future<void> deleteSection(int id) async {
    try {
      await ApiService.deleteSection(id);
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void showAddDialog() {
    if (departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a department first before adding sections')),
      );
      return;
    }

    final nameController = TextEditingController();
    final semesterController = TextEditingController(text: '5');
    final strengthController = TextEditingController(text: '60');
    int selectedDepartmentId = departments[0]['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Section'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Section name', hintText: 'e.g. CSE-3A'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: semesterController,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: strengthController,
                  decoration: const InputDecoration(labelText: 'Strength (number of students)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: departments.map<DropdownMenuItem<int>>((d) {
                    return DropdownMenuItem<int>(value: d['id'], child: Text(d['name']));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDepartmentId = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final semester = int.tryParse(semesterController.text.trim());
                final strength = int.tryParse(strengthController.text.trim());
                if (nameController.text.trim().isNotEmpty &&
                    semester != null &&
                    semester > 0 &&
                    strength != null &&
                    strength > 0) {
                  Navigator.pop(context);
                  addSection(nameController.text.trim(), semester, strength, selectedDepartmentId);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sections')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: sections.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No sections yet - tap + to add one')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final s = sections[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(s['name']),
                                subtitle: Text(
                                  '${departmentName(s['department_id'])} - Semester ${s['semester']} - ${s['strength']} students',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteSection(s['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
