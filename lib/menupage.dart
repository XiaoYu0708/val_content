import 'package:flutter/material.dart';
import '/page/about.dart';
import '/page/content/content.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _pageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const [
        Content(),
        About(),
      ][_pageIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (value) {
          setState(() {
            _pageIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.ad_units_outlined),
              selectedIcon: Icon(Icons.ad_units),
              label: '資產'),
          NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: '關於'),
        ],
      ),
    );
  }
}
