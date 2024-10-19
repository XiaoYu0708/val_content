import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;

class Buddies extends StatefulWidget {
  const Buddies({super.key});

  @override
  State<Buddies> createState() => _BuddiesState();
}

class _BuddiesState extends State<Buddies> {
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
          return BuddiesItemWidget(data: data[index]);
        },
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
        label: Text(
          FlutterI18n.translate(context, 'floatingActionButton.search.label'),
        ),
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse(FlutterI18n.translate(context, 'WebApiUrl.Buddies')));

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

class BuddiesItemWidget extends StatelessWidget {
  const BuddiesItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridTile(
          footer: Text(data['displayName']),
          child: data['displayIcon'] != null
              ? Image.network(data['displayIcon'])
              : const SizedBox(),
        ),
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
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    List suggestions = myList.where((searchResult) {
      final result = searchResult['displayName'].toLowerCase();
      final input = query.toLowerCase();

      return result.contains(input);
    }).toList();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        var suggestion = suggestions[index];

        return BuddiesItemWidget(
          data: suggestion,
        );
      },
    );
  }
}
