import 'dart:convert';

import 'package:anime_seasons/database/interfaces/site_cracker.dart';
import 'package:anime_seasons/models/models.dart';

import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';

class AnimeFLV implements SiteCracker {
  final String _url = "https://www3.animeflv.net";
  final RegExp listChapters =
      RegExp(r"var episodes = \[[\[0-9\],]+\];$", multiLine: true);
  final RegExp sourceList = RegExp(
      r'var videos = {[":a-zA-z0-9,_\-.\/\[\]{}=#!?]+};$',
      multiLine: true);

  @override
  Future<Uri?> searchForAnime(List<String> animeTitles) async {
    for (String title in animeTitles) {
      var response = await http.get(Uri.parse("$_url/browse?q=$title"));
      if (response.statusCode == 200) {
        BeautifulSoup bs = BeautifulSoup(response.body);
        for (Bs4Element article in bs.findAll("article", class_: "Anime")) {
          Bs4Element? link = article.find("a");
          if (link != null) {
            Bs4Element? title = link.find("h3", class_: "Title");
            if (title != null &&
                animeTitles.contains(title.getText().replaceAll("\n", "")) &&
                link.attributes['href'] != null) {
              return Uri.parse("$_url${link.attributes['href'].toString()}");
            }
          }
        }
      }
    }
  }

  Future<Uri?> _getCloudLink(Uri uri) async {
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      Match? match = sourceList.firstMatch(response.body);
      if (match != null) {
        Map<String, dynamic> jsonObject = jsonDecode(
            response.body.substring(match.start + 13, match.end - 1));
        for (Map<String, dynamic> cloudObject in jsonObject['SUB']) {
          if (cloudObject['server'] != null &&
              cloudObject['server'] == "fembed" &&
              cloudObject['code'] != null) {
            return Uri.parse(cloudObject['code']);
          }
        }
      }
    }
  }

  @override
  Future<List<Episode>> getEpisodes(Uri animeEpisodePage) async {
    List<Episode> episodes = [];
    var response = await http.get(animeEpisodePage);
    if (response.statusCode == 200) {
      Match? match = listChapters.firstMatch(response.body);
      if (match != null) {
        List<dynamic> jsonObject = jsonDecode(
            response.body.substring(match.start + 15, match.end - 1));
        for (List<dynamic> jsonEpisode in jsonObject) {
          Uri? cloudLink = await _getCloudLink(Uri.parse(
              "$_url/ver/${animeEpisodePage.toString().split("/").last}-${jsonEpisode.first}"));
          if (cloudLink != null) {
            episodes.add(Episode(jsonEpisode.first.toString(), cloudLink));
          }
        }
      }
    }
    return episodes;
  }
}
