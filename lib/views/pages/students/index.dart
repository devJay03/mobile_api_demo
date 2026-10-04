import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../../../services/api_service.dart';
import '../../../services/student_service.dart';
import 'add.dart';
import 'edit.dart';

class StudentPage extends StatefulWidget {
  final ApiService api;
  const StudentPage({super.key, required this.api});
  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  List<StudentModel> students = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await StudentService(
        widget.api,
      ).getStudents();
      if (!mounted) return;
      setState(() {
        students = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error!)));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> addStudent() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentAddPage(api: widget.api),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student created successfully.'),
      ),
    );
    await loadStudents();
  }

  Future<void> editStudent(StudentModel student) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEditPage(
          api: widget.api,
          student: student,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student updated successfully.'),
      ),
    );
    await loadStudents();
  }

  Future<void> deleteStudent(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'Are you sure you want to delete ${student.firstname} ${student.lastname}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await StudentService(
        widget.api,
      ).deleteStudent(student.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully.'),
        ),
      );
      await loadStudents();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStudents,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  96,
                ),
                children: [
                  if (error != null) ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: loadStudents,
                      child: const Text('Retry'),
                    ),
                  ] else if (students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No students found. Tap + to add one.',
                      ),
                    )
                  else
                    for (final student in students)
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                          ),
                          title: Text(
                            '${student.lastname}, ${student.firstname}',
                          ),
                          subtitle: Text(
                            'Course: ${student.title}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit student',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                ),
                                onPressed: () =>
                                    editStudent(student),
                              ),
                              IconButton(
                                tooltip: 'Delete student',
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                                onPressed: () =>
                                    deleteStudent(student),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add student',
        onPressed: addStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
