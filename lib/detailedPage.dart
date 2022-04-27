import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import 'locationData.dart';
import 'main.dart';
import 'search.dart';

//initial page index

class DetailedPage extends StatefulWidget {
  DetailedPage(this.index, {Key? key}) : super(key: key);
  final int index;

  @override
  DetailedPageState createState() => DetailedPageState(index);
}

class DetailedPageState extends State<DetailedPage> {
  DetailedPageState(this.initialPage);

  int initialPage;
  late PageController _controller =
      PageController(viewportFraction: .9, initialPage: initialPage);

  PageScrollPhysics pagePhysics = PageScrollPhysics();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      /// adding location takes a while and list doesn't navigate there to show it
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            showSearch(context: context, delegate: Delegate()).then((value) {
          Location location = Location(name: value);
          if (value != null)
            addLocation(context, location).then((_) {
              // setState(() {}); animation could automatically setstate

              _controller.animateToPage(locations.indexOf(location),
                  duration: Duration(milliseconds: 1000),
                  curve: /*TODO test curve*/ Curves.easeInOutCirc);
            });
        }),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: PageView.builder(
          key: detailKey,
          itemCount: locations.length,
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          controller: _controller,
          itemBuilder: (context, index) {
            Location location = locations[index];
            return Dismissible(

                ///TODO fix the dismissible lag
                direction: DismissDirection.up,
                key: Key(location.name),
                onDismissed: (direction) {
                  int index = locations.indexOf(location);
                  setState(() {
                    removeLocation(location);
                  });

                  /// undo location removal snackbar
                  showSnackbar(context, '${location.name} removed',
                      action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            setState(() => locations.insert(index, location));
                            _controller.animateToPage(
                                locations.indexOf(location),
                                duration: Duration(seconds: 1),
                                curve: Curves.easeInOutCirc);
                            // insertLocation(index);
                          }));
                },

                /// column of city name and list of cards
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32, top: 32),
                      child: GestureDetector(
                        onVerticalDragUpdate: (DragUpdateDetails details) {
                          if (details.primaryDelta! > 5) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Hero(
                          tag: '${location.name}',
                          child: Material(
                              color: Colors.transparent,

                              /// city name and location icon
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    location.isCurrentLocation
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Icon(
                                              Icons.location_on,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        : Container(),
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, right: 16),
                                        child: Text(
                                          location.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.questrial(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 30,
                                              color: Colors.blue),
                                        ),
                                      ),
                                    ),
                                  ])),
                        ),
                      ),
                    ),

                    /// list of cards
                    Expanded(
                      child: ListView(
                        physics: BouncingScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _buildMainCard(location),
                          _buildTempGraph(location),
                          _buildDetails(location)
                        ],
                      ),
                    ),
                  ],
                ));
          }),
    ));
  }

  Widget _buildMainCard(Location location) {
    int index = locations.indexOf(location);
    return Card(
      elevation: .75,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),

          /// column of forecast icon, temp, description, and 7-day
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(
                        flex: 2,
                      ),
                      Hero(
                        tag: '${location.name}Temp',

                        /// Material widget eliminates striped background during Hero animation
                        child: Material(
                          color: Colors.transparent,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                                celsius
                                    ? ' ${toCelsius(location.getTemp(day: 0))}'
                                    : ' ${(location.getTemp(day: 0).toString() + '°').contains('null') ? '' : location.getTemp(day: 0).toString() + '°'}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.questrial(
                                    fontSize: 60,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Spacer(),
                      icon(
                          location.getShort(day: index) ??
                              '',
                          size: 75,
                          label: true),
                      Spacer(
                        flex: 2,
                      )
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                      '${location.forecast.getDaily(0, 'name') /* ?? 'Loading...' */} '
                      '${location.forecast.getDaily(0, 'name') != null ? location.time /* ?? '' */
                          : ''}\n',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          color: Colors.grey[600])),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        text: location.getDetailed(0),
                        style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.black,
                            fontStyle: FontStyle.italic))),
              ),
              buildSevenDay(location)
            ],
          )),
    );
  }

  /// card of temp graph for current day TODO finish temp graph
  Widget _buildTempGraph(Location location) {
    return Card(
        elevation: .75,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              primaryXAxis: CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0), visibleMaximum: 8,labelPlacement: LabelPlacement.onTicks),

              /// TODO DateTimeAxis(),
              primaryYAxis: NumericAxis(isVisible: false, anchorRangeToVisiblePoints: false),
              plotAreaBorderWidth: 0,
              zoomPanBehavior: ZoomPanBehavior(enablePanning: true),
              // title: ChartTitle(text: 'Hourly Forecast',
              //     textStyle: GoogleFonts.questrial(
              //     fontSize: 18,
              //     color: Theme.of(context).colorScheme.secondary,
              //     fontWeight: FontWeight.bold)),
              legend: Legend(
                isVisible: false,
              ),
              enableAxisAnimation: true,
              series: _buildSeries(location),
            )));
  }

  /// TODO format chart x axis labels to datetime using intl.dart
  List<ChartSeries<int, String>> _buildSeries(Location location) {
    return [
      SplineAreaSeries<int, String>(
        dataSource: List.generate(
            12,
            (int index) => location.getTemp(hour: index) is String
                ? 0
                : location.getTemp(hour: index)),
        xValueMapper: (_, hour) =>
            location.forecast.getHourly(hour, 'startTime'),
        yValueMapper: (temp, _) => temp,
        xAxisName: 'Hours',
        yAxisName: 'Degrees',
        // borderWidth: 2,
        // borderColor: Theme.of(context).colorScheme.secondary,
        isVisibleInLegend: false,
        // markerSettings: MarkerSettings(isVisible: true, width: 5, height: 5, color: Theme.of(context).colorScheme.secondary),
        dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.bottom,
            // color: Theme.of(context).colorScheme.primary,
            textStyle: GoogleFonts.lato()),
        dataLabelMapper: (temp, _) => '${temp}°',
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.secondary.withOpacity(.5)
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      )
    ];
  }

  /// details card with wind speed, rain in in., UV index, air quality, etc.
  Widget _buildDetails(Location location) {
    return Card(
        elevation: .75,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(8),
        ));
  }
}
