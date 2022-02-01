import 'package:anime_seasons/database/api.dart';
import 'package:anime_seasons/models/models.dart';
import 'package:anime_seasons/views/anime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:rive/rive.dart';

class AnimeCard extends StatefulWidget {
  final ApiDB apiDB;
  final Anime anime;

  const AnimeCard(this.anime, this.apiDB, {Key? key}) : super(key: key);

  @override
  _AnimeCardState createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  SMIInput<bool>? _levelInput;

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Load the animation file from the bundle, note that you could also
    // download this. The RiveFile just expects a list of bytes.
    rootBundle.load("assets/animations/heart.riv").then(
      (data) async {
        // Load the RiveFile from the binary data.
        final file = RiveFile.import(data);

        // The artboard is the root of the animation and gets drawn in the
        // Rive widget.
        final artboard = file.mainArtboard;
        _controller =
            StateMachineController.fromArtboard(artboard, 'State Machine 1');
        if (_controller != null) {
          artboard.addController(_controller!);
          _levelInput = _controller!.inputs.first as SMIInput<bool>;
          if (widget.anime.favorite) {
            _levelInput!.value = true;
          } else {
            _levelInput!.value = false;
          }
        }
        if (mounted) {
          setState(() => _riveArtboard = artboard);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        LayoutBuilder(builder: (context, constrains) {
          if (constrains.maxWidth > 120) {
            return GestureDetector(
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        AnimeView(widget.anime, widget.apiDB),
                  ),
                );
              },
              child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Card(
                    // margin: EdgeInsets.all(value)
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    elevation: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                          width: 120,
                          height: 155,
                          child: Image.memory(widget.anime.image,
                              fit: BoxFit.cover)),
                    ),
                  )),
            );
          } else {
            return GestureDetector(
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          AnimeView(widget.anime, widget.apiDB),
                    ),
                  );
                },
                child: Card(
                  // margin: EdgeInsets.all(value)
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  elevation: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                        width: 100,
                        height: 135,
                        child: Image.memory(widget.anime.image,
                            fit: BoxFit.cover)),
                  ),
                ));
          }
        }),
        if (_riveArtboard != null)
          Transform(
            transform: MediaQuery.of(context).size.width < 400
                ? Matrix4.translation(vector.Vector3(30, 50, 0))
                : Matrix4.translation(vector.Vector3(30, 60, 0)),
            child: SizedBox(
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _levelInput!.value = !_levelInput!.value;
                  widget.anime.favorite = _levelInput!.value;
                  widget.apiDB.toogleFavorite(widget.anime);
                },
                child: Rive(
                  artboard: _riveArtboard!,
                ),
              ),
            ),
          )
      ],
    );
  }
}
