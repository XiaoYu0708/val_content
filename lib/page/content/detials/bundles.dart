import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Bundles extends StatefulWidget {
  const Bundles({super.key});

  @override
  State<Bundles> createState() => _BundlesState();
}

class _BundlesState extends State<Bundles> {
  List<dynamic> data = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: data[index]['displayIcon'] != null
                ? Image.network(data[index]['displayIcon'])
                : const Icon(Icons.question_mark),
            title: Text(data[index]['displayName']),
            trailing: const Icon(Icons.arrow_right),
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(data[index]['displayName']),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Image.network(
                            data[index]['displayIcon'],
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('關閉'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
        itemCount: data.length,
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('https://valorant-api.com/v1/bundles?language=zh-TW'));

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
