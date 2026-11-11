import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) return body['detail'].toString();
    } catch (_) {}
    return 'Something went wrong (${response.statusCode})';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> registerFcmToken(int userId, String token) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getDepartments() async {
    final response = await http.get(Uri.parse('$baseUrl/departments'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> createDepartment(String name) async {
    final response = await http.post(Uri.parse('$baseUrl/departments'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> deleteDepartment(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/departments/$id'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getFaculty() async {
    final response = await http.get(Uri.parse('$baseUrl/faculty'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> createFaculty(String name, String email, int departmentId) async {
    final response = await http.post(Uri.parse('$baseUrl/faculty'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'department_id': departmentId}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> deleteFaculty(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/faculty/$id'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getSubjects() async {
    final response = await http.get(Uri.parse('$baseUrl/subjects'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> createSubject({
    required String name, required int sessionsPerWeek, required bool isElective,
    required bool requiresLab, required int departmentId, required int facultyId,
  }) async {
    final response = await http.post(Uri.parse('$baseUrl/subjects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name, 'sessions_per_week': sessionsPerWeek, 'is_elective': isElective,
          'requires_lab': requiresLab, 'department_id': departmentId, 'faculty_id': facultyId,
        }));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> deleteSubject(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/subjects/$id'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getRooms() async {
    final response = await http.get(Uri.parse('$baseUrl/rooms'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> createRoom(String name, int capacity, String roomType) async {
    final response = await http.post(Uri.parse('$baseUrl/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'capacity': capacity, 'room_type': roomType}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> deleteRoom(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/rooms/$id'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getSections() async {
    final response = await http.get(Uri.parse('$baseUrl/sections'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> createSection(String name, int semester, int strength, int departmentId) async {
    final response = await http.post(Uri.parse('$baseUrl/sections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'semester': semester, 'strength': strength, 'department_id': departmentId}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> deleteSection(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/sections/$id'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<Map<String, dynamic>> generateTimetable() async {
    final response = await http.post(Uri.parse('$baseUrl/timetable/generate')).timeout(const Duration(minutes: 15));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<Map<String, dynamic>> getTimetable(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/timetable/$id'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<Map<String, dynamic>> getLatestTimetable() async {
    final response = await http.get(Uri.parse('$baseUrl/timetable/latest'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> updateTimetableEntry(int entryId, String day, int period, int roomId) async {
    final response = await http.put(Uri.parse('$baseUrl/timetable/entries/$entryId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'day': day, 'period': period, 'room_id': roomId}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<Map<String, dynamic>> rescheduleForLeave(int facultyId, String day) async {
    final response = await http.post(Uri.parse('$baseUrl/timetable/reschedule-leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'faculty_id': facultyId, 'day': day}));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getElectiveSubjects() async {
    final response = await http.get(Uri.parse('$baseUrl/subjects/electives'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<List<dynamic>> getSectionElectives(int sectionId) async {
    final response = await http.get(Uri.parse('$baseUrl/sections/$sectionId/electives'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractError(response));
  }

  static Future<void> addSectionElective(int sectionId, int subjectId) async {
    final response = await http.post(Uri.parse('$baseUrl/sections/$sectionId/electives'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'subject_id': subjectId}));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  static Future<void> removeSectionElective(int sectionId, int linkId) async {
    final response = await http.delete(Uri.parse('$baseUrl/sections/$sectionId/electives/$linkId'));
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }
}
