import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_api_demo/config/api_config.dart';
import 'package:mobile_api_demo/data/notifiers.dart';
import 'package:mobile_api_demo/models/course_model.dart';
import 'package:mobile_api_demo/models/student_model.dart';
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/services/course_service.dart';
import 'package:mobile_api_demo/services/student_service.dart';
import 'package:mobile_api_demo/views/widgets/widget_tree.dart';

http.Response json(Object body) => http.Response(jsonEncode(body), 200);
void main() {
  setUp(() {
    selectedPageNotifier.value = 0;
    dotenv.loadFromString(
      envString: 'API_BASE_URL=http://10.0.2.2/sample/api/',
    );
  });
  test('config normalizes trailing slash and accepts other hosts', () {
    expect(ApiConfig.baseUrl, 'http://10.0.2.2/sample/api');
    for (final url in [
      'http://localhost/sample/api',
      'http://192.168.1.5/sample/api',
      'https://example.test/sample/api',
    ]) {
      dotenv.loadFromString(envString: 'API_BASE_URL=$url');
      expect(ApiConfig.baseUrl, url);
    }
  });
  test('models accept PHP string IDs but reject missing required fields', () {
    expect(CourseModel.fromJson({'id': '3', 'title': 'BSIT'}).id, 3);
    final student = StudentModel.fromJson({
      'id': '4',
      'course_id': '4',
      'title': 'BSIT',
      'lastname': 'Doe',
      'firstname': 'Jane',
    });
    expect(student.id, 4);
    expect(student.courseId, 4);
    expect(
      () => CourseModel.fromJson({'title': 'BSIT'}),
      throwsFormatException,
    );
    expect(
      () => CourseModel.fromJson({'id': 1.5, 'title': 'BSIT'}),
      throwsFormatException,
    );
  });
  test(
    'student list preserves distinct primary keys for the same course',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          return json({
            'data': [
              {
                'id': 4,
                'course_id': 6,
                'title': 'BSIT',
                'lastname': 'A',
                'firstname': 'One',
              },
              {
                'id': 7,
                'course_id': 6,
                'title': 'BSIT',
                'lastname': 'B',
                'firstname': 'Two',
              },
            ],
          });
        }),
      );
      addTearDown(api.close);
      final students = await StudentService(api).getStudents();
      expect(students.length, 2);
      expect(students.map((student) => student.id), [4, 7]);
      expect(requests.map((request) => request.url.path), [
        '/sample/api/Students/all',
      ]);
    },
  );
  test('course CRUD uses PHP routes, form fields, and GET deletion', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        expect(request.headers.containsKey('authorization'), false);
        if (request.url.path.endsWith('/Courses/all')) {
          return json({
            'data': [
              {'id': '7', 'title': 'Course'},
            ],
          });
        }
        if (request.url.path.endsWith('/Students/all')) {
          return json({'data': []});
        }
        if (request.method == 'GET' && request.url.path.endsWith('/edit/7')) {
          return json({'id': 7, 'title': 'Course'});
        }
        return json({'status': 'success', 'message': 'Saved'});
      }),
    );
    addTearDown(api.close);
    final service = CourseService(api);
    expect((await service.getCourses()).single.id, 7);
    await service.createCourse('Arts & Science');
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/sample/api/Courses/add');
    expect(
      requests.last.headers['content-type'],
      startsWith('application/x-www-form-urlencoded'),
    );
    expect(requests.last.bodyFields, {'title': 'Arts & Science'});
    expect((await service.getCourse(7)).id, 7);
    await service.updateCourse(7, 'New');
    expect(requests.last.url.path, '/sample/api/Courses/edit/7');
    expect(requests.last.method, 'POST');
    expect(requests.last.bodyFields, {'id': '7', 'title': 'New'});
    await service.deleteCourse(7);
    expect(requests.last.method, 'GET');
    expect(requests.last.url.path, '/sample/api/Courses/delete/7');
  });
  test('student creation and resource lists use exact contract', () async {
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/Students/add')) {
          expect(request.method, 'POST');
          expect(request.bodyFields, {
            'lastname': 'Dela Cruz',
            'firstname': 'José',
            'course_id': '2',
          });
          return json({
            'status': 'success',
            'message': 'Student added successfully.',
          });
        }
        if (request.url.path.endsWith('/Students/all')) {
          return json({
            'data': [
              {
                'id': 2,
                'course_id': 2,
                'title': 'BSN',
                'lastname': 'Dela Cruz',
                'firstname': 'José',
              },
            ],
          });
        }
        throw StateError('Unexpected request');
      }),
    );
    addTearDown(api.close);
    final service = StudentService(api);
    await service.addStudent(
      lastname: 'Dela Cruz',
      firstname: 'José',
      courseId: 2,
    );
    expect((await service.getStudents()).single.firstname, 'José');
  });
  test('course deletion fails closed when referenced by students', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/sample/api/Students/all');
        return json({
          'data': [
            {'course_id': '7'},
          ],
        });
      }),
    );
    addTearDown(api.close);
    await expectLater(
      CourseService(api).deleteCourse(7),
      throwsA(isA<Exception>()),
    );
  });
  test(
    'rejects HTTP 200 errors, malformed JSON, wrong envelopes and unconfirmed writes',
    () async {
      for (final response in [
        json({'status': 'error', 'message': 'Title is required.'}),
        http.Response('<html>PHP error</html>', 200),
        json([]),
        http.Response('Not found', 404),
      ]) {
        final api = ApiService(client: MockClient((_) async => response));
        await expectLater(
          api.request('Courses/all'),
          throwsA(isA<Exception>()),
        );
        api.close();
      }
      final api = ApiService(
        client: MockClient((_) async => json({'data': null})),
      );
      await expectLater(api.list('Courses'), throwsA(isA<Exception>()));
      await expectLater(
        api.mutate('Courses/add', form: {'title': 'X'}),
        throwsA(isA<Exception>()),
      );
      api.close();
    },
  );
  testWidgets('navigation and student course selection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    http.Request? submitted;
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/Students/add')) {
          submitted = request;
          return json({'status': 'success', 'message': 'Saved'});
        }
        if (request.url.path.endsWith('/Courses/all')) {
          return json({
            'data': [
              {'id': 9, 'title': 'BSIT'},
            ],
          });
        }
        return json({'data': []});
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: WidgetTree(api: api)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(2));
    await tester.tap(find.byTooltip('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Doe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Jane',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BSIT').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), '');
    await tester.ensureVisible(find.text('Create Student'));
    await tester.tap(find.text('Create Student'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name (not 0).'), findsOneWidget);
    expect(submitted, isNull);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Doe',
    );
    await tester.ensureVisible(find.text('Create Student'));
    await tester.tap(find.text('Create Student'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Student created successfully.'), findsOneWidget);
    expect(submitted!.bodyFields, {
      'lastname': 'Doe',
      'firstname': 'Jane',
      'course_id': '9',
    });
  });
  testWidgets(
    'course edit retrieves record and submits body id; delete confirms',
    (tester) async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/Students/all')) {
            return json({'data': []});
          }
          if (request.url.path.endsWith('/Courses/all')) {
            return json({
              'data': [
                {'id': 9, 'title': 'Old'},
              ],
            });
          }
          if (request.method == 'GET' && request.url.path.endsWith('/edit/9')) {
            return json({'id': 9, 'title': 'Fresh'});
          }
          return json({'status': 'success', 'message': 'Saved'});
        }),
      );
      addTearDown(api.close);
      selectedPageNotifier.value = 1;
      await tester.pumpWidget(MaterialApp(home: WidgetTree(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit course'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Fresh'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Changed');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.method == 'POST').single.bodyFields, {
        'id': '9',
        'title': 'Changed',
      });
      await tester.tap(find.byTooltip('Delete course'));
      await tester.pumpAndSettle();
      expect(requests.any((r) => r.url.path.contains('/delete/')), false);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        requests.any((r) => r.url.path.endsWith('/Courses/delete/9')),
        true,
      );
    },
  );
  testWidgets('students show loading, server failure and a working retry', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var calls = 0;
    final api = ApiService(
      client: MockClient((request) async {
        calls++;
        if (calls == 1) return response.future;
        return json({'data': []});
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: WidgetTree(api: api)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(
      json({'status': 'error', 'message': 'Database unavailable'}),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Database unavailable'), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No students found. Tap + to add one.'), findsOneWidget);
    expect(calls, 2);
  });
}
