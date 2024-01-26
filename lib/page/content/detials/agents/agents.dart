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
          return AgentItemWidget(data: data[index]);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
        itemCount: data.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showSearch(
            context: context,
            delegate: MySearchDelegate(
              myList: data,
            ),
          );
        },
        icon: const Icon(Icons.search),
        label: const Text('搜尋'),
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

class AgentItemWidget extends StatelessWidget {
  const AgentItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: data['displayIconSmall'] != null
          ? Image.network(data['displayIconSmall'])
          : const Icon(Icons.question_mark),
      title: Hero(
        tag: Text(data['displayName']),
        child: Text(data['displayName']),
      ),
      trailing: Image.network(
        data['role']['displayIcon'],
        height: 20.0,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => AgentDetial(
              data: data,
            ),
          ),
        );
      },
    );
  }
}

class MySearchDelegate extends SearchDelegate {
  List myList;

  MySearchDelegate({
    required this.myList,
  });
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            onPressed: () {
              if (query.isEmpty) {
                close(context, null);
              } else {
                query = "";
              }
            },
            icon: const Icon(Icons.clear)),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => Center(
        child: Text(
          query,
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        ),
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    List suggestions = myList.where((searchResult) {
      final result = searchResult['displayName'];
      final input = query.toUpperCase();

      return result.contains(input);
    }).toList();
    return ListView.separated(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        var suggestion = suggestions[index];

        return AgentItemWidget(
          data: suggestion,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
  }
}
