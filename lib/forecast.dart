import 'dart:convert';

import 'package:http/http.dart' as http;

class Forecast {
  Forecast(
      {this.days = const [],
      this.hours = const [],
      this.conditionsSet = false});

  dynamic days = [];
  dynamic hours;
  String forecastUrl = '';
  String hourlyForecastUrl = '';
  bool conditionsSet = false;

  Forecast.fromJSON(Map<String, dynamic> data) {
    // parses raw data from http request
    try {
      forecastUrl = data['properties']['forecast'];
      hourlyForecastUrl = data['properties']['forecastHourly'];
    } on NoSuchMethodError {
      // parses saved data from SharedPrefs
      try {
        days = data['days'];
        hours = data['hours'];
        forecastUrl = data['forecastUrl'];
        hourlyForecastUrl = data['hourlyForecastUrl'];
        conditionsSet = data['conditionsSet'];
      } on NoSuchMethodError {}
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'hours': hours,
      'forecastUrl': forecastUrl,
      'hourlyForecastUrl': hourlyForecastUrl,
      'conditionsSet': conditionsSet
    };
  }

  /// sets [days] and [hours] to correct NWS JSON
  setConditions() async {
    try {
      String response = await http.read(Uri.parse(forecastUrl),
          headers: {'User-Agent': 'Wright Weather App, swright3743@gmail.com'});
      Map data = await json.decode(response);
      try {
        days = data['properties']['periods'];
      } on Exception {}

      String hourlyResponse = await http.read(Uri.parse(hourlyForecastUrl),
          headers: {'User-Agent': 'Wright Weather App, swright3743@gmail.com'});
      Map hourlyData = await json.decode(hourlyResponse);
      try {
        hours = hourlyData['properties']['periods'];
      } on Exception {}

      conditionsSet = true;
    } on Exception {}
  }

  /// get daily forecast info
  getDaily(int day, String item) {
    if (conditionsSet)
      return days[day][item];
    else {
      return null;
    }
  }

  /// get hourly forecast info
  getHourly(int hour, String item) {
    if (conditionsSet)
      return hours[hour][item];
    else {
      return '';
    }
  }
}
