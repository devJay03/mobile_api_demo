import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import '../../../services/api_service.dart';
import '../../../services/course_service.dart';

class CoursePage extends StatefulWidget {
  final ApiService api;
  const CoursePage({super.key, required this.api});
  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late final _service = CourseService(widget.api);
  List<CourseModel> courses = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await _service.getCourses();
      if (!mounted) return;
      setState(() {
        courses = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
      showMessage(error!);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _busy = false;

  Future<void> _edit([CourseModel? course]) async {
    setState(() => _busy = true);
    try {
      final current = course == null
          ? null
          : await _service.getCourse(course.id);
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CourseDialog(service: _service, course: current),
      );
      if (saved == true && mounted) {
        showMessage(
          course == null
              ? 'Course added successfully.'
              : 'Course updated successfully.',
        );
        await loadCourses();
      }
    } catch (error) {
      if (mounted) showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CourseModel course) async {
    setState(() => _busy = true);
    try {
      var deleting = false;
      String? deleteError;
      final deleted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => PopScope(
            canPop: !deleting,
            child: AlertDialog(
              title: const Text('Delete Course?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Are you sure you want to delete ${course.title}?'),
                  if (deleteError != null)
                    Text(
                      deleteError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: deleting
                      ? null
                      : () async {
                          setDialogState(() {
                            deleting = true;
                            deleteError = null;
                          });
                          try {
                            await _service.deleteCourse(course.id);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (error) {
                            if (context.mounted) {
                              setDialogState(() {
                                deleting = false;
                                deleteError = error.toString();
                              });
                            }
                          }
                        },
                  child: Text(deleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            ),
          ),
        ),
      );
      if (deleted != true || !mounted) return;
      showMessage('Course deleted successfully.');
      await loadCourses();
    } catch (error) {
      if (mounted) showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: loadCourses,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_busy) const Text('Course action in progress...'),
                if (error != null) ...[
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: loadCourses,
                    child: const Text('Retry'),
                  ),
                ] else if (courses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No courses found. Tap + to add one.'),
                  )
                else
                  for (final course in courses)
                    Card(
                      child: ListTile(
                        title: Text(course.title),
                        subtitle: Text('Course #${course.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit course',
                              onPressed: _busy ? null : () => _edit(course),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete course',
                              onPressed: _busy ? null : () => _delete(course),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Add course',
      onPressed: _busy ? null : () => _edit(),
      child: const Icon(Icons.add),
    ),
  );
}

class _CourseDialog extends StatefulWidget {
  final CourseService service;
  final CourseModel? course;
  const _CourseDialog({required this.service, this.course});
  @override
  State<_CourseDialog> createState() => __CourseDialogState();
}

class __CourseDialogState extends State<_CourseDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.course?.title ?? '');
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final course = widget.course;
      if (course == null) {
        await widget.service.createCourse(_title.text.trim());
      } else {
        await widget.service.updateCourse(course.id, _title.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.course == null ? 'Add Course' : 'Edit Course'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                enabled: !_saving,
                autofocus: true,
                maxLength: 55,
                decoration: const InputDecoration(labelText: 'Course Title'),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      value.trim() == '0') {
                    return 'Enter a course title (not 0).';
                  }
                  if (value.trim().runes.length > 55) {
                    return 'Use at most 55 characters.';
                  }
                  return null;
                },
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
  );
}
