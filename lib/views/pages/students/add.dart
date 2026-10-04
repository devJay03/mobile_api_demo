import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import '../../../services/api_service.dart';
import '../../../services/course_service.dart';
import '../../../services/student_service.dart';

class StudentAddPage extends StatefulWidget {
  final ApiService api;
  const StudentAddPage({super.key, required this.api});
  @override
  State<StudentAddPage> createState() => _StudentAddPageState();
}

class _StudentAddPageState extends State<StudentAddPage> {
  final _form = GlobalKey<FormState>();
  final _lastname = TextEditingController();
  final _firstname = TextEditingController();
  late Future<List<CourseModel>> _courses;
  int? _courseId;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _courses = CourseService(widget.api).getCourses();
  }

  @override
  void dispose() {
    _lastname.dispose();
    _firstname.dispose();
    super.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '0') {
      return 'Enter a name (not 0).';
    }
    if (value.trim().runes.length > 55) return 'Use at most 55 characters.';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await StudentService(widget.api).addStudent(
        lastname: _lastname.text.trim(),
        firstname: _firstname.text.trim(),
        courseId: _courseId!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _lastname,
                enabled: !_saving,
                maxLength: 55,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstname,
                enabled: !_saving,
                maxLength: 55,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: validateName,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<CourseModel>>(
                future: _courses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        Text(snapshot.error.toString()),
                        TextButton(
                          onPressed: () => setState(() {
                            _courseId = null;
                            _courses = CourseService(widget.api).getCourses();
                          }),
                          child: const Text('Retry courses'),
                        ),
                      ],
                    );
                  }
                  final courses = snapshot.data!;
                  if (courses.isEmpty) {
                    return const Text(
                      'Create a course in the Courses tab before adding a student.',
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _courseId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Course'),
                    items: courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course.id,
                            child: Text(course.title),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _courseId = value),
                    validator: (value) =>
                        value == null ? 'Select a course.' : null,
                  );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving || _courseId == null ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Create Student'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
