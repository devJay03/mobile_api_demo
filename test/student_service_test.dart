import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/services/student_service.dart';

void main() {
  test(
    'student mutations use route identity, form POST and GET deletion',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        baseUrl: 'http://localhost/sample/api',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'status': 'success', 'message': 'Saved'}),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final service = StudentService(api);
      await service.updateStudent(
        id: 4,
        lastname: 'Doe',
        firstname: 'Jane',
        courseId: 6,
      );
      expect(requests.last.url.path, '/sample/api/Students/edit/4');
      expect(requests.last.method, 'POST');
      expect(requests.last.bodyFields, {
        'lastname': 'Doe',
        'firstname': 'Jane',
        'course_id': '6',
      });
      await service.deleteStudent(4);
      expect(requests.last.url.path, '/sample/api/Students/delete/4');
      expect(requests.last.method, 'GET');
    },
  );
  test('student mutations reject errors and missing success status', () async {
    for (final body in [
      {'status': 'error', 'message': 'Student not found.'},
      {'message': 'Not confirmed'},
    ]) {
      final api = ApiService(
        baseUrl: 'http://localhost/sample/api',
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
      final service = StudentService(api);
      await expectLater(
        service.updateStudent(
          id: 4,
          lastname: 'Doe',
          firstname: 'Jane',
          courseId: 6,
        ),
        throwsException,
      );
      await expectLater(service.deleteStudent(4), throwsException);
      api.close();
    }
  });
}
