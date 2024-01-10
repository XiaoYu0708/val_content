import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Sprays extends StatefulWidget {
  const Sprays({super.key});

  @override
  State<Sprays> createState() => _SpraysState();
}

class _SpraysState extends State<Sprays> {
  List<dynamic> data = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        itemCount: data.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridTile(
                footer: Text(data[index]['displayName']),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.network(data[index]['animationGif'] ??
                      data[index]['fullTransparentIcon'] ??
                      data[index]['fullIcon'] ??
                      data[index]['displayIcon']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('https://valorant-api.com/v1/sprays?language=zh-TW'));

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
