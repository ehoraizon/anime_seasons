import 'package:anime_seasons/models/models.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnimePlayer extends StatefulWidget {
  final Episode episode;

  const AnimePlayer(this.episode, {Key? key}) : super(key: key);

  @override
  _AnimePlayerState createState() => _AnimePlayerState();
}

class _AnimePlayerState extends State<AnimePlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        widget.episode.directLink.toString(),
        httpHeaders: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:95.0) Gecko/20100101 Firefox/95.0"
        })
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          _chewieController = ChewieController(
              videoPlayerController: _controller!, autoPlay: true);
        });
      });
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
        body: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : SizedBox());
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
