import 'dart:io';

import 'package:anime_seasons/components/anime_card.dart';
import 'package:anime_seasons/database/api.dart';
import 'package:anime_seasons/models/models.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final ApiDB apiDB;
  const Search(this.apiDB, {Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final ScrollController _controller = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Anime> _animes = [];
  String _title = "";
  String _searchedTitle = "";

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(builder: (context, constrains) {
      if (constrains.maxWidth > 400 || Platform.isWindows) {
        return SizedBox(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.4,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 10.0, left: 10, bottom: 2),
                          child: TextFormField(
                            onSaved: (String? value) {
                              _title = value!;
                            },
                            decoration: const InputDecoration(
                                hintText: 'Write an anime title!',
                                border: InputBorder.none),
                            validator: (String? value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  (value.isNotEmpty && value.length <= 3)) {
                                return 'Enter an anime title (3 characters up)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            if (_title != _searchedTitle) {
                              setState(() {
                                _animes = [];
                                _searchedTitle = _title;
                              });
                              widget.apiDB.search(_title, 1).listen((event) {
                                setState(() {
                                  _animes.add(event);
                                });
                              });
                            }
                          }
                        },
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
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
                    children: _animes
                        .map((anime) => AnimeCard(anime, widget.apiDB))
                        .toList(),
                  ),
                ),
              )
            ],
          ),
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(top: 35),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.4,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 10.0, left: 10, bottom: 2),
                          child: TextFormField(
                            onSaved: (String? value) {
                              _title = value!;
                            },
                            decoration: const InputDecoration(
                                hintText: 'Write an anime title!',
                                border: InputBorder.none),
                            validator: (String? value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  (value.isNotEmpty && value.length <= 3)) {
                                return 'Enter an anime title (3 characters up)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            if (_title != _searchedTitle) {
                              setState(() {
                                _animes = [];
                                _searchedTitle = _title;
                              });
                              widget.apiDB.search(_title, 1).listen((event) {
                                setState(() {
                                  _animes.add(event);
                                });
                              });
                            }
                          }
                        },
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
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
                    children: _animes
                        .map((anime) => AnimeCard(anime, widget.apiDB))
                        .toList(),
                  ),
                ),
              )
            ],
          ),
        );
      }
    }));
  }
}
