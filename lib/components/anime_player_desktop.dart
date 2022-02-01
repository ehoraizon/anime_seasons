import 'package:anime_seasons/models/models.dart';
import 'package:flutter/material.dart';
import 'package:dart_vlc/dart_vlc.dart';

class AnimePlayerDesktop extends StatefulWidget {
  final Episode episode;

  const AnimePlayerDesktop(this.episode, {Key? key}) : super(key: key);

  @override
  _AnimePlayerDesktopState createState() => _AnimePlayerDesktopState();
}

class _AnimePlayerDesktopState extends State<AnimePlayerDesktop> {
  Player? _controller;

  @override
  void initState() {
    super.initState();
    _controller = Player(id: 69420);
    _controller!.setUserAgent(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:95.0) Gecko/20100101 Firefox/95.0");
    _controller!.open(Media.network(widget.episode.directLink!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.episode.name,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _controller != null
            ? Video(
                player: _controller,
                // height: 1920.0,
                // width: 1080.0,
                // scale: 1.0, // default
              )
            : SizedBox());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
