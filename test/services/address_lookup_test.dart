import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:taf_match/services/address_lookup.dart';

/// Builds a JSON response encoded in UTF-8, as the API does.
http.Response _ok(List<Map<String, dynamic>> results) => http.Response.bytes(
      utf8.encode(jsonEncode({'results': results})),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// An API result reduced to the fields inspected by the parser.
Map<String, dynamic> _result({String? label, String? detail}) => {
      'attrs': {
        if (label != null) 'label': label,
        if (detail != null) 'detail': detail,
      },
    };

/// MockClient that records the call to [close], to test dispose().
class _TrackingClient extends MockClient {
  _TrackingClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  group('search — garde-fou sur la requete', () {
    test('retourne une liste vide sous 3 caracteres, sans appel reseau', () async {
      var called = false;
      final lookup = AddressLookup(
        client: MockClient((_) async {
          called = true;
          return _ok([]);
        }),
      );

      expect(await lookup.search(''), isEmpty);
      expect(await lookup.search('ru'), isEmpty);
      expect(called, isFalse);
    });

    test('les espaces ne comptent pas dans la longueur minimale', () async {
      var called = false;
      final lookup = AddressLookup(
        client: MockClient((_) async {
          called = true;
          return _ok([]);
        }),
      );

      expect(await lookup.search('  ru  '), isEmpty);
      expect(called, isFalse);
    });
  });

  group('search — construction de la requete', () {
    test('appelle le SearchServer de swisstopo avec les bons parametres', () async {
      late Uri captured;
      final lookup = AddressLookup(
        client: MockClient((request) async {
          captured = request.url;
          return _ok([]);
        }),
      );

      await lookup.search('  rue de lausanne  ');

      expect(captured.host, 'api3.geo.admin.ch');
      expect(captured.path, '/rest/services/ech/SearchServer');
      expect(captured.queryParameters, {
        'searchText': 'rue de lausanne', // trimme
        'type': 'locations',
        'origins': 'address',
        'limit': '6', // valeur par defaut
        'sr': '2056',
      });
    });

    test('propage la limite personnalisee', () async {
      late Uri captured;
      final lookup = AddressLookup(
        client: MockClient((request) async {
          captured = request.url;
          return _ok([]);
        }),
      );

      await lookup.search('sion', limit: 20);

      expect(captured.queryParameters['limit'], '20');
    });
  });

  group('search — parsing des resultats', () {
    Future<List<AddressSuggestion>> searchWith(
      List<Map<String, dynamic>> results,
    ) {
      final lookup = AddressLookup(client: MockClient((_) async => _ok(results)));
      return lookup.search('lausanne');
    }

    test('retire le balisage HTML et normalise les espaces du label', () async {
      final suggestions = await searchWith([
        _result(label: '<b>Rue de Lausanne 1</b>   1950   Sion'),
      ]);

      expect(suggestions.single.label, 'Rue de Lausanne 1 1950 Sion');
    });

    test('conserve les accents (decodage UTF-8)', () async {
      final suggestions = await searchWith([
        _result(label: '<b>Route de Genève 3</b> 1004 Lausanne'),
      ]);

      expect(suggestions.single.label, 'Route de Genève 3 1004 Lausanne');
    });

    test('extrait le canton en dernier jeton de detail', () async {
      final suggestions = await searchWith([
        _result(
          label: '<b>Paradeplatz 2</b> 8001 Zürich',
          detail: 'paradeplatz 2 8001 zuerich 261 zuerich ch zh',
        ),
      ]);

      expect(suggestions.single.canton, 'ZH');
    });

    test('canton vide si le dernier jeton n\'est pas un canton suisse', () async {
      final suggestions = await searchWith([
        _result(
          label: '<b>Städtle 1</b> 9490 Vaduz',
          detail: 'staedtle 1 9490 vaduz li',
        ),
      ]);

      expect(suggestions.single.canton, isEmpty);
    });

    test('canton vide si detail est absent', () async {
      final suggestions = await searchWith([_result(label: 'Rue du Nord 4')]);

      expect(suggestions.single.canton, isEmpty);
    });

    test('ecarte les suggestions sans label exploitable', () async {
      final suggestions = await searchWith([
        _result(label: '', detail: 'x vd'),
        _result(label: '<b></b>', detail: 'x vd'),
        _result(label: 'Rue du Nord 4', detail: 'rue du nord 4 2300 la chaux-de-fonds ch ne'),
      ]);

      expect(suggestions, hasLength(1));
      expect(suggestions.single.label, 'Rue du Nord 4');
      expect(suggestions.single.canton, 'NE');
    });

    test('preserve l\'ordre renvoye par l\'API', () async {
      final suggestions = await searchWith([
        _result(label: 'Rue A 1'),
        _result(label: 'Rue B 2'),
        _result(label: 'Rue C 3'),
      ]);

      expect(
        suggestions.map((s) => s.label),
        ['Rue A 1', 'Rue B 2', 'Rue C 3'],
      );
    });

    test('retourne une liste vide si la cle results est absente', () async {
      final lookup = AddressLookup(
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode('{}'), 200),
        ),
      );

      expect(await lookup.search('lausanne'), isEmpty);
    });
  });

  group('search — degradation en cas de probleme', () {
    test('retourne une liste vide sur un statut non-200', () async {
      for (final status in [400, 429, 500, 503]) {
        final lookup = AddressLookup(
          client: MockClient((_) async => http.Response('boom', status)),
        );

        expect(await lookup.search('lausanne'), isEmpty, reason: 'statut $status');
      }
    });

    test('retourne une liste vide si le client leve (hors ligne)', () async {
      final lookup = AddressLookup(
        client: MockClient((_) async => throw const SocketExceptionStub()),
      );

      expect(await lookup.search('lausanne'), isEmpty);
    });

    test('retourne une liste vide si le corps n\'est pas du JSON valide', () async {
      final lookup = AddressLookup(
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode('<html>503</html>'), 200),
        ),
      );

      expect(await lookup.search('lausanne'), isEmpty);
    });

    test('un resultat malforme fait tomber toute la liste (comportement actuel)',
        () async {
      final lookup = AddressLookup(
        client: MockClient((_) async => _ok([
              {'attrs': null},
              _result(label: 'Rue du Nord 4'),
            ])),
      );

      // Documents the current behavior: casting `attrs` throws, and the catch
      // swallows the error and the valid suggestion is lost.
      expect(await lookup.search('lausanne'), isEmpty);
    });
  });

  group('dispose', () {
    test('ferme le client HTTP', () {
      final client = _TrackingClient((_) async => _ok([]));

      AddressLookup(client: client).dispose();

      expect(client.closed, isTrue);
    });
  });
}

/// Any exception to simulate a network failure without importing dart:io.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}