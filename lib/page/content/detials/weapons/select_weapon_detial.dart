import 'package:flutter/material.dart';

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
          return data['skins'][index]['displayName'] != '隨機最愛造型' &&
                  !data['skins'][index]['displayName'].startsWith('標準')
              ? SelectWeaponDetialItemWidget(data: data['skins'][index])
              : const SizedBox();
        },
        separatorBuilder: (BuildContext context, index) =>
            data['skins'][index]['displayName'] != '隨機最愛造型' &&
                    !data['skins'][index]['displayName'].startsWith('標準')
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
        label: const Text('搜尋'),
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
        return suggestions[index]['displayName'] != '隨機最愛造型' &&
                !suggestions[index]['displayName'].startsWith('標準')
            ? SelectWeaponDetialItemWidget(
                data: suggestions[index],
              )
            : const SizedBox();
      },
      separatorBuilder: (BuildContext context, int index) {
        return suggestions[index]['displayName'] != '隨機最愛造型' &&
                !suggestions[index]['displayName'].startsWith('標準')
            ? const Divider()
            : const SizedBox();
      },
    );
  }
}
