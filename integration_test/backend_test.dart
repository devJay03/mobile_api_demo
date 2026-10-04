import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_api_demo/config/api_config.dart';
import 'package:mobile_api_demo/data/notifiers.dart';
import 'package:mobile_api_demo/main.dart' as app;
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/services/course_service.dart';
import 'package:mobile_api_demo/services/student_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final darkMode in [false, true]) {
    testWidgets('Android PHP screens and course CRUD (dark: $darkMode)', (
      tester,
    ) async {
      selectedPageNotifier.value = 0;
      isDarkModeNotifier.value = false;
      await dotenv.load(fileName: '.env');
      expect(ApiConfig.baseUrl, 'http://10.0.2.2/sample/api');
      final api = ApiService();
      final courses = CourseService(api);
      final title = 'MobileTest${DateTime.now().millisecondsSinceEpoch}';
      final updated = '${title}Updated';
      try {
        // Real Android HTTP requests; no mocked client.
        expect(await courses.getCourses(), isNotNull);
        expect(await StudentService(api).getStudents(), isNotNull);
        await app.main();
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.light,
        );
        await tester.tap(find.byTooltip('Switch to Dark Mode'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.dark,
        );
        expect(find.byIcon(Icons.light_mode), findsOneWidget);
        if (!darkMode) {
          await tester.tap(find.byTooltip('Switch to Light Mode'));
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.dark_mode), findsOneWidget);
        }

        expect(find.byType(NavigationDestination), findsNWidgets(2));
        await tester.tap(find.text('Courses').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add course'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(AlertDialog))).brightness,
          darkMode ? Brightness.dark : Brightness.light,
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.text('Enter a course title (not 0).'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), title);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        var tile = find.ancestor(
          of: find.text(title),
          matching: find.byType(ListTile),
        );
        await tester.tap(
          find.descendant(of: tile, matching: find.byTooltip('Edit course')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(AlertDialog))).brightness,
          darkMode ? Brightness.dark : Brightness.light,
        );
        expect(find.text(title), findsWidgets);
        await tester.enterText(find.byType(TextFormField), updated);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(updated), findsOneWidget);
        tile = find.ancestor(
          of: find.text(updated),
          matching: find.byType(ListTile),
        );
        await tester.tap(
          find.descendant(of: tile, matching: find.byTooltip('Delete course')),
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(AlertDialog))).brightness,
          darkMode ? Brightness.dark : Brightness.light,
        );
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.text(updated), findsNothing);
        expect(
          (await courses.getCourses()).any(
            (c) => c.title == updated || c.title == title,
          ),
          false,
        );
      } finally {
        // Only uniquely named fixtures created by this test may be cleaned up.
        for (final course in await courses.getCourses()) {
          if (course.title == title || course.title == updated) {
            await courses.deleteCourse(course.id);
          }
        }
        api.close();
      }
    });
  }
}
