import 'dart:typed_data';

import 'package:anime_seasons/database/api.dart';
import 'package:badges/badges.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../components/info_accordion.dart';
import 'video_listing.dart';

import 'package:carousel_slider/carousel_slider.dart';

class AnimeView extends StatefulWidget {
  final Anime anime;
  final ApiDB apiDB;

  const AnimeView(this.anime, this.apiDB, {Key? key}) : super(key: key);

  @override
  _AnimeViewState createState() => _AnimeViewState();
}

class _AnimeViewState extends State<AnimeView> with TickerProviderStateMixin {
  List<Uint8List?> _pictures = [];
  double _currentPicture = 0;
  final TextStyle _noramlBoldText = const TextStyle(
      fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold);
  Widget? _accordionInfo;
  // bool _cancel = false;

  List<Widget> getSliderImages() {
    return _pictures
        .map((element) => Container(
              margin: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                elevation: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  child: Image.memory(element!, fit: BoxFit.contain),
                ),
              ),
            ))
        .toList();
  }

  Future<void> getAnimeDetails() async {
    if (widget.anime.reviews.isEmpty) {
      widget.apiDB.getReviews(widget.anime.id, 1).listen(
        (event) {
          widget.anime.reviews.add(event!);
        },
        onDone: () {
          _accordionInfo = InfoAccordion(widget.anime);
        },
      );
    }
    await widget.apiDB.getAnimeDetails(widget.anime);
  }

  @override
  void initState() {
    _pictures.add(widget.anime.image);
    _pictures.addAll(widget.anime.pictures);
    widget.apiDB.getPicturesFromAnime(widget.anime.id).listen((event) {
      bool save = true;
      for (Uint8List? picture in _pictures) {
        if (picture?.length != event?.length) continue;
        bool equals = true;
        for (int i = 0; i < picture!.length; i++) {
          if (picture[i] != event![i]) {
            equals = false;
            break;
          }
        }
        if (equals) {
          save = false;
          break;
        }
      }

      if (save) {
        setState(() {
          _pictures = List.from(_pictures)..add(event);
          widget.anime.pictures.add(event);
        });
      }
    });
    getAnimeDetails()
        .then((value) => _accordionInfo = InfoAccordion(widget.anime));
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
      body: Container(
        alignment: AlignmentDirectional.topCenter,
        margin: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, constrains) {
          if (constrains.maxWidth > 800) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    // margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                    // width: MediaQuery.of(context).size.width / 1.3,
                    // height: MediaQuery.of(context).size.height / 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            overflow: Overflow.visible,
                            children: [
                              CarouselSlider(
                                  options: CarouselOptions(
                                    viewportFraction: 0.7,
                                    aspectRatio: 1.0,
                                    enlargeCenterPage: true,
                                    autoPlay: true,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentPicture = index.toDouble();
                                      });
                                    },
                                  ),
                                  items: getSliderImages()),
                              Positioned(
                                  bottom: -10,
                                  right: -10,
                                  child: Container(
                                    decoration: const ShapeDecoration(
                                      color: Colors.blue,
                                      shape: CircleBorder(),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                          Icons.video_collection_rounded,
                                          color: Colors.white),
                                      onPressed: () {
                                        if (widget.anime.episodes.isEmpty) {
                                          showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                widget.apiDB
                                                    .getListEpisodes(
                                                        widget.anime)
                                                    .then((value) {
                                                  Navigator.pop(context);
                                                  if (widget.anime.episodes
                                                      .isNotEmpty) {
                                                    Navigator.push<void>(
                                                      context,
                                                      MaterialPageRoute<void>(
                                                        builder: (BuildContext
                                                                context) =>
                                                            VideoListing(
                                                                widget.anime,
                                                                widget.apiDB),
                                                      ),
                                                    );
                                                  }
                                                  // } else if (_cancel) {
                                                  //   setState(() {
                                                  //     _cancel = false;
                                                  //   });
                                                  // }
                                                });
                                                return SimpleDialog(
                                                  title: const Text(
                                                      'Loading chapter list...'),
                                                  children: <Widget>[
                                                    Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: const [
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 15.0,
                                                                    bottom:
                                                                        15.0),
                                                            child:
                                                                CircularProgressIndicator(
                                                              // value: _controller.value,
                                                              semanticsLabel:
                                                                  'Linear progress indicator',
                                                            ),
                                                          ),
                                                        ]),
                                                    // SimpleDialogOption(
                                                    //   onPressed: () {
                                                    //     setState(() {
                                                    //       _cancel = true;
                                                    //     });
                                                    //     Navigator.pop(context);
                                                    //   },
                                                    //   child: const Text('Cancel'),
                                                    // )
                                                  ],
                                                );
                                              });
                                        } else {
                                          Navigator.push<void>(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (BuildContext context) =>
                                                  VideoListing(widget.anime,
                                                      widget.apiDB),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        DotsIndicator(
                          dotsCount: _pictures.length,
                          position: _currentPicture,
                          decorator: DotsDecorator(
                            size: const Size.square(9.0),
                            activeSize: const Size(18.0, 9.0),
                            activeShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Column(
                            children: [
                              Text(
                                widget.anime.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const Divider(
                                height: 20,
                                thickness: 1.0,
                              ),
                              if (widget.anime.rating != null)
                                RichText(
                                  text: TextSpan(
                                      text: "Rating : ",
                                      style: _noramlBoldText,
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: widget.anime.rating,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.normal)),
                                      ]),
                                ),
                              if (widget.anime.status != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: RichText(
                                      text: TextSpan(
                                    text: "Status : ",
                                    style: _noramlBoldText,
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: widget.anime.status,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.normal))
                                    ],
                                  )),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 1.3,
                                  child: Table(
                                    defaultColumnWidth:
                                        const FlexColumnWidth(1.0),
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      TableRow(children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0, top: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text("Rank  ",
                                                  style: _noramlBoldText),
                                              Badge(
                                                toAnimate: false,
                                                shape: BadgeShape.square,
                                                badgeColor: Colors.deepPurple,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                badgeContent: Text(
                                                    widget.anime.rank
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0, top: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text("Score  ",
                                                  style: _noramlBoldText),
                                              Badge(
                                                toAnimate: false,
                                                shape: BadgeShape.square,
                                                badgeColor: Colors.deepPurple,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                badgeContent: Text(
                                                    widget.anime.score
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]),
                                      TableRow(children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text("Episodes  ",
                                                style: _noramlBoldText),
                                            Badge(
                                              toAnimate: false,
                                              shape: BadgeShape.square,
                                              badgeColor: Colors.deepPurple,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              badgeContent: Text(
                                                  widget.anime.episodesN
                                                      .toString(),
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text("Airing   ",
                                                style: _noramlBoldText),
                                            Badge(
                                              toAnimate: false,
                                              shape: BadgeShape.square,
                                              badgeColor: Colors.deepPurple,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              badgeContent: Text(
                                                  widget.anime.airing != null &&
                                                          widget.anime.airing!
                                                      ? "Yes"
                                                      : "No",
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ])
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_accordionInfo != null)
                            _accordionInfo!
                          else
                            const Padding(
                              padding: EdgeInsets.all(35.0),
                              child: LinearProgressIndicator(),
                            )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: MediaQuery.of(context).size.height / 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            overflow: Overflow.visible,
                            children: [
                              CarouselSlider(
                                  options: CarouselOptions(
                                    viewportFraction: 0.7,
                                    aspectRatio: 1.0,
                                    enlargeCenterPage: true,
                                    autoPlay: true,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentPicture = index.toDouble();
                                      });
                                    },
                                  ),
                                  items: getSliderImages()),
                              Positioned(
                                  bottom: -10,
                                  right: -10,
                                  child: Container(
                                    decoration: const ShapeDecoration(
                                      color: Colors.blue,
                                      shape: CircleBorder(),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                          Icons.video_collection_rounded,
                                          color: Colors.white),
                                      onPressed: () {
                                        if (widget.anime.episodes.isEmpty) {
                                          showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                widget.apiDB
                                                    .getListEpisodes(
                                                        widget.anime)
                                                    .then((value) {
                                                  Navigator.pop(context);
                                                  if (widget.anime.episodes
                                                      .isNotEmpty) {
                                                    Navigator.push<void>(
                                                      context,
                                                      MaterialPageRoute<void>(
                                                        builder: (BuildContext
                                                                context) =>
                                                            VideoListing(
                                                                widget.anime,
                                                                widget.apiDB),
                                                      ),
                                                    );
                                                  }
                                                  // } else if (_cancel) {
                                                  //   setState(() {
                                                  //     _cancel = false;
                                                  //   });
                                                  // }
                                                });
                                                return SimpleDialog(
                                                  title: const Text(
                                                      'Loading chapter list...'),
                                                  children: <Widget>[
                                                    Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: const [
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 15.0,
                                                                    bottom:
                                                                        15.0),
                                                            child:
                                                                CircularProgressIndicator(
                                                              // value: _controller.value,
                                                              semanticsLabel:
                                                                  'Linear progress indicator',
                                                            ),
                                                          ),
                                                        ]),
                                                    // SimpleDialogOption(
                                                    //   onPressed: () {
                                                    //     setState(() {
                                                    //       _cancel = true;
                                                    //     });
                                                    //     Navigator.pop(context);
                                                    //   },
                                                    //   child: const Text('Cancel'),
                                                    // )
                                                  ],
                                                );
                                              });
                                        } else {
                                          Navigator.push<void>(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (BuildContext context) =>
                                                  VideoListing(widget.anime,
                                                      widget.apiDB),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        DotsIndicator(
                          dotsCount: _pictures.length,
                          position: _currentPicture,
                          decorator: DotsDecorator(
                            size: const Size.square(9.0),
                            activeSize: const Size(18.0, 9.0),
                            activeShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ),
                        )
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.anime.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const Divider(
                        height: 20,
                        thickness: 1.0,
                      ),
                      if (widget.anime.rating != null)
                        RichText(
                          text: TextSpan(
                              text: "Rating : ",
                              style: _noramlBoldText,
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.anime.rating,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.normal)),
                              ]),
                        ),
                      if (widget.anime.status != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: RichText(
                              text: TextSpan(
                            text: "Status : ",
                            style: _noramlBoldText,
                            children: <TextSpan>[
                              TextSpan(
                                  text: widget.anime.status,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal))
                            ],
                          )),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 1.3,
                          child: Table(
                            defaultColumnWidth: const FlexColumnWidth(1.0),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8.0, top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Rank  ", style: _noramlBoldText),
                                      Badge(
                                        toAnimate: false,
                                        shape: BadgeShape.square,
                                        badgeColor: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(8),
                                        badgeContent: Text(
                                            widget.anime.rank.toString(),
                                            style: const TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8.0, top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Score  ", style: _noramlBoldText),
                                      Badge(
                                        toAnimate: false,
                                        shape: BadgeShape.square,
                                        badgeColor: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(8),
                                        badgeContent: Text(
                                            widget.anime.score.toString(),
                                            style: const TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                              TableRow(children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Episodes  ", style: _noramlBoldText),
                                    Badge(
                                      toAnimate: false,
                                      shape: BadgeShape.square,
                                      badgeColor: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(8),
                                      badgeContent: Text(
                                          widget.anime.episodesN.toString(),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Airing   ", style: _noramlBoldText),
                                    Badge(
                                      toAnimate: false,
                                      shape: BadgeShape.square,
                                      badgeColor: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(8),
                                      badgeContent: Text(
                                          widget.anime.airing != null &&
                                                  widget.anime.airing!
                                              ? "Yes"
                                              : "No",
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ])
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_accordionInfo != null)
                    _accordionInfo!
                  else
                    const Padding(
                      padding: EdgeInsets.all(35.0),
                      child: LinearProgressIndicator(),
                    )
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}
