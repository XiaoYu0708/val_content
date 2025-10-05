import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:val_content/page/auth_client.dart';
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
      body: [
        RiotLoginPage(),
        const Content(),
        const About(),
      ][_pageIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (value) {
          setState(() {
            _pageIndex = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: const Icon(Icons.account_circle),
            label: FlutterI18n.translate(
              context,
              "帳號",
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.ad_units_outlined),
            selectedIcon: const Icon(Icons.ad_units),
            label: FlutterI18n.translate(
              context,
              "Menu.destinations.label1",
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: FlutterI18n.translate(
              context,
              "Menu.destinations.label2",
            ),
          ),
        ],
      ),
    );
  }
}
