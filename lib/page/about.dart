import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
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
        title: Text(FlutterI18n.translate(context, 'Page.About.AppBar.Title')),
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
                title: const Text('API'),
                subtitle: const Text('Valorant API Docs'),
                trailing: const Icon(Icons.link),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'https://valapidocs.techchrism.me/',
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
                title: Text(FlutterI18n.translate(
                    context, 'Page.About.Body.ListTile2.Title')),
                subtitle: const Text('E-mail'),
                trailing: const Icon(Icons.mail),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      FlutterI18n.translate(
                          context, 'Page.About.Body.ListTile2.onTap.launchUrl'),
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
                trailing: const Icon(Icons.link),
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
