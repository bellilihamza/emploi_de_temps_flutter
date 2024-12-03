import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  _TimetablePageState createState() => _TimetablePageState();
}
class _TimetablePageState extends State<TimetablePage> {
  final String apiUrl = 'http://localhost:3000/sessions';
  final String teachersApiUrl = 'http://localhost:3000/teachers';
  final String subjectsApiUrl = 'http://localhost:3000/subjects';
  final String roomsApiUrl = 'http://localhost:3000/rooms';

  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = true;

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController teacherController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSessions();
    fetchTeachers();
    fetchSubjects();
    fetchRooms();
  }

  Future<void> fetchSessions() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          sessions = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        showError('Failed to fetch sessions. Please try again later.');
      }
    } catch (e) {
      showError('Error fetching sessions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTeachers() async {
    try {
      final response = await http.get(Uri.parse(teachersApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          teachers = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        showError('Failed to fetch teachers.');
      }
    } catch (e) {
      showError('Error fetching teachers: $e');
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final response = await http.get(Uri.parse(subjectsApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          subjects = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        showError('Failed to fetch subjects.');
      }
    } catch (e) {
      showError('Error fetching subjects: $e');
    }
  }

  Future<void> fetchRooms() async {
    try {
      final response = await http.get(Uri.parse(roomsApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          rooms = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        showError('Failed to fetch rooms.');
      }
    } catch (e) {
      showError('Error fetching rooms: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addSession() async {
    final String subject = subjectController.text.trim();
    final String teacher = teacherController.text.trim();
    final String room = roomController.text.trim();
    final String classId = classController.text.trim();
    final String date = dateController.text.trim();
    final String startTime = startTimeController.text.trim();
    final String endTime = endTimeController.text.trim();

    if (subject.isEmpty || teacher.isEmpty || room.isEmpty || classId.isEmpty || date.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      showError('Please fill all fields.');
      return;
    }

    try {
      final newSession = {
        'subject_id': subject,
        'teacher_id': teacher,
        'room_id': room,
        'class_id': classId,
        'session_date': date,
        'start_time': startTime,
        'end_time': endTime,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newSession),
      );

      if (response.statusCode == 201) {
        fetchSessions();
        Navigator.pop(context);
      } else {
        showError('Failed to add session.');
      }
    } catch (e) {
      showError('Error adding session. Please try again.');
    }
  }

  void _showAddSessionDialog(String day, String time) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Session'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(subjectController, 'Subject'),
                _buildTextField(teacherController, 'Teacher'),
                _buildTextField(roomController, 'Room'),
                _buildTextField(classController, 'Class'),
                _buildTextField(dateController, 'Date (YYYY-MM-DD)', hint: day),
                _buildTextField(startTimeController, 'Start Time (HH:MM)', hint: time.split(' - ')[0]),
                _buildTextField(endTimeController, 'End Time (HH:MM)', hint: time.split(' - ')[1]),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: addSession,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: 60,
                    columnSpacing: 20,
                    border: TableBorder.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    columns: _buildColumns(),
                    rows: _buildRows(),
                  ),
                ),
              ),
            ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(
        label: Text(
          'Hours',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      for (String day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'])
        DataColumn(
          label: Center(
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
    ];
  }

  List<DataRow> _buildRows() {
    return [
      for (String time in _timeSlots())
        DataRow(
          cells: [
            DataCell(
              Text(
                time,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (String day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'])
              DataCell(
                GestureDetector(
                  onDoubleTap: () => _showAddSessionDialog(day, time),
                  child: _getSessionForDayAndTime(day, time),
                ),
              ),
          ],
        ),
    ];
  }

  List<String> _timeSlots() {
    return [
      '08:00 - 09:00',
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
    ];
  }

  Widget _getSessionForDayAndTime(String day, String time) {
    final session = sessions.firstWhere(
      (session) {
        final sessionDate = DateTime.parse(session['session_date']);
        final sessionDay = _getDayFromDate(sessionDate);
        final sessionTime = session['start_time'];

        return sessionDay == day && sessionTime == time.split(' - ')[0];
      },
      orElse: () => {},
    );

    if (session.isEmpty) {
      return const Text('No session');
    } else {
      return Text('${session['subject_id']} - ${session['teacher_id']}');
    }
  }

  String _getDayFromDate(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      default:
        return '';
    }
  }
}

