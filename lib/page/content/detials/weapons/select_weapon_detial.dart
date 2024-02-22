import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:video_player/video_player.dart';

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

class SelectWeaponDetialItemWidget extends StatefulWidget {
  const SelectWeaponDetialItemWidget({
    super.key,
    required this.data,
  });

  final dynamic data;

  @override
  State<SelectWeaponDetialItemWidget> createState() =>
      _SelectWeaponDetialItemWidgetState();
}

class _SelectWeaponDetialItemWidgetState
    extends State<SelectWeaponDetialItemWidget> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        widget.data['chromas'][0]['fullRender'],
        width: 150,
      ),
      title: Text(
        widget.data['displayName'],
      ),
      onTap: () {
        final PageController pageViewController =
            PageController(initialPage: 0);
        int chromasMaxIndex = widget.data['chromas'].length;
        VideoPlayerController _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(
                'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'));
        ValueNotifier _initializeVideoPlayerFuture = ValueNotifier(dynamic);

        _initializeVideoPlayerFuture.value =
            _videoPlayerController.initialize().then((_) {
          _videoPlayerController.play();
          _videoPlayerController.setLooping(false);
          setState(() {});
        });
        showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(widget.data['displayName']),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: PageView(
                        controller: pageViewController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...widget.data['chromas'].map((value) {
                            return Image.network(value['fullRender']);
                          }),
                          ValueListenableBuilder(
                            valueListenable: _initializeVideoPlayerFuture,
                            builder:
                                (BuildContext context, value, Widget? child) {
                              return FutureBuilder(
                                future: value,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    return AspectRatio(
                                      aspectRatio: _videoPlayerController
                                          .value.aspectRatio,
                                      child:
                                          VideoPlayer(_videoPlayerController),
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...widget.data['chromas'].map((value) {
                            return value['streamedVideo'] == null
                                ? ElevatedButton(
                                    onPressed: () {
                                      _videoPlayerController.dispose();
                                      pageViewController.jumpToPage(widget
                                          .data['chromas']
                                          .indexOf(value));
                                    },
                                    child: Text(
                                        "${widget.data['chromas'].indexOf(value) + 1}"))
                                : Card(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        pageViewController
                                            .jumpToPage(chromasMaxIndex);

                                        _videoPlayerController.dispose();

                                        _videoPlayerController =
                                            VideoPlayerController.networkUrl(
                                                Uri.parse(
                                                    value['streamedVideo']));
                                        _initializeVideoPlayerFuture.value =
                                            _videoPlayerController
                                                .initialize()
                                                .then((_) {
                                          _videoPlayerController.play();
                                          _videoPlayerController
                                              .setLooping(false);
                                          setState(() {});
                                        });
                                      },
                                      child: Text(
                                          "${widget.data['chromas'].indexOf(value) + 1}"),
                                    ),
                                  );
                          })
                        ],
                      ),
                    ),
                    ...widget.data['levels'].map((value) {
                      return value['streamedVideo'] != null
                          ? Card(
                              child: ListTile(
                                onTap: () {
                                  pageViewController
                                      .jumpToPage(chromasMaxIndex);

                                  _videoPlayerController.dispose();

                                  _videoPlayerController =
                                      VideoPlayerController.networkUrl(
                                          Uri.parse(value['streamedVideo']));
                                  _initializeVideoPlayerFuture.value =
                                      _videoPlayerController
                                          .initialize()
                                          .then((_) {
                                    _videoPlayerController.play();
                                    _videoPlayerController.setLooping(false);
                                    setState(() {});
                                  });
                                },
                                title: Text(value['displayName']),
                              ),
                            )
                          : const SizedBox();
                    })
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(FlutterI18n.translate(
                      context, 'AlertDialog.actions.close')),
                  onPressed: () {
                    _videoPlayerController.dispose();
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
