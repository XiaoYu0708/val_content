import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import '/page/content/details/level_borders.dart';
import '/page/content/details/competitivetiers.dart';
import '/page/content/details/agents/agents.dart';
import '/page/content/details/buddies.dart';
import '/page/content/details/bundles.dart';
import '/page/content/details/maps.dart';
import '/page/content/details/player_cards.dart';
import '/page/content/details/sprays.dart';
import '/page/content/details/weapons/weapons.dart';

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  int _drawerSelectIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<MyDrawerNavigationDrawerDestinations>
        myDrawerNavigationDrawerDestinations = [
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.person_outline),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Agents'),
        page: const Agents(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.radio_button_unchecked),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Buddies'),
        page: const Buddies(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.grid_3x3),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Bundles'),
        page: const Bundles(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.crop_portrait_rounded),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Weapons'),
        page: const Weapons(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.map_outlined),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Maps'),
        page: const Maps(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.gamepad_outlined),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.PlayerCards'),
        page: const PlayerCards(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.format_paint_outlined),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Sprays'),
        page: const Sprays(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.crop_square_rounded),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.Competitivetiers'),
        page: const Competitivetiers(),
      ),
      MyDrawerNavigationDrawerDestinations(
        icon: const Icon(Icons.star_border),
        label: FlutterI18n.translate(context,
            'Page.Content.NavigationDrawer.NavigationDrawerDestinations.LevelBorders'),
        page: const LevelBorders(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text([
          ...myDrawerNavigationDrawerDestinations
              .map((MyDrawerNavigationDrawerDestinations value) {
            return value.label;
          })
        ][_drawerSelectIndex]),
      ),
      body: [
        ...myDrawerNavigationDrawerDestinations
            .map((MyDrawerNavigationDrawerDestinations value) {
          return value.page;
        })
      ][_drawerSelectIndex],
      drawer: NavigationDrawer(
        selectedIndex: _drawerSelectIndex,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 12.0,
              bottom: 12.0,
            ),
            child: Text(
              FlutterI18n.translate(
                  context, 'Page.Content.NavigationDrawer.Title'),
              style: const TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
          ...myDrawerNavigationDrawerDestinations
              .map((MyDrawerNavigationDrawerDestinations value) {
            return NavigationDrawerDestination(
              label: Text(value.label),
              icon: value.icon,
            );
          }),
        ],
        onDestinationSelected: (value) {
          setState(() {
            _drawerSelectIndex = value;
            Navigator.pop(context);
          });
        },
      ),
    );
  }
}

class MyDrawerNavigationDrawerDestinations {
  Icon icon;
  String label;
  Widget page;

  MyDrawerNavigationDrawerDestinations({
    required this.icon,
    required this.label,
    required this.page,
  });
}
