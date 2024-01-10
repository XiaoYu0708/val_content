import 'package:flutter/material.dart';

class AgentDetial extends StatefulWidget {
  final dynamic data;
  const AgentDetial({
    super.key,
    required this.data,
  });

  @override
  State<AgentDetial> createState() => _AgentDetialState();
}

class _AgentDetialState extends State<AgentDetial> {
  late dynamic data = widget.data;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            data['role']['displayIcon'] != null
                ? Image.network(
                    data['role']['displayIcon'],
                    height: 20.0,
                  )
                : const Icon(Icons.question_mark),
            const SizedBox(
              width: 10.0,
            ),
            Hero(
              tag: Text(data['displayName']),
              child: Text(data['displayName']),
            ),
            const SizedBox(
              width: 10.0,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  data['fullPortraitV2'] != null
                      ? Image.network(
                          data['fullPortraitV2'],
                        )
                      : const Icon(Icons.question_mark),
                  Text(data['description'])
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Image.network(data['role']['displayIcon']),
              title: Text(data['role']['displayName']),
              subtitle: Text(data['role']['description']),
            ),
          ),
          ...data['abilities'].map(
            (value) {
              return Card(
                child: ListTile(
                  leading: value['displayIcon'] != null
                      ? Image.network(value['displayIcon'])
                      : const Icon(Icons.question_mark),
                  title: Text('${value['displayName']}(${value['slot']})'),
                  subtitle: Text(value['description']),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
