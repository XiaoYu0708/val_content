import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;

class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  List<dynamic> data = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemBuilder: (BuildContext context, index) {
          return data[index]['displayIcon'] != null
              ? MapItemWidget(data: data[index])
              : const SizedBox();
        },
        separatorBuilder: (BuildContext context, index) =>
            data[index]['displayIcon'] != null
                ? const Divider()
                : const SizedBox(),
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
        label: Text(FlutterI18n.translate(
            context, 'floatingActionButton.search.label')),
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          FlutterI18n.translate(context, 'WebApiUrl.Maps'),
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

class MapItemWidget extends StatelessWidget {
  const MapItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        data['listViewIcon'],
        width: 150,
      ),
      title: Text(data['displayName']),
      trailing: const Icon(Icons.arrow_right),
      onTap: () {
        showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(data['displayName']),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Image.network(
                      data['displayIcon'],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(FlutterI18n.translate(
                      context, 'AlertDialog.actions.close')),
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
    return ListView.separated(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return suggestions[index]['displayIcon'] != null
            ? MapItemWidget(
                data: suggestions[index],
              )
            : const SizedBox();
      },
      separatorBuilder: (BuildContext context, int index) {
        return suggestions[index]['displayIcon'] != null
            ? const Divider()
            : const SizedBox();
      },
    );
  }
}
