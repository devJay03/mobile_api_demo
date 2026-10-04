import 'package:flutter/material.dart';
import '../../data/notifiers.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: selectedPageNotifier,
    builder: (context, index, child) => NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => selectedPageNotifier.value = value,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Students',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          label: 'Courses',
        ),
      ],
    ),
  );
}
