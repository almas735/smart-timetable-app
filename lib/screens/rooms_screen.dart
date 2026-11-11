import 'package:flutter/material.dart';
import '../api_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<dynamic> rooms = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.getRooms();
      setState(() {
        rooms = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> addRoom(String name, int capacity, String roomType) async {
    try {
      await ApiService.createRoom(name, capacity, roomType);
      loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  Future<void> deleteRoom(int id) async {
    try {
      await ApiService.deleteRoom(id);
      loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void showAddDialog() {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '60');
    String selectedType = 'classroom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Room name', hintText: 'e.g. Room 101'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Room type'),
                items: const [
                  DropdownMenuItem(value: 'classroom', child: Text('Classroom')),
                  DropdownMenuItem(value: 'lab', child: Text('Lab')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final capacity = int.tryParse(capacityController.text.trim());
                if (nameController.text.trim().isNotEmpty && capacity != null && capacity > 0) {
                  Navigator.pop(context);
                  addRoom(nameController.text.trim(), capacity, selectedType);
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
      appBar: AppBar(title: const Text('Rooms')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: loadRooms,
                  child: rooms.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No rooms yet - tap + to add one')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final r = rooms[index];
                            final isLab = r['room_type'] == 'lab';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                leading: Icon(isLab ? Icons.science : Icons.meeting_room,
                                    color: isLab ? Colors.orange : Colors.indigo),
                                title: Text(r['name']),
                                subtitle: Text('${r['room_type']} - capacity ${r['capacity']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteRoom(r['id']),
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
