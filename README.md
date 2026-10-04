# Sample School Flutter client

Flutter client for the native PHP API at `/sample/api`, with Students and Courses navigation and Light/Dark mode.

## Run

1. Start Apache and MySQL in XAMPP with the existing sample database.
2. Set `API_BASE_URL` in `.env`; Android emulator default: `http://10.0.2.2/sample/api`.
3. Run `flutter pub get`, then `flutter run -d emulator-5554`.

Students and Courses support list, add, edit and confirmed delete. Student edits prefill names and the current course. Successful edits/deletions reload the list and show a Snackbar. Failed requests show an error without removing a local record.

The Student PHP queries return `s.id AS id`, preserving `s.course_id` separately. Flutter stores this primary key in `StudentModel.id` and uses it in edit/delete routes.

Use the AppBar sun/moon button to switch themes. `isDarkModeNotifier`, `ValueListenableBuilder`, and `selectedPageNotifier` remain in use. Student pages are under `lib/views/pages/students` with `index.dart`, `add.dart`, and `edit.dart`. Courses use only `lib/views/pages/courses/index.dart`, with Add/Edit AlertDialogs and a Delete confirmation dialog.

## Checks

- `dart format lib test integration_test`
- `flutter analyze`
- `flutter test`
- `flutter test integration_test -d emulator-5554`

Live tests require XAMPP. They create uniquely named temporary records, verify CRUD and clean up their fixtures. The Android suite also checks both themes. See BACKEND_CONTRACT.md for request fields and IMPLEMENTATION_REPORT.md for results.
