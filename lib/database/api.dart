import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_seasons/database/animeflv.dart';
import 'package:anime_seasons/database/animefrenzy.dart';
import 'package:anime_seasons/database/fembed.dart';
import 'package:anime_seasons/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:auto_update/auto_update.dart';

import "./errors.dart";

/// JIKAN API LIMIT :
/// 30 requests per minute
/// 2  requests per second

class ApiDB {
  late Database _db;
  Options options = Options.fabric();
  int expDays = 5;
  DateTime lastJikanCall = DateTime.now().subtract(const Duration(minutes: 1));
  int requestMinuteCount = 0;
  String jikanApi = "https://api.jikan.moe/v3";
  AnimeFrenzy animeFrenzy = AnimeFrenzy();
  AnimeFLV animeFLV = AnimeFLV();
  Fembed fembed = Fembed();
  List<String> size =
      Platform.isAndroid ? ["small", "large"] : ["large", "small"];

  int _amountAnime = 0;
  int _amountPicture = 0;
  int _amountEpisode = 0;

  Future<bool> initAsync() async {
    String dbFilePath = "cache.sql";
    if (Platform.isWindows) {
      dbFilePath = await AutoUpdate.getDocumentsFolder() +
          "\\Anime Seasons\\" +
          dbFilePath;
      File file = File(dbFilePath);
      if (!(await file.exists())) {
        file.create(recursive: true);
      }
    }

    _db =
        await openDatabase(dbFilePath, version: 1, onCreate: (db, vers) async {
      await db.execute(
          "CREATE TABLE options (id INTEGER PRIMARY KEY , limit_anime INTEGER DEFAULT 500, limit_pictures INTEGER DEFAULT 800, limit_episode INTEGER DEFAULT 200, language TEXT)");
      await db.execute(
          "CREATE TABLE image (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT, raw_image BLOB, create_date DATETIME, usage INTEGER DEFAULT 0 )");
      await db.execute(
          "CREATE TABLE favorite_anime (id INTEGER PRIMARY KEY, image_url TEXT, title TEXT, synopsis TEXT, score NUM)");
      await db.execute(
          "CREATE TABLE episode (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, directLink TEXT, anime_id INTEGER, create_date DATETIME, usage INTEGER DEFAULT 0 )");

      /* CACHE */
      await db.execute(
          "CREATE TABLE cache_season (year INTEGER, season INTEGER, anime_id_list TEXT)");
      await db.execute(
          "CREATE TABLE cache_anime (id INTEGER PRIMARY KEY, image_url TEXT, title TEXT, synopsis TEXT, score NUM)");
      await db.execute(
          "CREATE TABLE cache_review (page INTEGER, anime_id INTEGER, review_list TEXT)");
      await db.execute(
          "CREATE TABLE cache_search (page INTEGER, anime_title TEXT PRIMARY KEY, anime_id_list TEXT)");
      await db.execute(
          "CREATE TABLE cache_anime_details (anime_id INTEGER PRIMARY KEY, producer_list TEXT, genre_list TEXT, studio_list TEXT, demographics_list TEXT, airing_object TEXT, episodes INTEGER, status TEXT, rating TEXT, rank INTEGER)");
      /* END CACHE */

      await db
          .execute("INSERT INTO options (id, language) VALUES (1, 'english')");
    }, onOpen: (db) async {
      await db.rawDelete(
          "DELETE FROM image WHERE julianday('now') - julianday(create_date) > ?",
          [expDays]);
      await db.rawDelete(
          "DELETE FROM episode WHERE julianday('now') - julianday(create_date) > ?",
          [expDays]);
      await db.delete("cache_season");
      await db.delete("cache_search");
      await db.delete("cache_anime");
      await db.delete("cache_search");
      await db.delete("cache_review");
      await db.delete("cache_anime_details");

      var results = await db.rawQuery(
          "SELECT limit_anime, limit_pictures, limit_episode, language FROM options WHERE id = 1");
      if (results.isNotEmpty) {
        options = Options(
            results[0]["limit_anime"] as int,
            results[0]["limit_pictures"] as int,
            results[0]["limit_episode"] as int,
            Language.english.name == results[0]["language"] as String
                ? Language.english
                : Language.spanish);
      }

      results =
          await db.rawQuery("SELECT COUNT(*) AS amount FROM favorite_anime");
      if (results.isNotEmpty && results[0]["amount"] != null) {
        _amountAnime = results[0]["amount"] as int;
      }
      results = await db.rawQuery("SELECT COUNT(*) AS amount FROM episode");
      if (results.isNotEmpty && results[0]["amount"] != null) {
        _amountEpisode = results[0]["amount"] as int;
      }
      results = await db.rawQuery("SELECT COUNT(*) AS amount FROM image");
      if (results.isNotEmpty && results[0]["amount"] != null) {
        _amountPicture = results[0]["amount"] as int;
      }
    });

    if (_db.isOpen) {
      return await Future.delayed(const Duration(seconds: 2), () => true);
    }
    throw Exception("unable to open");
  }

