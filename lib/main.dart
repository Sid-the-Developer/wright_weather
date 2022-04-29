import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:geocoder/geocoder.dart';
// import 'package:geocode/geocode.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locationData.dart';
import 'splashscreen.dart';

/// global variables for access in other files
late SharedPreferences prefs;
late bool celsius;
late bool dark;
late bool detailedView;
List<Location> locations = [];
ValueNotifier<List<Location>> locationsNotifier = ValueNotifier<List<Location>>(locations);
late List cityList;
bool prefsSet = false;
/// Geocode plugin initialization
// GeoCode geocode = GeoCode();

/// key to insert and remove items in animated list
GlobalKey<AnimatedListState> listKey = GlobalKey();

GlobalKey<AnimatedListState> detailKey = GlobalKey();

/// global methods for [detailedPage.dart]
/// I really need more organization of files...
toCelsius(temp) =>
    temp == null ? '' : ((temp - 32) * 5.0 / 9).round().toString() + '°';

showSnackbar(BuildContext context, String text,
    {SnackBarAction? action}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(),
      ),
      action: action));
}

/// adds the passed location in locations
/// TODO MAKE IT SPEEEEED
Future<void> addLocation(BuildContext context, Location location) async {
  if (!locations.contains(location)) {
    // Coordinates coordinates = await geocode.forwardGeocoding(address: location.name);
    List<geocode.Location> addresses = await geocode.locationFromAddress(location.name);
    // Deprecated Geocoder plugin
    // List<Address> addresses =
    //     await Geocoder.local.findAddressesFromQuery('${location.name}');

    location.lon = addresses.first.longitude;
    location.lat = addresses.first.latitude;

    void value = await location.updateForecast(context);
    locations.add(location);
    // insert location before getting forecast for latency
    insertListItem(locations.indexOf(location));
    return value;
  } else {
    showSnackbar(
      context,
      '${location.name} already added',
    );
  }
}

void removeLocation(Location location) {
  /// removes with Dismissible swipe
  int index = locations.indexOf(location);
  locations.remove(location);
  if (prefsSet) prefs.setString('locations', Location.encodeList(locations));
  listKey.currentState?.removeItem(index, (context, animation) => Container(),
      duration: Duration(milliseconds: 500));
}


/// global version no longer needed b/c detailedPage uses PageView
/// TODO find a way to show new item after its added
insertListItem(int index) {
  listKey.currentState
      ?.insertItem(index, duration: Duration(milliseconds: 500));
}

/// returns text for chance of precipitation
Widget precip(String forecast) {
  if (forecast.contains('%')) {
    int precipIndex = forecast.indexOf('%');
    return Text(
      '${forecast.substring(precipIndex - 3, precipIndex + 1)}',
      style: GoogleFonts.lato(
        color: Colors.lightBlue,
      ),
    );
  }
  // returns empty Text instead of Container in order to align 7-day icons
  return Text(' ');
}

/// returns weather icon for forecast
Widget icon(String forecast,
    {double size = 50, bool label = false, bool night = false}) {
  String? path;
  String description = '';

  /// searches for each keyword to find correct icon
  if (forecast.contains(RegExp('storms', caseSensitive: false))) {
    if (forecast.contains(RegExp('sunny', caseSensitive: false))) {
      path = 'stormy-day.png';
      description = 'Scattered Thunderstorms';
    } else {
      night ? path = 'stormy-night.png' : path = 'storm.png';
      description = 'Thunderstorm';
    }
  } else if (forecast.contains(RegExp('hail', caseSensitive: false)) ||
      forecast.contains(RegExp('sleet', caseSensitive: false))) {
    path = 'hail.png';
    description = 'Hail';
  } else if (forecast.contains(RegExp('snow', caseSensitive: false))) {
    path = 'snow.png';
    description = 'Snow';
  } else if (forecast.contains(RegExp('snow mix', caseSensitive: false))) {
    path = 'sleet.png';
    description = 'Sleet';
  } else if (forecast.contains(RegExp('showers', caseSensitive: false)) ||
      forecast.contains(RegExp('drizzle', caseSensitive: false)) ||
      forecast.contains(RegExp('rain', caseSensitive: false))) {
    if (forecast.contains(RegExp('sunny', caseSensitive: false))) {
      path = 'rain-cloud-day.png';
      description = 'Scattered Showers';
    } else {
      path = 'rain.png';
      description = 'Showers';
    }
  } else if (forecast.contains(RegExp('fog', caseSensitive: false))) {
    path = 'fog.png';
    description = 'Foggy';
  } else if (forecast
      .contains(RegExp('partly cloudy', caseSensitive: false))) {
    night ? path = 'night.png' : path = 'partly-cloudy-day.png';
    description = 'Partly Cloudy';
  } else if (forecast.contains(RegExp('sunny', caseSensitive: false))) {
    path = 'sun.png';
    forecast.contains(RegExp('mostly sunny', caseSensitive: false))
        ? description = 'Mostly Sunny'
        : description = 'Sunny';
  } else if (forecast.contains(RegExp('cloud', caseSensitive: false))) {
    path = 'clouds.png';
    description = 'Cloudy';
  } else if (forecast.contains(RegExp('clear', caseSensitive: false))) {
    path = 'sun.png';
    description = 'Clear';
  }

  return path != null
      ? Column(
          children: [
            Image.asset(
              'assets/weather_icons/$path',
              width: size,
              height: size,
            ),
            Container(
                width: size,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label ? description : '',
                        style: GoogleFonts.lato(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ))
          ],
        )

      /// idk why but the Container needs size to avoid error
      : Container(
          width: 1,
          height: 1,
        );
}

/// builds seven day row with icons
Widget buildSevenDay(Location location) {
  return Container(
    height: 180,
    child: ListView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      children: List.generate(13, (index) {
        /// returns item only if its the day item in NWS API
        if ((location.forecast.getDaily(index, 'isDaytime') ?? false)) {
          return Padding(
            padding: EdgeInsets.fromLTRB(15, 25, 15, 25),
            child: Column(
              children: [
                precip(location.forecast.getDaily(index, 'detailedForecast')),
                icon(location.forecast.getDaily(index, 'shortForecast')),

                /// text for the day
                Center(
                    child: Text(
                  '${location.forecast.getDaily(index, 'name')}',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                )),

                /// temperature text
                Center(
                  child: Text(
                    celsius
                        ? '${toCelsius(location.getTemp(day: index))} / '
                            '${toCelsius(location.getTemp(day: index + 1))}'
                        : '${(location.getTemp(day: index).toString() + '°').contains('null') ? '' : location.getTemp(day: index).toString() + '°'} / '
                            '${(location.getTemp(day: index + 1).toString() + '°').contains('null') ? '' : location.getTemp(day: index + 1).toString() + '°'}',
                    style: GoogleFonts.lato(),
                  ),
                )
              ],
            ),
          );
        }

        /// the NWS has day and night separate, so Container is returned for night
        return Container();
      }),
    ),
  );
}

main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Color(0xff24A4FE),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  /// This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wright Weather',
      debugShowCheckedModeBanner: false,
      // TODO actually use theme
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColorLight: Color(0xff24A4FE),
        dividerColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.deepOrange[300],
          primaryColorDark: Colors.blue[900],
        ),


        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashPage(),
    );
  }
}
