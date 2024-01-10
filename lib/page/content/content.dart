import 'package:flutter/material.dart';
import '/page/content/detials/level_borders.dart';
import '/page/content/detials/competitivetiers.dart';
import '/page/content/detials/agents/agents.dart';
import '/page/content/detials/buddies.dart';
import '/page/content/detials/bundles.dart';
import '/page/content/detials/maps.dart';
import '/page/content/detials/player_cards.dart';
import '/page/content/detials/sprays.dart';
import '/page/content/detials/weapons/weapons.dart';

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  int _drawerSelectIndex = 0;

  final List<MyDrawerNavigationDrawerDestinations>
      _myDrawerNavigationDrawerDestinations = [
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.person_outline),
      label: '特務',
      page: const Agents(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.radio_button_unchecked),
      label: '吊飾',
      page: const Buddies(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.grid_3x3),
      label: '組合包',
      page: const Bundles(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.crop_portrait_rounded),
      label: '武器',
      page: const Weapons(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.map_outlined),
      label: '地圖',
      page: const Maps(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.gamepad_outlined),
      label: '玩家卡面',
      page: const PlayerCards(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.format_paint_outlined),
      label: '噴漆',
      page: const Sprays(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.crop_square_rounded),
      label: '牌位',
      page: const Competitivetiers(),
    ),
    MyDrawerNavigationDrawerDestinations(
      icon: const Icon(Icons.star_border),
      label: '等級框飾',
      page: const LevelBorders(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text([
          ..._myDrawerNavigationDrawerDestinations
              .map((MyDrawerNavigationDrawerDestinations value) {
            return value.label;
          })
        ][_drawerSelectIndex]),
      ),
      body: [
        ..._myDrawerNavigationDrawerDestinations
            .map((MyDrawerNavigationDrawerDestinations value) {
          return value.page;
        })
      ][_drawerSelectIndex],
      drawer: NavigationDrawer(
        selectedIndex: _drawerSelectIndex,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              top: 12.0,
              bottom: 12.0,
            ),
            child: Text(
              '選單',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
          ..._myDrawerNavigationDrawerDestinations
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
