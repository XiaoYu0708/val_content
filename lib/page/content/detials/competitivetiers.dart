import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
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
              ? CompetitivetierItemWidget(
                  data: data[data.length - 1]['tiers'][index])
              : const SizedBox();
        },
        separatorBuilder: (context, index) =>
            data[data.length - 1]['tiers'][index]['smallIcon'] != null
                ? const Divider()
                : const SizedBox(),
        itemCount: data.isNotEmpty ? data[data.length - 1]['tiers'].length : 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showSearch(
            context: context,
            delegate: MySearchDelegate(
              myList: data[data.length - 1]['tiers'],
            ),
          );
        },
        icon: const Icon(Icons.search),
        label: Text(
          FlutterI18n.translate(context, 'floatingActionButton.search.label'),
        ),
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          FlutterI18n.translate(context, 'WebApiUrl.Competitivetiers'),
        ),
      );

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
  void didChangeDependencies() {
    fetchData();
    super.didChangeDependencies();
  }
}

class CompetitivetierItemWidget extends StatelessWidget {
  const CompetitivetierItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(data['tierName']),
      leading: Image.network(
        data['smallIcon'],
      ),
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
      final result = searchResult['tierName'].toLowerCase();
      final input = query.toLowerCase();

      return result.contains(input);
    }).toList();
    return ListView.separated(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return suggestions[index]['smallIcon'] != null
            ? CompetitivetierItemWidget(
                data: suggestions[index],
              )
            : const SizedBox();
      },
      separatorBuilder: (BuildContext context, int index) {
        return suggestions[index]['smallIcon'] != null
            ? const Divider()
            : const SizedBox();
      },
    );
  }
}
