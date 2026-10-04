import 'package:flutter/material.dart';
import '../../data/notifiers.dart';
import '../../services/api_service.dart';
import '../pages/courses/index.dart';
import '../pages/students/index.dart';
import 'navbar_widget.dart';

class WidgetTree extends StatefulWidget {
  final ApiService? api;
  const WidgetTree({super.key, this.api});
  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  late final ApiService _api = widget.api ?? ApiService();
  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: selectedPageNotifier,
    builder: (context, index, child) => Scaffold(
      appBar: AppBar(
        title: Text(const ['Students', 'Courses'][index]),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isDarkModeNotifier,
            builder: (context, isDarkMode, child) => IconButton(
              tooltip: isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              onPressed: () {
                isDarkModeNotifier.value = !isDarkModeNotifier.value;
              },
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            ),
          ),
        ],
      ),
      body: [StudentPage(api: _api), CoursePage(api: _api)][index],
      bottomNavigationBar: const NavbarWidget(),
    ),
  );
}
