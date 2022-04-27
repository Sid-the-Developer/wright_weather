import 'dart:convert';

import 'forecast.dart';

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
  bool operator ==(Object other) => other is Location ? name == other.name : false;
}
