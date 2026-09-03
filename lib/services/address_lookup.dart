import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// An address suggestion returned by the swisstopo API.
class AddressSuggestion {
  const AddressSuggestion({required this.label, required this.canton});

  /// Formatted address, ready to be inserted into the field.
  final String label;

  /// Canton abbreviation, or an empty string if the API did not provide one.
  final String canton;
}

/// Swiss address autocomplete using the official swisstopo API.
///
/// Free and keyless. In return, swisstopo asks clients to avoid high-intensity
/// requests: the field must be debounced on the client side.
class AddressLookup {
  AddressLookup({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint =
      'https://api3.geo.admin.ch/rest/services/ech/SearchServer';

  static const _cantons = {
    'AG', 'AI', 'AR', 'BE', 'BL', 'BS', 'FR', 'GE', 'GL', 'GR', 'JU', 'LU',
    'NE', 'NW', 'OW', 'SG', 'SH', 'SO', 'SZ', 'TG', 'TI', 'UR', 'VD', 'VS',
    'ZG', 'ZH',
  };

  Future<List<AddressSuggestion>> search(String query, {int limit = 6}) async {
    if (query.trim().length < 3) return const [];

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'searchText': query.trim(),
      'type': 'locations',
      'origins': 'address', // seulement des adresses, pas des lacs ni des parcelles
      'limit': '$limit',
      'sr': '2056',
    });

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final results = (body['results'] as List?) ?? const [];

      return results
          .map((r) => (r as Map<String, dynamic>)['attrs'] as Map<String, dynamic>)
          .map((attrs) => AddressSuggestion(
                label: _stripTags('${attrs['label'] ?? ''}'),
                canton: _cantonFrom('${attrs['detail'] ?? ''}'),
              ))
          .where((s) => s.label.isNotEmpty)
          .toList();
    } catch (_) {
      // Offline or API unavailable: no suggestions are shown, but manual entry
      // remains possible. Never block posting creation because of this.
      return const [];
    }
  }

  /// The label contains markup: "<b>Rue de Lausanne 1</b> 1950 Sion".
  static String _stripTags(String raw) =>
      raw.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The canton is the last token in `detail`, after the country code:
  /// "paradeplatz 2 8001 zuerich 261 zuerich ch zh" -> "ZH".
  /// It is missing for some addresses, especially in Liechtenstein.
  static String _cantonFrom(String detail) {
    final tokens = detail.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return '';
    final last = tokens.last.toUpperCase();
    return _cantons.contains(last) ? last : '';
  }

  void dispose() => _client.close();
}