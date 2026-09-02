

import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:taf_match/utils/transports_api.dart';

class LocationUtils {

  /// Return latitude and longitude of geolocalisation
  static Future<Position> findDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  static Future<String?> getLocationName(double latitude, double longitude) async {

    final rawLocations = await TransportsApi.findLocation(latitude, longitude);
    final locations = jsonDecode(rawLocations.body) as Map<String, dynamic>;

    String? location;
    if (locations["stations"] != null) {
      locations['stations'].forEach((v) {
        location ??= v["name"];
      });
    }

    return location;
  }

  static Future<(double, double)?> getLocationCoord(String address) async {

    final rawLocations = await TransportsApi.findLocationByName(address);
    final locations = jsonDecode(rawLocations.body) as Map<String, dynamic>;

    double jobLatitude = 0;
    double jobLongitude = 0;
    bool jobLocationFound = false;
    if (locations["stations"] != null) {
      locations['stations'].forEach((v) {
        if (!jobLocationFound && v["coordinate"]["x"] != null && v["coordinate"]["y"] != null) {
          jobLatitude = v["coordinate"]["x"];
          jobLongitude = v["coordinate"]["y"];
          jobLocationFound = true;
        }
      });
    }

    return jobLocationFound ? (jobLatitude, jobLongitude) : null;
  }

}