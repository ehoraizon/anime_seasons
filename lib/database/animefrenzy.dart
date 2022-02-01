import 'package:anime_seasons/database/interfaces/site_cracker.dart';
import 'package:anime_seasons/models/models.dart';

import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';

class AnimeFrenzy implements SiteCracker {
  final String _url = "https://www.animefrenzy.net";

  @override
  Future<Uri?> searchForAnime(List<String> animeTitle) async {
    for (String title in animeTitle) {
      var response = await http.get(Uri.parse("$_url/search?name=$title"));
      if (response.statusCode == 200) {
        BeautifulSoup bs = BeautifulSoup(response.body);
        List<Bs4Element> animeTitles = bs.findAll("p", class_: "ani-name");
        List<Bs4Element> animeLinks = bs.findAll("a", class_: "linka");
        for (int i = 0; i < animeTitles.length; i++) {
          if (animeTitle
              .contains((animeTitles[i].getText().replaceAll("\n", "")))) {
            if (animeLinks[i].attributes['href'] != null) {
              return Uri.parse(animeLinks[i].attributes['href'].toString());
            }
          }
        }
      }
    }
  }

  Future<Uri?> _getCloudLink(Uri videoUri) async {
    var response = await http.get(videoUri);
    if (response.statusCode == 200) {
      BeautifulSoup bs = BeautifulSoup(response.body);
      for (Bs4Element li in bs.findAll("li", class_: "linkserver")) {
        switch (li.getText().replaceAll("\n", "")) {
          case "Xstreamcdn":
            if (li.attributes["data-status"] != null &&
                li.attributes["data-status"] == "1") {
              String? link = li.attributes["data-video"];
              if (link != null) {
                return Uri.parse(link);
              }
            }
            break;
        }
      }
    }
  }

  Future<Uri?> _getGoLink(Uri url) async {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      BeautifulSoup bs = BeautifulSoup(response.body);
      Bs4Element? selectElm = bs.find("select", id: "select-iframe-to-display");
      if (selectElm != null) {
        for (Bs4Element option in selectElm.findAll("option")) {
          var videoIDService = option.attributes['value']?.split("-#-");
          if (videoIDService != null && videoIDService.length == 2) {
            if (videoIDService[1] == "gogo-stream") {
              return await _getCloudLink(Uri.parse(
                  "https://goload.one/streaming.php?id=${videoIDService[0]}"));
            }
            // switch (videoIDService[1]) {
            //   case "fembed":
            //     return Uri.parse("https://fcdn.stream/v/${videoIDService[0]}");
            //   case "gogo-stream":
            //     return Uri.parse(
            //         "https://goload.one/streaming.php?id=${videoIDService[0]}");
            // }
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
      BeautifulSoup bs = BeautifulSoup(response.body);
      List<Bs4Element>? liEpisodes =
          bs.find("ul", class_: "episode")?.findAll("li", class_: "epi-me");
      if (liEpisodes != null) {
        for (var element in liEpisodes) {
          Bs4Element? link = element.find('a');
          if (link != null) {
            String? href = link.attributes["href"];
            if (href != null) {
              Uri? cloudLink = await _getGoLink(Uri.parse(href));
              if (cloudLink != null) {
                episodes.add(
                    Episode(link.getText().replaceAll("\n", ""), cloudLink));
              }
            }
          }
        }
      }
    }
    return episodes;
  }
}
