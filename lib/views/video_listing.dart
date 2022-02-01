import 'dart:io';

import 'package:anime_seasons/components/anime_player.dart';
import 'package:anime_seasons/components/anime_player_desktop.dart';
import 'package:anime_seasons/database/api.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

class VideoListing extends StatefulWidget {
  final Anime anime;
  final ApiDB apiDB;

  const VideoListing(this.anime, this.apiDB, {Key? key}) : super(key: key);

  @override
  _VideoListingState createState() => _VideoListingState();
}

class _VideoListingState extends State<VideoListing> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount: widget.anime.episodes.length,
          itemBuilder: (BuildContext context, int index) => GestureDetector(
            onTap: () async {
              if (widget.anime.episodes[index].directLink == null) {
                // await widget.apiDB
                //     .getDirectVideoLink(widget.anime.episodes[index]);
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      widget.apiDB
                          .getDirectVideoLink(
                              widget.anime.id, widget.anime.episodes[index])
                          .then((value) {
                        Navigator.pop(context);
                        if (widget.anime.episodes[index].directLink != null) {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => Platform
                                      .isAndroid
                                  ? AnimePlayer(widget.anime.episodes[index])
                                  : AnimePlayerDesktop(
                                      widget.anime.episodes[index]),
                            ),
                          );
                        }
                      });
                      return SimpleDialog(
                        title: const Text('Loading direct link...'),
                        children: <Widget>[
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding:
                                      EdgeInsets.only(top: 15.0, bottom: 15.0),
                                  child: CircularProgressIndicator(
                                    semanticsLabel: 'Linear progress indicator',
                                  ),
                                ),
                              ]),
                        ],
                      );
                    });
              } else {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        AnimePlayer(widget.anime.episodes[index]),
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                    child: Image.memory(
                      widget.anime.image,
                      fit: BoxFit.contain,
                      height: 100,
                    )),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: Text(
                    widget.anime.episodes[index].name,
                    style: const TextStyle(fontSize: 20),
                  ),
                )
              ],
            ),
          ),
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        ));
  }
}
