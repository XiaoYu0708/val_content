import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class WeaponDetial extends StatefulWidget {
  final dynamic data;
  const WeaponDetial({
    super.key,
    required this.data,
  });

  @override
  State<WeaponDetial> createState() => _WeaponDetialState();
}

class _WeaponDetialState extends State<WeaponDetial> {
  late dynamic data = widget.data;
  String ddd = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data['displayName'])),
      body: ListView.separated(
        itemBuilder: (BuildContext context, index) {
          return data['skins'][index]['displayName'] !=
                      FlutterI18n.translate(
                          context, 'Page.WeaponDetial.dontDisPlay1') &&
                  !data['skins'][index]['displayName'].startsWith(
                      FlutterI18n.translate(
                          context, 'Page.WeaponDetial.dontDisPlay2'))
              ? SelectWeaponDetialItemWidget(data: data['skins'][index])
              : const SizedBox();
        },
        separatorBuilder: (BuildContext context, index) => data['skins'][index]
                        ['displayName'] !=
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay1') &&
                !data['skins'][index]['displayName'].startsWith(
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay2'))
            ? const Divider()
            : const SizedBox(),
        itemCount: data['skins'].length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showSearch(
            context: context,
            delegate: MySearchDelegate(
              myList: data['skins'],
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
}

class SelectWeaponDetialItemWidget extends StatelessWidget {
  const SelectWeaponDetialItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        data['levels'][0]['displayIcon'],
        width: 150,
      ),
      title: Text(
        data['displayName'],
      ),
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
                    ...data['chromas'].map((value) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(value['fullRender']),
                      );
                    }),
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
  Widget buildResults(BuildContext context) => Center(
        child: Text(
          query,
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        ),
      );

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
        return suggestions[index]['displayName'] !=
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay1') &&
                !suggestions[index]['displayName'].startsWith(
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay2'))
            ? SelectWeaponDetialItemWidget(
                data: suggestions[index],
              )
            : const SizedBox();
      },
      separatorBuilder: (BuildContext context, int index) {
        return suggestions[index]['displayName'] !=
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay1') &&
                !suggestions[index]['displayName'].startsWith(
                    FlutterI18n.translate(
                        context, 'Page.WeaponDetial.dontDisPlay2'))
            ? const Divider()
            : const SizedBox();
      },
    );
  }
}
