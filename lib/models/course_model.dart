class CourseModel {
  final int id;
  final String title;
  const CourseModel({required this.id, required this.title});

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id'].toString());
    final title = json['title'];
    if (id == null || id <= 0 || title is! String || title.trim().isEmpty) {
      throw const FormatException('Invalid course record.');
    }
    return CourseModel(id: id, title: title);
  }
}