  Future<Map<dynamic, dynamic>> _limitChecker(Uri url) {
    //Check for limits
    if (DateTime.now().difference(lastJikanCall).inMinutes == 0 &&
        requestMinuteCount == 30) {
      //If exced delay the call of the function until reach one minute of difference
      return Future.delayed(Duration(seconds: 60 - DateTime.now().second), () {
        lastJikanCall = DateTime.now();
        requestMinuteCount = 0;
        try {
          return _makeRequests(url);
        } on StatusCodeException {
          rethrow;
        }
      });
    } else {
      //Check if there is a minute of difference between the last call and this call
      if (lastJikanCall.difference(DateTime.now()).inMinutes > 0) {
        lastJikanCall = DateTime.now();
        requestMinuteCount = 0;
      } else {
        requestMinuteCount++;
      }
      return _makeRequests(url);
    }
  }

  Future<Map<dynamic, dynamic>> _makeRequests(Uri url) async {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    } else {
      throw StatusCodeException(response.statusCode);
    }
  }

  Future<Uint8List?> getImage(Uri url) async {
    var results = await _db.rawQuery(
        "SELECT raw_image, id FROM image WHERE url = ?", [url.toString()]);
    if (results.isNotEmpty) {
      await _db.rawUpdate("UPDATE image SET usage = usage + usage WHERE id = ?",
          [results[0]['id']]);
      return results[0]['raw_image'] as Uint8List;
    }

    var response = await http.get(url);
    if (response.statusCode == 200) {
      Uint8List image = response.bodyBytes;
      if (image.isNotEmpty) {
        if (_amountPicture >= options.limitPictures) {
          var id = await _db
              .rawQuery("SELECT id FROM image ORDER BY usage ASC LIMIT 1");
          if (id.isNotEmpty) {
            await _db.rawDelete(
                "DELETE FROM image WHERE id = ?", [id[0]["id"] as int]);
          }
        } else {
          _amountPicture += 1;
        }
        await _db.rawInsert(
            "INSERT INTO image(url, raw_image, create_date) VALUES(?, ?, DATE('now'))",
            [url.toString(), image]);
      }
      return image;
    }
  }

  Stream<Anime> getSeason(int year, Season season) async* {
    List<dynamic> animeId = [];
    List<int> favoritesID = await getFavoritesId();

    var results = await _db.rawQuery(
        "SELECT anime_id_list FROM cache_season WHERE year = ? AND season = ?",
        [year, season.index]);
    if (results.isNotEmpty && results[0]['anime_id_list'] != null) {
      animeId = jsonDecode(results[0]['anime_id_list'] as String);
    }

    if (animeId.isEmpty) {
      try {
        for (Map<dynamic, dynamic> anime in (await _limitChecker(
                Uri.parse("$jikanApi/season/$year/${season.name}")))['anime'] ??
            []) {
          Anime animeInstance = Anime(
              anime['title'],
              anime['synopsis'] ?? "",
              anime['score'] ?? 0,
              anime['mal_id'],
              (await getImage(Uri.parse(anime['image_url']))) ?? Uint8List(0),
              anime['image_url']);

          var results = await _db.rawQuery(
              "SELECT 1 FROM cache_anime WHERE id = ?", [animeInstance.id]);
          if (results.isEmpty) {
            await _db.rawInsert(
                "INSERT OR ABORT INTO cache_anime (id, image_url, title, synopsis, score) VALUES (?, ?,?,?,?)",
                [
                  animeInstance.id,
                  animeInstance.imageUrl,
                  animeInstance.title,
                  animeInstance.synopsis,
                  animeInstance.score
                ]);

            animeId.add(animeInstance.id);
          }
          if (favoritesID.contains(animeInstance.id)) {
            animeInstance.favorite = true;
          }
          yield animeInstance;
        }
      } on StatusCodeException catch (e) {
        print(e);
      }
      await _db.rawInsert(
          "INSERT INTO cache_season (year, season, anime_id_list) VALUES(?,?,?)",
          [year, season.index, jsonEncode(animeId)]);
    } else {
      try {
        for (int id in animeId) {
          var result = await _db.rawQuery(
              "SELECT title, synopsis, score, image_url FROM cache_anime WHERE id = ?",
              [id]);
          if (result.isNotEmpty) {
            Anime anime = Anime(
                result[0]['title'] as String,
                result[0]['synopsis'] as String,
                result[0]['score'] as num,
                id,
                (await getImage(Uri.parse(result[0]['image_url'] as String))) ??
                    Uint8List(0),
                result[0]['image_url'] as String);
            if (favoritesID.contains(id)) {
              anime.favorite = true;
            }
            yield anime;
          }
        }
      } on StatusCodeException catch (e) {
        print(e);
      }
    }
  }

  Stream<Anime> search(String title, int page) async* {
    List<dynamic> animeId = [];
    List<int> favoritesID = await getFavoritesId();

    var results = await _db.rawQuery(
        "SELECT anime_id_list FROM cache_search WHERE anime_title = ? AND page = ?",
        [title, page]);
    if (results.isNotEmpty && results[0]['anime_id_list'] != null) {
      animeId = jsonDecode(results[0]['anime_id_list'] as String);
    }

    if (animeId.isEmpty) {
      try {
        for (Map<dynamic, dynamic> anime in (await _limitChecker(Uri.parse(
                "$jikanApi/search/anime?q=$title&page=$page")))['results'] ??
            []) {
          Anime animeInstance = Anime(
              anime['title'],
              anime['synopsis'] ?? "",
              anime['score'] ?? 0,
              anime['mal_id'],
              (await getImage(Uri.parse(anime['image_url']))) ?? Uint8List(0),
              anime['image_url']);

          var results = await _db.rawQuery(
              "SELECT 1 FROM cache_anime WHERE id = ?", [animeInstance.id]);
          if (results.isEmpty) {
            await _db.rawInsert(
                "INSERT OR ABORT INTO cache_anime (id, image_url, title, synopsis, score) VALUES (?,?,?,?,?)",
                [
                  animeInstance.id,
                  animeInstance.imageUrl,
                  animeInstance.title,
                  animeInstance.synopsis,
                  animeInstance.score
                ]);
          }
          animeId.add(animeInstance.id);

          if (favoritesID.contains(animeInstance.id)) {
            animeInstance.favorite = true;
          }
          yield animeInstance;
        }
      } on StatusCodeException catch (e) {
        print(e);
      }

      await _db.rawInsert(
          "INSERT INTO cache_search (anime_title, page, anime_id_list) VALUES(?,?,?)",
          [title, page, jsonEncode(animeId)]);
    } else {
      try {
        for (int id in animeId) {
          var result = await _db.rawQuery(
              "SELECT title, synopsis, score, image_url FROM cache_anime WHERE id = ?",
              [id]);
          if (result.isNotEmpty) {
            Anime anime = Anime(
                result[0]['title'] as String,
                result[0]['synopsis'] as String,
                result[0]['score'] as num,
                id,
                (await getImage(Uri.parse(result[0]['image_url'] as String))) ??
                    Uint8List(0),
                result[0]['image_url'] as String);
            if (favoritesID.contains(id)) {
              anime.favorite = true;
            }
            yield anime;
          }
        }
      } on StatusCodeException catch (e) {
        print(e);
      }
    }
  }

  Stream<Uint8List?> getPicturesFromAnime(int animeId) async* {
    try {
      for (Map<dynamic, dynamic> picture in (await _limitChecker(
              Uri.parse("$jikanApi/anime/$animeId/pictures")))['pictures'] ??
          []) {
        yield await getImage(Uri.parse(picture[size[0]] ?? picture[size[1]])) ??
            Uint8List(0);
      }
    } on StatusCodeException catch (e) {
      print(e);
    }
  }

  Stream<Review?> getReviews(int animeId, int reviewPage) async* {
    // await db.execute(
    //       "CREATE TABLE cache_review (page INTEGER, anime_id INTEGER, review_list TEXT)");

    var results = await _db.rawQuery(
        "SELECT review_list FROM cache_review WHERE anime_id = ? AND page = ?",
        [animeId, reviewPage]);
    if (results.isNotEmpty) {
      for (var element in jsonDecode(results[0]['review_list'] as String)) {
        yield Review.fromJson(element);
      }
    } else {
      List<Review> reviews = [];
      try {
        for (Map<dynamic, dynamic> review in (await _limitChecker(Uri.parse(
                "$jikanApi/anime/$animeId/reviews/$reviewPage")))["reviews"] ??
            []) {
          Review reviewInstance = Review(
              review["mal_id"],
              Reviewer(
                  review["reviewer"]["username"],
                  await getImage(Uri.parse(review["reviewer"]["image_url"])) ??
                      Uint8List(0)),
              review["helpful_count"],
              review["date"] != null ? DateTime.parse(review["date"]) : null,
              review["reviewer"]["scores"]["episode_seen"],
              review["reviewer"]["scores"]["overall"],
              review["reviewer"]["scores"]["story"],
              review["reviewer"]["scores"]["animation"],
              review["reviewer"]["scores"]["sound"],
              review["reviewer"]["scores"]["character"],
              review["reviewer"]["scores"]["enjoyment"],
              review["content"]);
          reviews.add(reviewInstance);
          yield reviewInstance;
        }
        await _db.rawInsert(
            "INSERT INTO cache_review (page, anime_id, review_list) VALUES(?,?,?)",
            [
              reviewPage,
              animeId,
              jsonEncode(reviews.map((review) => review.toJson()).toList())
            ]);
      } on StatusCodeException catch (e) {
        print(e);
      }
    }
  }

  Future<void> getAnimeDetails(Anime anime) async {
    // _db.execute(
    //     "CREATE TABLE cache_anime_details
    //(anime_id INTEGER, producer_list TEXT, genre_list TEXT, studio_list TEXT, demographics_list TEXT, airing_object TEXT, episodes INTEGER, status TEXT, rating TEXT, rank INTEGER)");

    var results = await _db.rawQuery(
        "SELECT producer_list, genre_list, studio_list, demographics_list, airing_object, episodes, status, rating, rank FROM cache_anime_details WHERE anime_id = ?",
        [anime.id]);
    if (results.isNotEmpty) {
      anime.producers = List<Producer>.from(
          jsonDecode(results[0]['producer_list'] as String)
              .map((v) => Producer.fromJson(v)));
      anime.genres = List<Genre>.from(
          jsonDecode(results[0]['genre_list'] as String)
              .map((v) => Genre.fromJson(v)));
      anime.studios = List<Studio>.from(
          jsonDecode(results[0]['studio_list'] as String)
              .map((v) => Studio.fromJson(v)));
      anime.demographics = List<Demographics>.from(
          jsonDecode(results[0]['demographics_list'] as String)
              .map((v) => Demographics.fromJson(v)));
      var airing = jsonDecode(results[0]['airing_object'] as String);
      anime.from =
          airing['from'].isNotEmpty ? DateTime.parse(airing['from']) : null;
      anime.to = airing['to'].isNotEmpty ? DateTime.parse(airing['to']) : null;
      anime.episodesN = results[0]['episodes'] as int;
      anime.status = results[0]['status'] as String;
      anime.rating = results[0]['rating'] as String;
      anime.rank = results[0]['rank'] as int;
    } else {
      try {
        Map<dynamic, dynamic> animeInfo =
            await _limitChecker(Uri.parse("$jikanApi/anime/${anime.id}"));
        anime.producers = List<Producer>.from(animeInfo['producers']
            ?.map((producer) => Producer(producer['mal_id'], producer['name']))
            .toList());
        anime.genres = List<Genre>.from(animeInfo['genres']
            ?.map((genre) => Genre(genre['mal_id'], genre['name']))
            .toList(growable: false));
        anime.studios = List<Studio>.from(animeInfo['studios']
            ?.map((genre) => Studio(genre['mal_id'], genre['name']))
            .toList(growable: false));
        anime.demographics = List<Demographics>.from(animeInfo['demographics']
            ?.map((genre) => Demographics(genre['mal_id'], genre['name']))
            .toList(growable: false));
        anime.airing = animeInfo['airing'];
        if (animeInfo['aired']['from'] != null) {
          anime.from = DateTime.parse(animeInfo['aired']['from']);
        }
        if (animeInfo['aired']['to'] != null) {
          anime.to = DateTime.parse(animeInfo['aired']['to']);
        }
        anime.episodesN = animeInfo['episodes'] ?? 0;
        anime.status = animeInfo['status'];
        anime.rating = animeInfo['rating'];
        anime.rank = animeInfo['rank'] ?? 0;

        await _db.rawInsert(
            "INSERT INTO cache_anime_details (anime_id, producer_list, genre_list, studio_list, demographics_list, airing_object, episodes, status, rating, rank) VALUES (?,?,?,?,?,?,?,?,?,?)",
            [
              anime.id,
              jsonEncode(anime.producers.map((v) => v.toJson()).toList()),
              jsonEncode(anime.genres.map((v) => v.toJson()).toList()),
              jsonEncode(anime.studios.map((v) => v.toJson()).toList()),
              jsonEncode(anime.demographics.map((v) => v.toJson()).toList()),
              jsonEncode({
                'from': anime.from != null ? anime.from.toString() : '',
                'to': anime.to != null ? anime.to.toString() : ''
              }),
              anime.episodesN,
              anime.status,
              anime.rating,
              anime.rank
            ]);
      } on StatusCodeException catch (e) {
        print(e);
      }
    }
  }

  Future<void> getListEpisodes(Anime anime) async {
    // Uri? animeVideoPage = await searchForAnime([anime.title]);
    // if (animeVideoPage != null) {
    //   anime.episodes = await getEpisodes(animeVideoPage);
    // }
    var api = options.language == Language.english ? animeFrenzy : animeFLV;
    Uri? animeVideoPage = await api.searchForAnime([anime.title]);
    if (animeVideoPage != null) {
      anime.episodes = await api.getEpisodes(animeVideoPage);
    }
  }

  Future<void> getDirectVideoLink(int animeId, Episode episode) async {
    // Uri? singleVideoLink = await getSingleVideoLink(episode.uri);
    // if (singleVideoLink != null) {
    //   episode.directLink = await getGoLoadLinkForMp4Upload(singleVideoLink);
    // }

    var results = await _db.rawQuery(
        "SELECT directLink FROM episode WHERE anime_id = ? AND name = ?",
        [animeId, episode.name]);
    if (results.isNotEmpty) {
      episode.directLink = Uri.parse(results[0]['directLink'] as String);
    } else {
      episode.directLink = await fembed.getDirectLink(episode.uri);
      if (_amountPicture >= options.limitPictures) {
        await _db.rawUpdate(
            "UPDATE image SET usage = usage + usage WHERE id = ?", [animeId]);
        var results = await _db
            .rawQuery("SELECT id FROM cache_anime ORDER BY usage ASC LIMIT 1");
        if (results.isNotEmpty) {
          await _db.rawDelete(
              "DELETE FROM episode WHERE anime_id = ?", [results[0]["id"]]);
        }
      } else {
        _amountPicture += 1;
      }
      await _db.rawInsert(
          "INSERT INTO episode(name, directLink, anime_id, create_date) VALUES(?, ?, ?, DATE('now'))",
          [episode.name, episode.directLink.toString(), animeId]);
    }
  }

  Future<void> toogleFavorite(Anime anime) async {
    if (anime.favorite) {
      await _db.rawInsert(
          "INSERT INTO favorite_anime (id, title, image_url, synopsis, score) VALUES(?,?,?,?,?)",
          [anime.id, anime.title, anime.imageUrl, anime.synopsis, anime.score]);
    } else {
      await _db
          .rawDelete("DELETE FROM favorite_anime WHERE id = ?", [anime.id]);
    }
  }

  Stream<Anime> getFavorites() async* {
    var results = await _db.rawQuery(
        "SELECT id, title, image_url, synopsis, score FROM favorite_anime");
    for (var result in results) {
      var anime = Anime(
          result['title'] as String,
          result['synopsis'] as String,
          result['score'] as num,
          result['id'] as int,
          (await getImage(Uri.parse(result['image_url'] as String))) ??
              Uint8List(0),
          result['image_url'] as String);
      anime.favorite = true;
      yield anime;
    }
  }

  Future<List<int>> getFavoritesId() async {
    var results = await _db.rawQuery("SELECT id FROM favorite_anime");
    if (results.isNotEmpty) {
      return results.map((e) => e['id'] as int).toList();
    }
    return [];
  }

  Future<void> updateOption() async {
    await _db
        .rawUpdate("UPDATE options SET language = ?", [options.language.name]);
  }
}
