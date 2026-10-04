class StudentModel {
  final int id;
  final String lastname;
  final String firstname;
  final int courseId;
  final String title;
  const StudentModel({
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.courseId,
    required this.title,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final courseId = int.tryParse(json['course_id'].toString());
    final lastname = json['lastname'];
    final firstname = json['firstname'];
    final title = json['title']?.toString() ?? '';
    if (courseId == null ||
        courseId <= 0 ||
        lastname is! String ||
        firstname is! String) {
      throw const FormatException('Invalid student record.');
    }
    return StudentModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      lastname: lastname,
      firstname: firstname,
      courseId: courseId,
      title: title,
    );
  }
}
