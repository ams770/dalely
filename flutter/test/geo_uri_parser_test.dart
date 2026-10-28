import 'dart:io';

import 'package:feen/shared/utils/geo_uri_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoUriParser', () {
    test('returns null for null or empty input', () {
      expect(GeoUriParser.parse(null), isNull);
      expect(GeoUriParser.parse(''), isNull);
      expect(GeoUriParser.parse('   '), isNull);
      expect(GeoUriParser.parse('invalid uri'), isNull);
    });

    test('parses simple geo:lat,lng', () {
      final res = GeoUriParser.parse('geo:30.0444,31.2357');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
      expect(res.label, isNull);
    });

    test('parses geo:lat,lng with zoom parameter', () {
      final res = GeoUriParser.parse('geo:30.0444,31.2357?z=16');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
    });

    test('parses geo:0,0?q=lat,lng query coordinates', () {
      final res = GeoUriParser.parse('geo:0,0?q=24.7136,46.6753');
      expect(res, isNotNull);
      expect(res!.latitude, 24.7136);
      expect(res.longitude, 46.6753);
      expect(res.label, isNull);
    });

    test('parses geo:0,0?q=lat,lng(Label) with label', () {
      final res = GeoUriParser.parse('geo:0,0?q=30.0444,31.2357(Downtown Pharmacy)');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
      expect(res.label, 'Downtown Pharmacy');
    });

    test('parses Google Maps URL format (maps.google.com/?q=lat,lng)', () {
      final res =
          GeoUriParser.parse('https://maps.google.com/?q=30.0444,31.2357');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
    });

    test('parses Google Maps /maps?q=lat,lng format', () {
      final res =
          GeoUriParser.parse('https://www.google.com/maps?q=25.2048,55.2708');
      expect(res, isNotNull);
      expect(res!.latitude, 25.2048);
      expect(res.longitude, 55.2708);
    });

    test('parses Google Maps search API format', () {
      final res = GeoUriParser.parse(
          'https://www.google.com/maps/search/?api=1&query=30.0444,31.2357');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
    });

    test('parses Google Maps @lat,lng path format', () {
      final res = GeoUriParser.parse(
          'https://www.google.com/maps/@30.0444,31.2357,17z/data=!3m1!4b1');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
    });

    test('parses Apple Maps URL with ll parameter', () {
      final res =
          GeoUriParser.parse('https://maps.apple.com/?ll=30.0444,31.2357&q=Home');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
      expect(res.label, 'Home');
    });

    test('parses feen://save custom scheme', () {
      final res = GeoUriParser.parse(
          'feen://save?lat=21.4858&lng=39.1925&name=Red+Sea+Mall');
      expect(res, isNotNull);
      expect(res!.latitude, 21.4858);
      expect(res.longitude, 39.1925);
      expect(res.label, 'Red Sea Mall');
    });

    test('parses URL with percent-encoded coordinates and spaces', () {
      final res = GeoUriParser.parse(
          'geo:0,0?q=30.0444%2C31.2357%20(City%20Center)');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
      expect(res.label, 'City Center');
    });

    test('parses multi-line Apple Maps share text with title', () {
      const shared = 'Marked Location\nGiza Kerdasa\nhttps://maps.apple.com/?ll=30.0135,31.2081';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0135);
      expect(res.longitude, 31.2081);
      expect(res.label, 'Marked Location');
    });

    test('parses Google Maps place path with place name', () {
      const url =
          'https://www.google.com/maps/place/Sphinx+International+Airport/@30.1147,31.0211,15z';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 30.1147);
      expect(res.longitude, 31.0211);
      expect(res.label, 'Sphinx International Airport');
    });

    test('parses multi-line Google Maps share with title and query link', () {
      const shared =
          'Sphinx International Airport\nhttps://maps.google.com/?q=30.1147,31.0211';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.1147);
      expect(res.longitude, 31.0211);
      expect(res.label, 'Sphinx International Airport');
    });

    test('parses multi-line text with raw coordinates and name', () {
      const shared = 'Downtown Office\n30.0444, 31.2357';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0444);
      expect(res.longitude, 31.2357);
      expect(res.label, 'Downtown Office');
    });

    test('parses feen://save?data= with encoded share content', () {
      final encoded = Uri.encodeComponent(
          'Marked Location\nhttps://maps.apple.com/?ll=30.0135,31.2081');
      final res = GeoUriParser.parse('feen://save?data=$encoded');
      expect(res, isNotNull);
      expect(res!.latitude, 30.0135);
      expect(res.longitude, 31.2081);
      expect(res.label, 'Marked Location');
    });

    test('parses Google Maps URL with !3d and !4d protobuf coordinates', () {
      const url =
          'https://www.google.com/maps/place/Cairo+Festival+City/@30.0298,31.4087,17z/data=!4m6!3m5!1s0x14583cdbfb7e7ab7:0xeb88cb995fc0cbe!8m2!3d30.0298132!4d31.4087192';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0298);
      expect(res.longitude, 31.4087);
      expect(res.label, 'Cairo Festival City');
    });

    test('parses Google Maps URL with only !3d and !4d data coordinates', () {
      const url =
          'https://www.google.com/maps/place/Giza+Zoo/data=!4m2!3m1!1s0x0:0x0!3d30.0232!4d31.2134';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0232);
      expect(res.longitude, 31.2134);
      expect(res.label, 'Giza Zoo');
    });

    test('parses Apple Maps URL with sll search coordinates', () {
      const url =
          'https://maps.apple.com/?q=Downtown+Mall&sll=30.0123,31.4567';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0123);
      expect(res.longitude, 31.4567);
      expect(res.label, 'Downtown Mall');
    });

    test('extractLabel extracts place name from shared text containing short link', () {
      const shared = 'Cairo Festival City Mall\nhttps://maps.app.goo.gl/wJ1qAbcDefGh';
      final label = GeoUriParser.extractLabel(shared);
      expect(label, 'Cairo Festival City Mall');
    });

    test('parseAsync resolves short link redirect using mock HTTP client', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((HttpRequest request) {
          if (request.uri.path == '/short') {
            request.response.statusCode = HttpStatus.movedTemporarily;
            request.response.headers.set(
              HttpHeaders.locationHeader,
              'http://${server.address.host}:${server.port}/maps/@30.0444,31.2357,17z',
            );
            request.response.close();
          } else {
            request.response.statusCode = HttpStatus.ok;
            request.response.close();
          }
        });

        final shortUrl = 'Place Name\nhttp://${server.address.host}:${server.port}/short';
        final res = await GeoUriParser.parseAsync(shortUrl);
        expect(res, isNotNull);
        expect(res!.latitude, 30.0444);
        expect(res.longitude, 31.2357);
        expect(res.label, 'Place Name');
      } finally {
        await server.close(force: true);
      }
    });

    test('parseAsync returns null gracefully on connection failure without crashing', () async {
      const invalidUrl = 'Place Name\nhttp://127.0.0.1:54321/nonexistent';
      final res = await GeoUriParser.parseAsync(
        invalidUrl,
        timeout: const Duration(milliseconds: 200),
      );
      expect(res, isNull);
    });

    test('parses Arabic Google Maps place with address and keeps only place name', () {
      const shared = 'برج المملكة، طريق الملك فهد، العليا، الرياض 12214\nhttps://maps.google.com/?q=24.7115,46.6744';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 24.7115);
      expect(res.longitude, 46.6744);
      expect(res.label, 'برج المملكة');
    });

    test('parses Google Maps URL with raw Arabic place path', () {
      const url =
          'https://www.google.com/maps/place/برج+المملكة،+طريق+الملك+فهد/@24.7115,46.6744,17z';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 24.7115);
      expect(res.longitude, 46.6744);
      expect(res.label, 'برج المملكة');
    });

    test('parses Google Maps URL with percent-encoded Arabic place path', () {
      const url =
          'https://www.google.com/maps/place/%D8%A8%D8%B1%D8%AC+%D8%A7%D9%84%D9%85%D9%85%D9%84%D9%83%D8%A9%D8%8C+%D8%B7%D8%B1%D9%8A%D9%82+%D8%A7%D9%84%D9%85%D9%84%D9%83+%D9%81%D9%87%D8%AF/@24.7115,46.6744,17z';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 24.7115);
      expect(res.longitude, 46.6744);
      expect(res.label, 'برج المملكة');
    });

    test('extracts street from Arabic dropped pin near road', () {
      const shared = 'موقع تم وضع علامة عليه بالقرب من طريق الملك فهد\nhttps://maps.google.com/?q=24.7115,46.6744';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 24.7115);
      expect(res.longitude, 46.6744);
      expect(res.label, 'طريق الملك فهد');
    });

    test('discards generic Arabic dropped pin label and keeps coordinates', () {
      const shared = 'موقع تم وضع علامة عليه\nhttps://maps.google.com/?q=24.7115,46.6744';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 24.7115);
      expect(res.longitude, 46.6744);
      expect(res.label, isNull);
    });

    test('parses Japanese Google Maps place and extracts only name', () {
      const shared = '東京タワー、芝公園４丁目２−８\nhttps://maps.google.com/?q=35.6586,139.7454';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 35.6586);
      expect(res.longitude, 139.7454);
      expect(res.label, '東京タワー');
    });

    test('unwraps feen scheme containing Arabic place and resolves async', () async {
      final encoded = Uri.encodeComponent('مطعم البيك\nhttps://maps.google.com/?q=21.4225,39.8262');
      final res = await GeoUriParser.parseAsync('feen://save?data=$encoded');
      expect(res, isNotNull);
      expect(res!.latitude, 21.4225);
      expect(res.longitude, 39.8262);
      expect(res.label, 'مطعم البيك');
    });

    test('parses Chinese place and extracts only name without address', () {
      const shared = '故宫博物院，北京市东城区景山前街4号\nhttps://maps.google.com/?q=39.9163,116.3972';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 39.9163);
      expect(res.longitude, 116.3972);
      expect(res.label, '故宫博物院');
    });

    test('parses French place and extracts only name without street address', () {
      const shared = 'Tour Eiffel, Champ de Mars, 5 Av. Anatole France, 75007 Paris\nhttps://maps.google.com/?q=48.8584,2.2945';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 48.8584);
      expect(res.longitude, 2.2945);
      expect(res.label, 'Tour Eiffel');
    });

    test('parses Russian place and extracts only name', () {
      const shared = 'Эрмитаж, Дворцовая пл., 2, Санкт-Петербург\nhttps://maps.google.com/?q=59.9398,30.3146';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 59.9398);
      expect(res.longitude, 30.3146);
      expect(res.label, 'Эрмитаж');
    });

    test('parses Greek place and extracts only name', () {
      const shared = 'Ακρόπολη Αθηνών, Αθήνα 105 58, Ελλάδα\nhttps://maps.google.com/?q=37.9715,23.7257';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 37.9715);
      expect(res.longitude, 23.7257);
      expect(res.label, 'Ακρόπολη Αθηνών');
    });

    test('strips metadata separated by middle dot and category', () {
      const shared = 'مطعم البرنس · مطعم مأكولات شعبية · إمبابة\nhttps://maps.google.com/?q=30.0754,31.2187';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0754);
      expect(res.longitude, 31.2187);
      expect(res.label, 'مطعم البرنس');
    });

    test('strips city separated by spaced hyphen', () {
      const shared = 'جامع الأزهر - القاهرة\nhttps://maps.google.com/?q=30.0456,31.2625';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0456);
      expect(res.longitude, 31.2625);
      expect(res.label, 'جامع الأزهر');
    });

    test('strips star rating and reviews in Arabic share text', () {
      const shared = 'مطعم صبحي كابر 4.6 ★★★★☆ (25,000)\nhttps://maps.google.com/?q=30.0825,31.2405';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0825);
      expect(res.longitude, 31.2405);
      expect(res.label, 'مطعم صبحي كابر');
    });

    test('strips invisible directional markers in Arabic text', () {
      const shared = '\u200Eمطعم بلبع للمشويات\u200F\nhttps://maps.google.com/?q=31.2356,29.9678';
      final res = GeoUriParser.parse(shared);
      expect(res, isNotNull);
      expect(res!.latitude, 31.2356);
      expect(res.longitude, 29.9678);
      expect(res.label, 'مطعم بلبع للمشويات');
    });

    test('extracts Arabic place name from Google Maps search URL path', () {
      const url = 'https://www.google.com/maps/search/مطعم+البرنس/@30.0754,31.2187,17z';
      final res = GeoUriParser.parse(url);
      expect(res, isNotNull);
      expect(res!.latitude, 30.0754);
      expect(res.longitude, 31.2187);
      expect(res.label, 'مطعم البرنس');
    });

    test('extractLabel extracts Arabic query from search API URL', () {
      const url = 'https://www.google.com/maps/search/?api=1&query=%D9%85%D8%B7%D8%B9%D9%85+%D8%A7%D9%84%D8%A8%D8%B1%D9%86%D8%B3';
      final label = GeoUriParser.extractLabel(url);
      expect(label, 'مطعم البرنس');
    });
  });
}
