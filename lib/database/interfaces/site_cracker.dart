import 'package:anime_seasons/models/models.dart';

class SiteCracker {
  final String _url;

  SiteCracker(this._url);

  Future<Uri?> searchForAnime(List<String> animeTitles) async {}
  Future<List<Episode>> getEpisodes(Uri animeEpisodePage) async {
    return [];
  }
}
