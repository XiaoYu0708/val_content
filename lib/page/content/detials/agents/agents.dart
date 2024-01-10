import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/page/content/detials/agents/select_agent_detial.dart';

class Agents extends StatefulWidget {
  const Agents({super.key});

  @override
  State<Agents> createState() => _AgentsState();
}

class _AgentsState extends State<Agents> {
  List<dynamic> data = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: data[index]['displayIconSmall'] != null
                ? Image.network(data[index]['displayIconSmall'])
                : const Icon(Icons.question_mark),
            title: Hero(
              tag: Text(data[index]['displayName']),
              child: Text(data[index]['displayName']),
            ),
            trailing: Image.network(
              data[index]['role']['displayIcon'],
              height: 20.0,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => AgentDetial(
                    data: data[index],
                  ),
                ),
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
      final response = await http.get(Uri.parse(
          'https://valorant-api.com/v1/agents?isPlayableCharacter=true&language=zh-TW'));

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
