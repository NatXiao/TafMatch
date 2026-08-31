

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransportsApi {

  static Future<http.Response> findTransport(String start, String end, DateTime date) {
    return http.get(Uri.parse('http://transport.opendata.ch/v1/connections?${buildConnectionParameters(start, end, date)}'));
  }

  static String buildConnectionParameters(String from, String to, DateTime date) {
    final formatter = DateFormat("yyyy-MM-dd");
    return "from=$from&to=$to&date=${formatter.format(date)}&time=${DateFormat.Hm().format(date)}";
  }

  static Future<http.Response> findLocation(double latitude, double longitude) {
    return http.get(Uri.parse('http://transport.opendata.ch/v1/locations?${buildLocationParameters(latitude, longitude)}'));
  }

  static String buildLocationParameters(double latitude, double longitude) {
    return "x=$latitude&y=$longitude";
  }

  static Future<http.Response> findLocationByName(String name) {
    return http.get(Uri.parse('http://transport.opendata.ch/v1/locations?${buildLocationByNameParameters(name)}'));
  }

  static String buildLocationByNameParameters(String name) {
    return "query=$name";
  }

}