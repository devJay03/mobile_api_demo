import 'package:flutter/material.dart';
import '../../data/notifiers.dart';
import '../../services/auth_service.dart';
import '../pages/categories/category_page.dart';
import '../pages/products/product_list_page.dart';
import 'navbar_widget.dart';

class WidgetTree extends StatefulWidget {
  final AuthService? authService;

  const WidgetTree({super.key, this.authService});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  late final AuthService _authService;
  final List<Widget> _pages = const [
    ProductListPage(),
    CategoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedIndex, child) {
            return Text(selectedIndex == 0 ? 'Products' : 'Categories');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _authService.logout();
              } catch (_) {}
              isUserLoggedInNotifier.value = false;
              selectedPageNotifier.value = 0;
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedIndex, child) {
          return _pages[selectedIndex];
        },
      ),
      bottomNavigationBar: const NavbarWidget(),
    );
  }
}
