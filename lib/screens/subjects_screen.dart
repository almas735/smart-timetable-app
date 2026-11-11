import 'package:flutter/material.dart';
import '../api_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<dynamic> subjects = [];
  List<dynamic> departments = [];
  List<dynamic> faculty = [];
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
        ApiService.getSubjects(),
        ApiService.getDepartments(),
        ApiService.getFaculty(),
      ]);
      setState(() {
        subjects = results[0];
        departments = results[1];
        faculty = results[2];
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

  String facultyName(int id) {
    for (final f in faculty) {
      if (f['id'] == id) return f['name'];
    }
    return 'Unknown faculty';
  }

  List<dynamic> facultyInDepartment(int departmentId) {
    return faculty.where((f) => f['department_id'] == departmentId).toList();
  }

  Future<void> addSubject({
    required String name,
    required int sessionsPerWeek,
    required bool isElective,
    required bool requiresLab,
    required int departmentId,
    required int facultyId,
  }) async {
    try {
      await ApiService.createSubject(
        name: name,
        sessionsPerWeek: sessionsPerWeek,
        isElective: isElective,
        requiresLab: requiresLab,
        departmentId: departmentId,
        facultyId: facultyId,
      );
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await ApiService.deleteSubject(id);
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
        const SnackBar(content: Text('Add a department first before adding subjects')),
      );
      return;
    }
    if (faculty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add faculty first before adding subjects')),
      );
      return;
    }

    final nameController = TextEditingController();
    final sessionsController = TextEditingController(text: '4');
    int selectedDepartmentId = departments[0]['id'];
    List<dynamic> availableFaculty = facultyInDepartment(selectedDepartmentId);
    int? selectedFacultyId = availableFaculty.isNotEmpty ? availableFaculty[0]['id'] : null;
    bool isElective = false;
    bool requiresLab = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject name', hintText: 'e.g. Data Structures'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sessionsController,
                  decoration: const InputDecoration(labelText: 'Sessions per week'),
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
                      availableFaculty = facultyInDepartment(selectedDepartmentId);
                      selectedFacultyId = availableFaculty.isNotEmpty ? availableFaculty[0]['id'] : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                availableFaculty.isEmpty
                    ? const Text('No faculty in this department yet', style: TextStyle(color: Colors.red))
                    : DropdownButtonFormField<int>(
                        initialValue: selectedFacultyId,
                        decoration: const InputDecoration(labelText: 'Faculty'),
                        items: availableFaculty.map<DropdownMenuItem<int>>((f) {
                          return DropdownMenuItem<int>(value: f['id'], child: Text(f['name']));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedFacultyId = value;
                          });
                        },
                      ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Elective (NEP 2020)'),
                  value: isElective,
                  onChanged: (value) => setDialogState(() => isElective = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Requires lab room'),
                  value: requiresLab,
                  onChanged: (value) => setDialogState(() => requiresLab = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final sessions = int.tryParse(sessionsController.text.trim());
                if (nameController.text.trim().isNotEmpty &&
                    sessions != null &&
                    sessions > 0 &&
                    selectedFacultyId != null) {
                  Navigator.pop(context);
                  addSubject(
                    name: nameController.text.trim(),
                    sessionsPerWeek: sessions,
                    isElective: isElective,
                    requiresLab: requiresLab,
                    departmentId: selectedDepartmentId,
                    facultyId: selectedFacultyId!,
                  );
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
      appBar: AppBar(title: const Text('Subjects')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: subjects.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No subjects yet - tap + to add one')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final s = subjects[index];
                            final tags = <String>[
                              '${s['sessions_per_week']}x/week',
                              if (s['is_elective'] == true) 'Elective',
                              if (s['requires_lab'] == true) 'Lab',
                            ];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(s['name']),
                                subtitle: Text(
                                  '${facultyName(s['faculty_id'])} - ${departmentName(s['department_id'])}\n${tags.join(' - ')}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteSubject(s['id']),
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
