import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/notifiers.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'views/pages/auth/login_page.dart';
import 'views/pages/auth/register_page.dart';
import 'views/widgets/widget_tree.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  final String? token = await StorageService().getToken();
  final bool hasToken = token != null && token.isNotEmpty;
  isUserLoggedInNotifier.value = hasToken;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey ?? rootNavigatorKey,
      title: 'Mobile API Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const WidgetTree(),
      },
      home: ValueListenableBuilder<bool>(
        valueListenable: isUserLoggedInNotifier,
        builder: (context, isLoggedIn, child) {
          if (isLoggedIn) {
            return const WidgetTree();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
