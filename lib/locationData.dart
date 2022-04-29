import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'detailedPage.dart';
import 'forecast.dart';
import 'listPage.dart';
import 'main.dart';

class Location {
  Location(
      {this.name = '',
      this.time = '',
      this.lon = 0,
      this.lat = 0,
      this.isCurrentLocation = false});

  String name;
  String time;
  double lon;
  double lat;
  Forecast forecast = Forecast();
  bool isCurrentLocation;

  Location.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        time = json['time'],
        lon = json['lon'],
        lat = json['lat'],
        forecast = json['forecast'] != null
            ? Forecast.fromJSON(json['forecast'])
            : Forecast(),
        isCurrentLocation = json['isCurrentLocation'];

  static Map<String, dynamic> toJson(Location location) => {
        'name': location.name,
        'time': location.time,
        'lon': location.lon,
        'lat': location.lat,
        'forecast': location.forecast.toJson(),
        'isCurrentLocation': location.isCurrentLocation
      };

  /// gets all forecasts from NWS and sets them in forecast object of each location
  /// adds to animated list
  /// idk if its me but the NWS fails to return forecast a lot
  /// TODO tell govt to fix NWS
  Future<void> getForecast() async {
    try {
      String response = await http.read(
          Uri.parse('https://api.weather.gov/points/${lat},${lon}'),
          headers: {'User-Agent': 'Wright Weather App, swright3743@gmail.com'});

      forecast = Forecast.fromJSON(json.decode(response));
      time = DateFormat('h:mm a').format(DateTime.now());
      await forecast.setConditions();

      if (prefsSet)
        prefs.setString('locations', Location.encodeList(locations));
    } on Exception catch (e) {
      throw e;
    }
  }

  /// updates the forecast of the given [location] using
  /// [getForecast]. Displays error [SnackBar] if necessary.
  /// Mostly exists to simplify syntax of calling [getForecast].
  /// TODO: notifyListeners somehow
  Future<void> updateForecast(BuildContext context) async {
    return await getForecast().catchError((e) {
      showSnackbar(
          context, 'Something went wrong while getting forecast for ${name}');
      locations.remove(this);
    });
  }

  /// retrieves short forecast from forecast object. Shorthand method.
  String? getShort({int? day, int? hour}) => day != null
      ? forecast.getDaily(day, 'shortForecast')
      : forecast.getHourly(hour!, 'shortForecast');

  /// retrieves detailed forecast from forecast object. Shorthand method.
  String? getDetailed(int day) => forecast.getDaily(day, 'detailedForecast');

  /// retrieves current temperature from forecast object. Shorthand method.
  getTemp({int? day, int? hour}) => day != null
      ? forecast.getDaily(day, 'temperature')
      : forecast.getHourly(hour!, 'temperature');

  /// encode list of Locations to JSON String to save in SHaredPreferences
  static String encodeList(List<Location> locations) =>
      jsonEncode(locations.map((location) => toJson(location)).toList());

  /// decode JSON string from SharedPreferences into Location objects
  static List<Location> decodeList(String json) => (jsonDecode(json) as List)
      .map((item) => Location.fromJson(item))
      .toList();

  @override
  bool operator ==(Object other) =>
      other is Location ? name == other.name : false;
}
