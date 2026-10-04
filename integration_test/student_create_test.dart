import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_api_demo/main.dart' as app;
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/services/student_service.dart';
import 'package:mobile_api_demo/services/course_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android student add, prefilled edit, cancel and delete', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    final api = ApiService();
    final service = StudentService(api);
    final fixture = 'Android${DateTime.now().millisecondsSinceEpoch}';
    final before = await service.getStudents();
    final courseService = CourseService(api);
    await courseService.createCourse('Course$fixture');
    final course = (await courseService.getCourses()).singleWhere(
      (c) => c.title == 'Course$fixture',
    );
    try {
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(find.byTooltip('Edit student'), findsNWidgets(before.length));
      expect(find.byTooltip('Delete student'), findsNWidgets(before.length));
      await tester.tap(find.byTooltip('Add student'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last name'),
        fixture,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Temporary',
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(course.title).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create Student'));
      await tester.tap(find.text('Create Student'));
      await tester.pumpAndSettle();
      final created = (await service.getStudents()).singleWhere(
        (s) => s.lastname == fixture,
      );
      expect(created.courseId, course.id);
      Finder tile(String first) => find.ancestor(
        of: find.text('$fixture, $first'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: tile('Temporary'),
          matching: find.byTooltip('Edit student'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(fixture), findsOneWidget);
      expect(find.text('Temporary'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .initialValue,
        course.id,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Updated',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('$fixture, Updated'), findsOneWidget);
      final after = await service.getStudents();
      expect(after.length, before.length + 1);
      expect(after.singleWhere((s) => s.id == created.id).firstname, 'Updated');
      for (final original in before) {
        final current = after.singleWhere((s) => s.id == original.id);
        expect(
          [current.lastname, current.firstname, current.courseId],
          [original.lastname, original.firstname, original.courseId],
        );
      }
      await tester.tap(
        find.descendant(
          of: tile('Updated'),
          matching: find.byTooltip('Delete student'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete Student?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('$fixture, Updated'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: tile('Updated'),
          matching: find.byTooltip('Delete student'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('$fixture, Updated'), findsNothing);
      expect(
        (await service.getStudents()).any((s) => s.id == created.id),
        false,
      );
      debugPrint(
        'Student CRUD passed: student ID ${created.id}, course ID ${course.id}',
      );
    } finally {
      for (final student in await service.getStudents()) {
        if (student.lastname == fixture) {
          await service.deleteStudent(student.id);
        }
      }
      await courseService.deleteCourse(course.id);
      api.close();
    }
  });
}
