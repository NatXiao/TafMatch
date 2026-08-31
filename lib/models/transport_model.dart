
class TransportModel {
  final DateTime departure;
  final DateTime arrival;
  final Duration duration;
  final String name;

  TransportModel({
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'departure': departure,
      'arrival': arrival,
      'duration': duration,
      'name': name,
    };
  }

  factory TransportModel.fromMap(Map<String, dynamic> map) {

    var departure = DateTime.parse(map["from"]["departure"]);
    var arrival = DateTime.parse(map["to"]["arrival"]);

    departure = departure.add(parseTimezoneOffset(map["from"]["departure"]));
    arrival = arrival.add(parseTimezoneOffset(map["to"]["arrival"]));

    String name = "";

    map["sections"].forEach((v) {
      if (v["journey"] != null) {
        name += "${v["journey"]["category"]} ${v["journey"]["number"]} - ";
      }
    });

    name = name.substring(0, name.length - 3);

    return TransportModel(
      departure: departure,
      arrival: arrival,
      duration: arrival.difference(departure),
      name: name,
    );
  }

  static Duration parseTimezoneOffset(String date) {

    final h = int.parse(date.substring(date.length - 4, date.length - 2));
    final min = int.parse(date.substring(date.length - 2));

    return Duration(hours: h, minutes: min);
  }

}