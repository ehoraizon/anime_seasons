import 'dart:typed_data';

enum Season { summer, spring, fall, winter }
enum Language { spanish, english }

class JsonSerializableData {
  final int id;
  final String name;

  JsonSerializableData(this.id, this.name);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Genre extends JsonSerializableData {
  Genre(int id, String name) : super(id, name);
  factory Genre.fromJson(Map<String, dynamic> object) =>
      Genre(object['id'], object['name']);
}

class Producer extends JsonSerializableData {
  Producer(int id, String name) : super(id, name);
  factory Producer.fromJson(Map<String, dynamic> object) =>
      Producer(object['id'], object['name']);
}

class Studio extends JsonSerializableData {
  Studio(int id, String name) : super(id, name);
  factory Studio.fromJson(Map<String, dynamic> object) =>
      Studio(object['id'], object['name']);
}

class Demographics extends JsonSerializableData {
  Demographics(int id, String name) : super(id, name);
  factory Demographics.fromJson(Map<String, dynamic> object) =>
      Demographics(object['id'], object['name']);
}

class Anime {
  final String title;
  final String synopsis;
  final num score;
  final int id;
  final Uint8List image;
  final String imageUrl;
  List<Uint8List?> pictures = [];
  List<Producer> producers = [];
  List<Studio> studios = [];
  List<Genre> genres = [];
  List<Demographics> demographics = [];
  List<Review> reviews = [];
  List<Episode> episodes = [];
  bool? airing;
  DateTime? from;
  DateTime? to;
  String? status;
  String? rating;
  int? rank = 0;
  int episodesN = 0;
  bool favorite = false;

  Anime(this.title, this.synopsis, this.score, this.id, this.image,
      this.imageUrl);
}

class Episode {
  final String name;
  final Uri uri;
  Uri? directLink;

  Episode(this.name, this.uri);
}

class Cordinates {
  final Season season;
  final int year;

  Cordinates(this.season, this.year);
  Cordinates clone() {
    return Cordinates(season, year);
  }
}

class Reviewer {
  final String nick;
  final Uint8List avatar;

  Reviewer(this.nick, this.avatar);

  factory Reviewer.fromJson(Map<String, dynamic> object) =>
      Reviewer(object['nick'], object['avatar']);

  Map<String, dynamic> toJson() => {'nick': nick, 'avatar': avatar};
}

class Review {
  final int id;
  final Reviewer reviewer;
  final int? helpfulCount;
  final DateTime? date;
  final int? epidodeSeen;
  final int? overall;
  final int? story;
  final int? animation;
  final int? sound;
  final int? character;
  final int? enjoyment;
  final String? content;

  Review(
      this.id,
      this.reviewer,
      this.helpfulCount,
      this.date,
      this.epidodeSeen,
      this.overall,
      this.story,
      this.animation,
      this.sound,
      this.character,
      this.enjoyment,
      this.content);

  factory Review.fromJson(Map<String, dynamic> object) => Review(
      object["id"],
      Reviewer.fromJson(object["reviewer"]),
      object["helpfulCount"],
      object["date"].isNotEmpty ? DateTime.parse(object["date"]) : null,
      object["epidodeSeen"],
      object["overall"],
      object["story"],
      object["animation"],
      object["sound"],
      object["character"],
      object["enjoyment"],
      object["content"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "reviewer": reviewer.toJson(),
        "helpfulCount": helpfulCount,
        "date": date != null ? date.toString() : '',
        "epidodeSeen": epidodeSeen,
        "overall": overall,
        "story": story,
        "animation": animation,
        "sound": sound,
        "character": character,
        "enjoyment": enjoyment,
        "content": content
      };
}

class Options {
  final int limitAnime;
  final int limitPictures;
  final int limitEpisode;
  Language language;

  Options(
      this.limitAnime, this.limitPictures, this.limitEpisode, this.language);

  factory Options.fabric() => Options(500, 500, 500, Language.english);
}
