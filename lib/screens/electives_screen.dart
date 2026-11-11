import 'package:flutter/material.dart';
import '../api_service.dart';

class ElectivesScreen extends StatefulWidget {
  const ElectivesScreen({super.key});
  @override
  State<ElectivesScreen> createState() => _ElectivesScreenState();
}

class _ElectivesScreenState extends State<ElectivesScreen> {
  List<dynamic> sections = [];
  List<dynamic> allElectives = [];
  List<dynamic> sectionElectives = [];
  int? selectedSectionId;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  Future<void> loadInitial() async {
    setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([ApiService.getSections(), ApiService.getElectiveSubjects()]);
      setState(() {
        sections = results[0];
        allElectives = results[1];
        if (sections.isNotEmpty) selectedSectionId = sections[0]['id'];
        loading = false;
      });
      if (selectedSectionId != null) await loadSectionElectives();
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> loadSectionElectives() async {
    if (selectedSectionId == null) return;
    try {
      final result = await ApiService.getSectionElectives(selectedSectionId!);
      setState(() => sectionElectives = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> addElective(int subjectId) async {
    try {
      await ApiService.addSectionElective(selectedSectionId!, subjectId);
      await loadSectionElectives();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> removeElective(int linkId) async {
    try {
      await ApiService.removeSectionElective(selectedSectionId!, linkId);
      await loadSectionElectives();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NEP 2020 Electives')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose which cross-department electives each section\'s students take. A subject stays unscheduled unless at least one section picks it.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedSectionId,
                        decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                        items: sections.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
                        onChanged: (v) async {
                          setState(() => selectedSectionId = v);
                          await loadSectionElectives();
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Currently chosen:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      sectionElectives.isEmpty
                          ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('None chosen yet', style: TextStyle(color: Colors.grey)))
                          : Column(
                              children: sectionElectives.map<Widget>((e) => Card(
                                    child: ListTile(
                                      title: Text(e['subject_name']),
                                      subtitle: Text('from ${e['department']}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => removeElective(e['link_id']),
                                      ),
                                    ),
                                  )).toList(),
                            ),
                      const SizedBox(height: 20),
                      const Text('Available electives (any department):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: allElectives.map<Widget>((subj) {
                            final alreadyChosen = sectionElectives.any((e) => e['subject_id'] == subj['id']);
                            return Card(
                              child: ListTile(
                                title: Text(subj['name']),
                                subtitle: Text('${subj['department']} - ${subj['sessions_per_week']}x/week'),
                                trailing: alreadyChosen
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                                        onPressed: () => addElective(subj['id']),
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
