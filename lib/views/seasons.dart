import 'dart:io';

import 'package:anime_seasons/components/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:animated_floating_buttons/animated_floating_buttons.dart';

import '../database/api.dart';
import '../models/models.dart';

class SeasonView extends StatefulWidget {
  final ApiDB apiDB;
  const SeasonView(this.apiDB, {Key? key}) : super(key: key);

  @override
  _SeasonViewState createState() => _SeasonViewState();
}

class _SeasonViewState extends State<SeasonView> {
  final Map<int, Map<Season, List<Anime>>> _seasonAnime = {};
  final ScrollController _controller = ScrollController();
  final ScrollController _controllerYear = ScrollController();
  DateTime today = DateTime.now();
  Cordinates _cordinates = Cordinates(Season.winter, DateTime.now().year);
  int _selected = 0;

  void addSeason() async {
    if (_seasonAnime[_cordinates.year] == null ||
        _seasonAnime[_cordinates.year]?[_cordinates.season] == null) {
      _seasonAnime[_cordinates.year] = {_cordinates.season: <Anime>[]};
      var cordinatesCopy = _cordinates.clone();
      widget.apiDB
          .getSeason(cordinatesCopy.year, cordinatesCopy.season)
          .listen((event) {
        if (mounted) {
          setState(() {
            List<Anime>? seasonAnimes =
                _seasonAnime[cordinatesCopy.year]?[cordinatesCopy.season];
            if (seasonAnimes != null) {
              _seasonAnime[cordinatesCopy.year]?[cordinatesCopy.season] =
                  List.from(seasonAnimes)..add(event);
            }
          });
        }
      });
    }
  }

  void updateSeason(Season season) {
    if (mounted) {
      setState(() {
        _cordinates = Cordinates(season, _cordinates.year);
        addSeason();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    addSeason();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _controllerYear.dispose();
  }

  List<Widget> getFloatinActions() {
    return <Widget>[
      FloatingActionButton(
        onPressed: () => updateSeason(Season.winter),
        heroTag: "winter",
        tooltip: 'Winter',
        child: const Icon(Icons.ac_unit),
      ),
      FloatingActionButton(
        onPressed: () => updateSeason(Season.spring),
        heroTag: "spring",
        tooltip: 'Spring',
        child: const Icon(Icons.local_florist),
      ),
      FloatingActionButton(
        onPressed: () => updateSeason(Season.summer),
        heroTag: "summer",
        tooltip: 'Summer',
        child: const Icon(Icons.wb_sunny),
      ),
      FloatingActionButton(
        onPressed: () => updateSeason(Season.fall),
        heroTag: "fall",
        tooltip: 'Fall',
        child: const Icon(Icons.air),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedFloatingActionButton(
          //Fab list
          fabButtons: getFloatinActions(),
          colorStartAnimation: Colors.blue,
          colorEndAnimation: Colors.red,
          animatedIconData: AnimatedIcons.menu_close),
      body: Column(
        children: [
          LayoutBuilder(builder: (context, constrains) {
            if (constrains.maxWidth > 400 || Platform.isWindows) {
              return SizedBox(
                // Container
                height: 43,
                width: 400,
                child: Scrollbar(
                  isAlwaysShown: true,
                  controller: _controllerYear,
                  child: ListView.builder(
                    controller: _controllerYear,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 20),
                    itemCount: 10,
                    itemBuilder: (context, index) => TextButton(
                        style: ButtonStyle(
                          backgroundColor: _selected == index
                              ? MaterialStateProperty.all<Color>(
                                  Colors.grey[300]!)
                              : MaterialStateProperty.all<Color>(Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            _selected = index;
                            _cordinates = Cordinates(
                                _cordinates.season, today.year - index);
                            addSeason();
                          });
                        },
                        child: Text(
                          "${today.year - index}",
                          style: TextStyle(
                              fontSize: 25,
                              color: _selected == index
                                  ? Colors.blue
                                  : Colors.black),
                        )),
                  ),
                ),
              );
            } else {
              return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black12,
                        width: 3.0,
                      ),
                    ),
                  ),
                  margin: const EdgeInsets.only(top: 35),
                  height: 43,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 20),
                    itemCount: 10,
                    itemBuilder: (context, index) => TextButton(
                        style: ButtonStyle(
                          backgroundColor: _selected == index
                              ? MaterialStateProperty.all<Color>(
                                  Colors.grey[300]!)
                              : MaterialStateProperty.all<Color>(Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            _selected = index;
                            _cordinates = Cordinates(
                                _cordinates.season, today.year - index);
                            addSeason();
                          });
                        },
                        child: Text(
                          "${today.year - index}",
                          style: TextStyle(
                              fontSize: 25,
                              color: _selected == index
                                  ? Colors.blue
                                  : Colors.black),
                        )),
                  ));
            }
          }),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 100,
              child: GridView.count(
                controller: _controller,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                crossAxisCount:
                    (MediaQuery.of(context).size.width / 130).round(),
                // mainAxisSpacing: 3.0,
                // crossAxisSpacing: 2.0,
                childAspectRatio:
                    MediaQuery.of(context).size.width < 400 ? 0.8 : 0.7,
                children: (_seasonAnime[_cordinates.year]?[_cordinates.season]
                        as List<Anime>)
                    .map((anime) => AnimeCard(anime, widget.apiDB))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
