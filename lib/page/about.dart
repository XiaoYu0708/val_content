import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('關於'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('API'),
                subtitle: const Text('Valorant-API'),
                trailing: const Icon(Icons.link),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'https://dash.valorant-api.com/',
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('回饋及建議'),
                subtitle: const Text('E-mail'),
                trailing: const Icon(Icons.mail),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'mailto:weitsungyu@gmail.com?subject=關於 val_content app 的回饋及建議&body=內容',
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('About'),
                subtitle: const Text(
                  'val_content is not affiliated with or endorsed by Riot Games in any way.',
                ),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'https://playvalorant.com/',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
