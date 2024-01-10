import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Competitivetiers extends StatefulWidget {
  const Competitivetiers({super.key});

  @override
  State<Competitivetiers> createState() => _CompetitivetiersState();
}

class _CompetitivetiersState extends State<Competitivetiers> {
  List<dynamic> data = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (context, index) {
          return data[data.length - 1]['tiers'][index]['smallIcon'] != null
              ? ListTile(
                  title:
                      Text(data[data.length - 1]['tiers'][index]['tierName']),
                  leading: Image.network(
                    data[data.length - 1]['tiers'][index]['smallIcon'],
                  ),
                )
              : const SizedBox();
        },
        separatorBuilder: (context, index) =>
            data[data.length - 1]['tiers'][index]['smallIcon'] != null
                ? const Divider()
                : const SizedBox(),
        itemCount: data.isNotEmpty ? data[data.length - 1]['tiers'].length : 0,
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://valorant-api.com/v1/competitivetiers?language=zh-TW'));

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
