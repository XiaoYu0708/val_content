import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LevelBorders extends StatefulWidget {
  const LevelBorders({super.key});

  @override
  State<LevelBorders> createState() => _LevelBordersState();
}

class _LevelBordersState extends State<LevelBorders> {
  List<dynamic> data = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (context, index) {
          return ListTile(
            leading: Image.network(data[index]['smallPlayerCardAppearance']),
            title: Text(data[index]['displayName']),
            trailing: Image.network(data[index]['levelNumberAppearance']),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: data.length,
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
          Uri.parse('https://valorant-api.com/v1/levelborders?language=zh-TW'));

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
