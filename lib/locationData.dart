import 'dart:convert';

import 'forecast.dart';

class Location {
  Location(
      {this.name = '',
      this.time = '',
      this.lon,
      this.lat,
      this.isCurrentLocation = false});
  String name;
  String time;
  double lon;
  double lat;
  Forecast forecast;
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
        'forecast': location.forecast?.toJson(),
        'isCurrentLocation': location.isCurrentLocation
      };

  getShort({int day = -1, int hour}) => day != -1
      ? forecast?.getDaily(day, 'shortForecast')
      : forecast?.getHourly(hour, 'shortForecast');
  getDetailed(int day) => forecast?.getDaily(day, 'detailedForecast');
  getTemp({int day = -1, int hour}) => day != -1
      ? forecast?.getDaily(day, 'temperature')
      : forecast?.getHourly(day, 'temperature');

  /// encode list of Locations to JSON String to save in SHaredPreferences
  static String encodeList(List<Location> locations) =>
      jsonEncode(locations.map((location) => toJson(location)).toList());

  /// decode JSON string from SharedPreferences into Location objects
  static List<Location> decodeList(String json) => (jsonDecode(json) as List)
      .map((item) => Location.fromJson(item))
      .toList();

  @override
  bool operator ==(other) {
    return name == other.name;
  }
}
