import '../models/student_model.dart';
import 'api_service.dart';

class StudentService {
  final ApiService api;
  StudentService(this.api);
  Future<List<StudentModel>> getStudents() async =>
      (await api.list('Students')).map(StudentModel.fromJson).toList();
  Future<void> addStudent({
    required String lastname,
    required String firstname,
    required int courseId,
  }) => api.mutate(
    'Students/add',
    form: {
      'lastname': lastname,
      'firstname': firstname,
      'course_id': '$courseId',
    },
  );
  Future<void> updateStudent({
    required int id,
    required String lastname,
    required String firstname,
    required int courseId,
  }) => api.mutate(
    'Students/edit/$id',
    form: {
      'lastname': lastname,
      'firstname': firstname,
      'course_id': '$courseId',
    },
  );

  Future<void> deleteStudent(int id) => api.mutate('Students/delete/$id');
}
