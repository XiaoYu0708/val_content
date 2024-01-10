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
              ? ListTile(
                  leading: Image.network(
                    data['skins'][index]['levels'][0]['displayIcon'],
                    width: 150,
                  ),
                  title: Text(
                    data['skins'][index]['displayName'],
                  ),
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(data['skins'][index]['displayName']),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                ...data['skins'][index]['chromas'].map((value) {
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
                )
              : const SizedBox();
        },
        separatorBuilder: (BuildContext context, index) =>
            data['skins'][index]['displayName'] != '隨機最愛造型' &&
                    !data['skins'][index]['displayName'].startsWith('標準')
                ? const Divider()
                : const SizedBox(),
        itemCount: data['skins'].length,
      ),
    );
  }
}
