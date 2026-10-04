import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/views/pages/courses/index.dart';

void main() {
  testWidgets(
    'course modal validates, survives failure, waits for success and refreshes',
    (tester) async {
      final pending = Completer<http.Response>();
      var writes = 0;
      var lists = 0;
      final api = ApiService(
        baseUrl: 'http://localhost/sample/api',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            writes++;
            expect(request.url.path, '/sample/api/Courses/add');
            expect(request.bodyFields, {'title': 'New Course'});
            if (writes == 1) {
              return http.Response(
                jsonEncode({'status': 'error', 'message': 'Try again'}),
                200,
              );
            }
            return pending.future;
          }
          lists++;
          return http.Response(
            jsonEncode({
              'data': lists == 1
                  ? []
                  : [
                      {'id': 23, 'title': 'New Course'},
                    ],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MaterialApp(home: CoursePage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add course'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a course title (not 0).'), findsOneWidget);
      expect(writes, 0);
      await tester.enterText(find.byType(TextFormField), 'New Course');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Try again'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Saving...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Saving...'),
            )
            .onPressed,
        isNull,
      );
      expect(lists, 1);
      pending.complete(
        http.Response(
          jsonEncode({'status': 'success', 'message': 'Saved'}),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('New Course'), findsOneWidget);
      expect(find.text('Course added successfully.'), findsOneWidget);
      expect(lists, 2);
      await tester.tap(find.byTooltip('Add course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(writes, 2);
    },
  );
}
