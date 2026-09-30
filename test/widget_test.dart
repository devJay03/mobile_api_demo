import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_api_demo/config/api_config.dart';
import 'package:mobile_api_demo/data/notifiers.dart';
import 'package:mobile_api_demo/main.dart';
import 'package:mobile_api_demo/models/category_model.dart';
import 'package:mobile_api_demo/models/product_model.dart';
import 'package:mobile_api_demo/models/user_model.dart';
import 'package:mobile_api_demo/services/api_service.dart';
import 'package:mobile_api_demo/services/auth_service.dart';
import 'package:mobile_api_demo/services/storage_service.dart';
import 'package:mobile_api_demo/views/pages/auth/login_page.dart';
import 'package:mobile_api_demo/views/pages/auth/register_page.dart';
import 'package:mobile_api_demo/views/pages/categories/category_page.dart';
import 'package:mobile_api_demo/views/pages/products/product_add_page.dart';
import 'package:mobile_api_demo/views/pages/products/product_edit_page.dart';
import 'package:mobile_api_demo/views/pages/products/product_list_page.dart';
import 'package:mobile_api_demo/views/widgets/widget_tree.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.2.2/web-api/api');
  });

  group('Models & Config Tests', () {
    test('ApiConfig default endpoints', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.login, contains('/login'));
      expect(ApiConfig.register, contains('/register'));
      expect(ApiConfig.logout, contains('/logout'));
      expect(ApiConfig.categories, contains('/categories'));
      expect(ApiConfig.products, contains('/products'));
    });

    test('UserModel serialization', () {
      final json = {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'};
      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.toJson(), json);
    });

    test('CategoryModel serialization', () {
      final json = {'id': 5, 'name': 'Electronics', 'description': 'Gadgets'};
      final category = CategoryModel.fromJson(json);
      expect(category.id, 5);
      expect(category.name, 'Electronics');
      expect(category.description, 'Gadgets');
      expect(category.toJson(), json);
    });

    test('ProductModel numeric safety parsing', () {
      final json = {
        'id': '10',
        'name': 'Laptop',
        'category_id': '2',
        'category_name': 'Tech',
        'price': '999.99',
        'quantity': '15',
      };
      final product = ProductModel.fromJson(json);
      expect(product.id, 10);
      expect(product.name, 'Laptop');
      expect(product.categoryId, 2);
      expect(product.categoryName, 'Tech');
      expect(product.price, 999.99);
      expect(product.quantity, 15);
    });
  });

  group('UI & Navigation Verification', () {
    testWidgets('App displays LoginPage when unauthenticated',
        (WidgetTester tester) async {
      isUserLoggedInNotifier.value = false;
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(WidgetTree), findsNothing);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('App displays WidgetTree when authenticated',
        (WidgetTester tester) async {
      isUserLoggedInNotifier.value = true;
      selectedPageNotifier.value = 0;
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(WidgetTree), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ProductListPage), findsOneWidget);
    });

    testWidgets('Tab switching via NavbarWidget switches pages',
        (WidgetTester tester) async {
      isUserLoggedInNotifier.value = true;
      selectedPageNotifier.value = 0;
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(ProductListPage), findsOneWidget);
      expect(find.byType(CategoryPage), findsNothing);

      // Tap on Categories tab (index 1)
      await tester.tap(find.text('Categories'));
      await tester.pump();

      expect(selectedPageNotifier.value, 1);
      expect(find.byType(CategoryPage), findsOneWidget);
      expect(find.byType(ProductListPage), findsNothing);
    });

    testWidgets('Logout button resets auth state and routes to LoginPage',
        (WidgetTester tester) async {
      isUserLoggedInNotifier.value = true;
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(WidgetTree), findsOneWidget);

      final logoutButton = find.byIcon(Icons.logout);
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(isUserLoggedInNotifier.value, false);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(WidgetTree), findsNothing);
    });

    testWidgets('ProductEditPage pre-fills existing product data',
        (WidgetTester tester) async {
      final product = ProductModel(
        id: 42,
        name: 'Keyboard',
        categoryId: 3,
        categoryName: 'Accessories',
        price: 49.99,
        quantity: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductEditPage(product: product),
        ),
      );
      await tester.pump();

      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('49.99'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Update Product'), findsOneWidget);
    });

    testWidgets('ProductAddPage form validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductAddPage(),
        ),
      );
      await tester.pump();

      final saveButton = find.text('Save Product');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Please enter product name'), findsOneWidget);
    });
  });

  group('Registration Flow & Form UX Refinements', () {
    testWidgets('LoginPage input types and password visibility toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pump();

      // Verify email input type
      final emailField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Email'),
          matching: find.byType(TextField),
        ),
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);

      // Verify password input type and initial obscure state
      final passwordFieldInitial = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordFieldInitial.keyboardType, TextInputType.visiblePassword);
      expect(passwordFieldInitial.obscureText, isTrue);

      // Toggle password visibility
      final toggleButton = find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(IconButton),
      );
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pump();

      final passwordFieldToggled = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordFieldToggled.obscureText, isFalse);

      // Tapping background unfocuses keyboard
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
    });

    testWidgets('LoginPage navigate to RegisterPage and back without stacking',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pump();

      // Tap Register link
      final registerLink = find.text('Register');
      expect(registerLink, findsOneWidget);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);

      // Tap "Already have an account? Login" link in RegisterPage
      final loginLink = find.text('Login');
      expect(loginLink, findsOneWidget);
      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Should be back to LoginPage without duplicate pages
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(RegisterPage), findsNothing);
    });

    testWidgets('RegisterPage input types, password toggles, and form validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pump();

      // Email field input type
      final emailField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Email'),
          matching: find.byType(TextField),
        ),
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);

      // Password field input type & obscure state
      final passwordField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(TextField),
        ),
      );
      expect(passwordField.keyboardType, TextInputType.visiblePassword);
      expect(passwordField.obscureText, isTrue);

      // Confirm Password field input type & obscure state
      final confirmPasswordField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Confirm Password'),
          matching: find.byType(TextField),
        ),
      );
      expect(confirmPasswordField.keyboardType, TextInputType.visiblePassword);
      expect(confirmPasswordField.obscureText, isTrue);

      // Toggle password visibility
      final passwordToggle = find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(IconButton),
      );
      await tester.tap(passwordToggle);
      await tester.pump();

      final updatedPassword = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(TextField),
        ),
      );
      expect(updatedPassword.obscureText, isFalse);

      // Tap Register button to trigger validation
      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets(
        'Successful registration clears navigation history and routes into WidgetTree',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/register')) {
          return http.Response(
            jsonEncode({
              'token': 'test_reg_token_123',
              'user': {'id': 1, 'name': 'New User', 'email': 'new@test.com'},
            }),
            201,
          );
        }
        return http.Response('Not found', 404);
      });

      final storageService = StorageService();
      final apiService = ApiService(
        client: mockClient,
        storageService: storageService,
      );
      final authService = AuthService(
        storageService: storageService,
        apiService: apiService,
      );

      isUserLoggedInNotifier.value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(authService: authService),
        ),
      );
      await tester.pump();

      // Enter registration details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'New User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'new@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      // Submit registration
      await tester.tap(find.text('Register'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verifies transition into WidgetTree, navigation history cleared, notifier updated
      expect(isUserLoggedInNotifier.value, isTrue);
      expect(find.byType(WidgetTree), findsOneWidget);
      expect(find.byType(RegisterPage), findsNothing);
    });
  });

  group('Global Auth & Token Guarding Tests', () {
    testWidgets('ApiService handles 401: deletes token, sets notifier false, and redirects to LoginPage',
        (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
        );
      });

      final storageService = StorageService();
      await storageService.saveToken('expired_or_invalid_token');
      expect(await storageService.hasToken(), isTrue);

      isUserLoggedInNotifier.value = true;

      final navKey = GlobalKey<NavigatorState>();
      final apiService = ApiService(
        client: mockClient,
        storageService: storageService,
        navigatorKey: navKey,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await apiService.get(Uri.parse('http://10.0.2.2/web-api/api/products'));
                },
                child: const Text('Fetch Products'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fetch Products'), findsOneWidget);

      // Trigger request that returns 401
      await tester.tap(find.text('Fetch Products'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Token deleted from storage
      expect(await storageService.getToken(), isNull);
      // Notifier set to false
      expect(isUserLoggedInNotifier.value, isFalse);
      // Redirected to LoginPage
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
