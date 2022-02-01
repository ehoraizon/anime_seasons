import 'dart:io';

import 'package:anime_seasons/components/anime_card.dart';
import 'package:anime_seasons/database/api.dart';
import 'package:anime_seasons/models/models.dart';
import 'package:flutter/material.dart';

class Favorite extends StatefulWidget {
  final ApiDB apiDB;

  const Favorite(this.apiDB, {Key? key}) : super(key: key);

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  final List<Anime> _favorites = [];

  @override
  void initState() {
    super.initState();

    widget.apiDB.getFavorites().listen((event) {
      setState(() {
        _favorites.add(event);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(builder: (context, constrains) {
      if (Platform.isWindows) {
        return GridView.count(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          crossAxisCount: (MediaQuery.of(context).size.width / 130).round(),
          // mainAxisSpacing: 3.0,
          // crossAxisSpacing: 2.0,
          childAspectRatio: 0.8,
          children: _favorites
              .map((anime) => AnimeCard(anime, widget.apiDB))
              .toList(),
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(top: 35),
          child: GridView.count(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            crossAxisCount: (MediaQuery.of(context).size.width / 130).round(),
            // mainAxisSpacing: 3.0,
            // crossAxisSpacing: 2.0,
            childAspectRatio: 0.8,
            children: _favorites
                .map((anime) => AnimeCard(anime, widget.apiDB))
                .toList(),
          ),
        );
      }
    }));
  }
}
