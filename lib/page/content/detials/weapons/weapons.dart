import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/page/content/detials/weapons/select_weapon_detial.dart';

class Weapons extends StatefulWidget {
  const Weapons({super.key});

  @override
  State<Weapons> createState() => _WeaponsState();
}

class _WeaponsState extends State<Weapons> {
  List<dynamic> data = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (BuildContext context, index) {
          return ListTile(
            leading: Image.network(
              data[index]['displayIcon'],
              width: 150,
            ),
            title: Text(data[index]['displayName']),
            trailing: const Icon(Icons.arrow_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => WeaponDetial(
                    data: data[index],
                  ),
                ),
              );
            },
          );
        },
        separatorBuilder: (BuildContext context, index) => const Divider(),
        itemCount: data.length,
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('https://valorant-api.com/v1/weapons?language=zh-TW'));

      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body)['data'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    fetchData();
    super.initState();
  }
}
