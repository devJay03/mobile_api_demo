import '../models/course_model.dart';
import 'api_service.dart';

class CourseService {
  final ApiService api;
  CourseService(this.api);
  Future<List<CourseModel>> getCourses() async =>
      (await api.list('Courses')).map(CourseModel.fromJson).toList();
  Future<CourseModel> getCourse(int id) async {
    final course = CourseModel.fromJson(await api.request('Courses/edit/$id'));
    if (course.id != id) throw Exception('Course identity mismatch.');
    return course;
  }

  Future<void> createCourse(String title) =>
      api.mutate('Courses/add', form: {'title': title});
  Future<void> updateCourse(int id, String title) =>
      api.mutate('Courses/edit/$id', form: {'id': '$id', 'title': title});
  Future<void> deleteCourse(int id) async {
    final students = await api.list('Students');
    for (final student in students) {
      final courseId = int.tryParse('${student['course_id']}');
      if (courseId == null || courseId <= 0) {
        throw Exception('Cannot verify course references. Deletion blocked.');
      }
      if (courseId == id) {
        throw Exception('This course has students and cannot be deleted here.');
      }
    }
    await getCourse(id);
    await api.mutate('Courses/delete/$id');
  }
}
