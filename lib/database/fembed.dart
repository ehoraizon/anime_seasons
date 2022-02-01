import 'dart:convert';

import 'package:anime_seasons/database/interfaces/cloud_cracker.dart';
// import 'package:anime_seasons/database/interfaces/site_cracker.dart';

// import 'package:anime_seasons/database/interfaces/site_cracker.dart';
// import 'package:anime_seasons/models/models.dart';

import 'package:http/http.dart' as http;
// import 'package:beautiful_soup_dart/beautiful_soup.dart';

// class UserAgentClient extends http.BaseClient {
//   final String userAgent;
//   final http.Client _inner;

//   UserAgentClient(this.userAgent, this._inner);

//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     request.headers['user-agent'] = userAgent;
//     return _inner.send(request);
//   }
// }

class Fembed implements CloudCracker {
  @override
  Future<Uri?> getDirectLink(Uri videoLink) async {
    var headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:95.0) Gecko/20100101 Firefox/95.0',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.5',
      // 'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      'Origin': videoLink.origin,
      'Alt-Used': 'fembed-hd.com',
      'Connection': 'keep-alive',
      'Referer': videoLink.toString(),
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-GPC': '1',
      'DNT': '1',
      'TE': 'trailers'
    };
    var request = http.Request(
        'POST',
        Uri.parse(videoLink.origin +
            "/api/source/" +
            videoLink.toString().split("/v/").last));
    request.bodyFields = {'r': '', 'd': 'fembed-hd.com'};
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var decodedResponse =
          jsonDecode(await response.stream.bytesToString()) as Map;

      if (decodedResponse['data'] != null &&
          decodedResponse['data'].runtimeType != String &&
          (decodedResponse['data'] as List).isNotEmpty &&
          (decodedResponse['data'] as List).last['file'] != null) {
        return Uri.parse(
            (decodedResponse['data'] as List).last['file'] + "/video.mp4");
      }
    }
  }
}
