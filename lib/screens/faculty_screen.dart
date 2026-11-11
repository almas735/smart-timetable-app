import 'package:flutter/material.dart';
import '../api_service.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  List<dynamic> faculty = [];
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
        ApiService.getFaculty(),
        ApiService.getDepartments(),
      ]);
      setState(() {
        faculty = results[0];
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

  String departmentName(int departmentId) {
    for (final d in departments) {
      if (d['id'] == departmentId) return d['name'];
    }
    return 'Unknown department';
  }

  Future<void> addFaculty(String name, String email, int departmentId) async {
    try {
      await ApiService.createFaculty(name, email, departmentId);
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  Future<void> deleteFaculty(int id) async {
    try {
      await ApiService.deleteFaculty(id);
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void showAddDialog() {
    if (departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a department first before adding faculty')),
      );
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    int selectedDepartmentId = departments[0]['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Faculty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Prof. Sharma'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'e.g. sharma@college.edu'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedDepartmentId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.map<DropdownMenuItem<int>>((d) {
                  return DropdownMenuItem<int>(
                    value: d['id'],
                    child: Text(d['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedDepartmentId = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    emailController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  addFaculty(
                    nameController.text.trim(),
                    emailController.text.trim(),
                    selectedDepartmentId,
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
      appBar: AppBar(title: const Text('Faculty')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: faculty.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No faculty yet - tap + to add one')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: faculty.length,
                          itemBuilder: (context, index) {
                            final f = faculty[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(f['name']),
                                subtitle: Text('${f['email']} - ${departmentName(f['department_id'])}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteFaculty(f['id']),
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
