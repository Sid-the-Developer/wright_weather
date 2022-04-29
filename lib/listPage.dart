import 'dart:async';
import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import 'package:geocoder/geocoder.dart';
// import 'package:geocode/geocode.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as location_plugin;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wright_weather/detailedPage.dart';
import 'package:wright_weather/search.dart';

import 'locationData.dart';
import 'main.dart';
import 'settings.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  static of(BuildContext context, {bool root = false}) => root
      ? context.findRootAncestorStateOfType<_MainPageState>()
      : context.findAncestorStateOfType<_MainPageState>();

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  /// refreshes location and forecast every 6 hours
  late Timer timer;

  /// key to insert and remove items in animated list
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  /// keeps track of list view or card view
  bool listView = false;

  /// ensures enable location services dialog is only shown once
  bool dialogShown = false;

  /// list view animated icon controller
  late AnimationController _iconController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 300));

  /// used to animate to position
  ScrollController _scrollController = ScrollController();

  /// FadeScaleTransition controller (search and FAB)
  late AnimationController _fadeScaleController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 300));

  /// instance variable so that [currentLocation] is not null
  location_plugin.LocationData currentLocation =
      location_plugin.LocationData.fromMap(Map());
  location_plugin.Location locator = location_plugin.Location();

  /// get (and add if need be) current location to locations list
  Future<void> _getCurrentLocation() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      // not tested but should
      if (await Permission.locationAlways.isGranted) {
        locator.onLocationChanged.listen((newLocation) async {
          // update forecast
          if (currentLocation != newLocation) {
            currentLocation = newLocation;
            await _addCurrentLocation();
          } else {
            locations[0].updateForecast(context);
          }
        });
      } else if (await Permission.location.request().isGranted) {
        location_plugin.LocationData newLocation = await locator.getLocation();
        // update forecast
        if (currentLocation != newLocation) {
          currentLocation = newLocation;
          await _addCurrentLocation();
        } else {
          locations[0].updateForecast(context);
        }
      } else if (!dialogShown) {
        // location services prompt logic
        dialogShown = true;
        showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: Text(
                  'Enable location services',
                  style: GoogleFonts.lato(),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 100, right: 100),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        primary: Colors.blue[600],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _getCurrentLocation();
                      },
                      child: Text(
                        'OK',
                        style: GoogleFonts.lato(color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            });
      }
    }
  }

  /// constructs [Location] object and adds current location to the list
  /// Returns the constructed object as [Future]
  Future<Location> _addCurrentLocation() async {
    // Address address = await geocode.reverseGeocoding(latitude: currentLocation?.latitude,
    //     longitude: currentLocation?.longitude);
    List<geocode.Placemark> addresses = await geocode.placemarkFromCoordinates(
        currentLocation.latitude ?? 0, currentLocation.longitude ?? 0);

    Location location = Location(
      name:
          '${addresses.first.locality}, ${addresses.first.administrativeArea}',
      lon: currentLocation.longitude!,
      lat: currentLocation.latitude!,
      isCurrentLocation: true,
    );
    await location.updateForecast(context);

    if (locations.isNotEmpty && locations[0].isCurrentLocation) {
      locations[0] = location;
    } else {
      locations.insert(0, location);
      insertListItem(0);
    }
    return location;
  }

  /// initializes [cityList] to open search faster
  buildCityList() async {
    String data = await rootBundle.loadString('assets/usaCities.json');
    cityList = await json.decode(data);
  }

  /// sets variables that need context and begins to get current location.
  /// getCurrentLocation() is in initState() so that it is called once at
  /// the beginning of the app.
  @override
  void initState() {
    super.initState();

    //set up shared preferences
    SharedPreferences.getInstance().then((SharedPreferences value) {
      prefs = value;
      // prefs.clear();
      // initialize settings
      locations = Location.decodeList(prefs.getString('locations') ?? "[]");
      celsius = prefs.getBool('celsius') ?? false;
      dark = prefs.getBool('dark') ?? false;
      detailedView = prefs.getBool('detailedView') ?? false;
      listView = prefs.getBool('listView') ?? false;
      if (listView) _iconController.forward();

      prefsSet = true;
      // set forecast data
      Future.forEach(locations, (Location location) {
        location.updateForecast(context);
        insertListItem(locations.indexOf(location));
      });

      if (detailedView)
        Navigator.of(context).push(SharedAxisPageRoute(DetailedPage(0),
            transitionType: SharedAxisTransitionType.vertical));
    });

    buildCityList();

    _getCurrentLocation();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      Future.delayed(Duration(milliseconds: 200), () {
        _fadeScaleController.forward();
      });

      //timer to update current location and forecasts
      timer = Timer.periodic(Duration(hours: 6), (timer) {
        refresh();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  // TODO: remove setState
  Future<void> refresh() {
    return Future.forEach(locations, (Location location) {
      if (!location.isCurrentLocation) location.updateForecast(context);
    }).then((value) {
      _getCurrentLocation();
      setState((){});
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      floatingActionButton: FadeScaleTransition(
        animation: _fadeScaleController,
        child: FloatingActionButton(
          onPressed: () =>
              showSearch(context: context, delegate: Delegate()).then((value) {
            if (value != null)
              addLocation(context, Location(name: value)).then((_) {
                return _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOutCirc);
              });
          }),
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: Colors.black.withOpacity(.5),
        elevation: 0,
        child: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).push(SharedAxisPageRoute(
                    SettingsPage(),
                    transitionType: SharedAxisTransitionType.horizontal))),
            Spacer(),
            IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.list_view,
                progress: _iconController,
                color: Colors.white,
              ),
              onPressed: () {
                listView
                    ? _iconController.reverse()
                    : _iconController.forward();

                setState(() => listView = !listView);
                prefs.setBool('listView', listView);
              },
            )
          ],
        ),
      ),
      body: NestedScrollView(
        physics: BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        /// TODO fix the sliver bar not retracting due  to ListView scroll controller
        headerSliverBuilder: (context, index) {
          return [
            SliverAppBar(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              backgroundColor: Color(0xff24A4FE),
              title: FadeScaleTransition(
                animation: _fadeScaleController,
                child: Center(
                  child: RichText(
                      text: TextSpan(
                          text: 'WRIGHT ',
                          style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          children: [
                        TextSpan(
                          text: 'WEATHER',
                          style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        )
                      ])),
                ),
              ),
            ),

            /// old app bar  with search container
//            SliverAppBar(
//              primary: true,
//              brightness: Brightness.light,
//              snap: true,
//              floating: true,
//              title: FadeScaleTransition(
//                child: buildSearchBar(),
//                animation: fadeScaleController,
//              ),
//              elevation: 0,
//              backgroundColor: Colors.transparent,
//            )
          ];
        },
        body: RefreshIndicator(
          strokeWidth: 3,
          key: Key('refresh'),
          onRefresh: refresh,
          color: Theme.of(context).colorScheme.secondary,
          child: ValueListenableBuilder(
            valueListenable: locationsNotifier,
            builder: (context, value, child) => AnimatedList(
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                key: listKey,
                initialItemCount: locations.length,
                itemBuilder: (context, index, Animation animation) {
                  return buildDraggable(locations[index], animation);
                }),
          ),
        ),
      ),
    );
  }

  /// builds draggable container for card/list tile
  /// TODO actually implement drag system
  Widget buildDraggable(Location location, Animation animation) {
    return FadeTransition(
      opacity: animation.drive(Tween(begin: 0, end: 1)),
      child: SlideTransition(
          position: animation.drive(
              Tween(begin: Offset(0, .1), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCirc))),
          child: LongPressDraggable(
              feedback: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                      location.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.questrial(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.blue),
                    ),
                  ),
                ),
              ),
              childWhenDragging: Container(),
              child: Dismissible(
                key: Key('${location.name}'),
                onDismissed: (direction) {
                  int index = locations.indexOf(location);
                  removeLocation(location);
                  showSnackbar(context, '${location.name} removed',
                      action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            locations.insert(index, location);
                            insertListItem(index);
                          }));
                },
                child: Column(
                  children: [
                    AnimatedCrossFade(
                      duration: Duration(milliseconds: 300),
                      crossFadeState: listView
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstCurve: Curves.decelerate,
                      secondCurve: Curves.decelerate,
                      sizeCurve: Curves.decelerate,
                      firstChild: buildCard(location),
                      secondChild: buildListTile(location),
                    ),
                    DragTarget(
                      builder:
                          (BuildContext context, List accepted, List rejected) {
                        return accepted.isEmpty
                            ? Container()
                            : Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                color: Colors.grey,
                                child: Text('${accepted[0]}'),
                              );
                      },
                    )
                  ],
                ),
              ))),
    );
  }

  /// builds each card for the card view mode
  Widget buildCard(Location location) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: .5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,

      /// opens detailed view on tap
      child: InkWell(
        onTap: () => Navigator.of(context).push(SharedAxisPageRoute(
            DetailedPage(locations.indexOf(location)),
            transitionType: SharedAxisTransitionType.vertical,
            duration: Duration(milliseconds: 500))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              children: [
                /// current location and city name header
                Row(children: [
                  location.isCurrentLocation
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                          ),
                        )
                      : Container(),
                  Expanded(
                      flex: 7,
                      child: Hero(
                        tag: '${location.name}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            location.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.questrial(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Colors.blue),
                          ),
                        ),
                      )),
                  Spacer(),
                  Flexible(
                    flex: 2,
                    child: Hero(
                        tag: '${location.name}Temp',
                        child: Material(
                          color: Colors.transparent,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                                celsius
                                    ? ' ${toCelsius(location.getTemp(day: 0))}'
                                    : ' ${(location.getTemp(day: 0).toString() + '°').contains('null') ? '' : location.getTemp(day: 0).toString() + '°'}',
                                style: GoogleFonts.questrial(
                                    fontSize: 60,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )),
                  )
                ]),
                RichText(
                    text: TextSpan(
                        text:
                            '${location.forecast.getDaily(0, 'name') ?? 'Loading...'} '
                            '${location.forecast.getDaily(0, 'name') != null ? location.time : ''}\n',
                        style: GoogleFonts.lato(
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        children: [
                      TextSpan(
                          text: location.getDetailed(0),
                          style: GoogleFonts.lato(
                              fontSize: 18,
                              color: Colors.black,
                              fontStyle: FontStyle.italic))
                    ]))
              ],
            )),
      ),
    );
  }

  /// builds each list tile for the list view mode
  Widget buildListTile(Location location) {
    return Column(
      children: [
        Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
              maintainState: true,
              children: [
                buildSevenDay(location),
                Divider(
                  color: Colors.black,
                  indent: 30,
                  endIndent: 30,
                )
              ],
              title: Row(
                children: [
                  location.isCurrentLocation
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(0, 5, 12, 5),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                          ),
                        )
                      : Container(),
                  Flexible(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: location.name,
                        style: GoogleFonts.questrial(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Text(
                  celsius
                      ? ' ${toCelsius(location.getTemp(day: 0))}'
                      : ' ${(location.getTemp(day: 0).toString() + '°').contains('null') ? '' : location.getTemp(day: 0).toString() + '°'}',
                  style: GoogleFonts.questrial(
                      fontSize: 36,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
              subtitle: Text('${location.getShort(day: 0) ?? 'Loading...'}',
                  style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black,
                      fontStyle: FontStyle.italic))),
        )
      ],
    );
  }

  /// builds app bar search bar with failed open container
  /// NO LONGER USED
//  Widget buildSearchBar() {
//    return GestureDetector(
//      onTap: () =>
//          showSearch(context: context, delegate: Delegate()).then((value) {
//        if (value != null) addLocation(Location(name: value), _scaffoldKey);
//            _scrollController.animateTo(
//                _scrollController.position.maxScrollExtent,
//                duration: Duration(milliseconds: 500),
//                curve: Curves.easeInOutCirc);
//      }),
//      child: Card(
//        elevation: 5,
//        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//        child: Padding(
//          padding: const EdgeInsets.all(8.0),
//          child: Row(
//            children: [
//              Icon(
//                Icons.search,
//                size: 30,
//                color: Colors.grey,
//              ),
//              SizedBox(
//                width: 10,
//              ),
//              Text('Search locations',
//                  style: GoogleFonts.lato(
//                      color: Colors.grey,
//                      fontSize: 20,
//                      fontStyle: FontStyle.italic))
//            ],
//          ),
//        ),
//      ),
//    );
//  }
}

/// allows for easier syntax when using SharedAxisTransition
class SharedAxisPageRoute extends PageRouteBuilder {
  SharedAxisPageRoute(Widget page,
      {required SharedAxisTransitionType transitionType,
      Duration duration = const Duration(milliseconds: 300)})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: duration,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
        );
}
