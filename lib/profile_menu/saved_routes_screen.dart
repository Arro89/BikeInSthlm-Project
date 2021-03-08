import 'package:bikeinsthlm/distance_calculator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bikeinsthlm/artefacts/saved_route.dart';
import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:charts_flutter/flutter.dart" as charts;

import '../route_planner_screen.dart';

class SavedRoutesScreen extends StatefulWidget {
  final BaseAuth auth;
  Set<Marker> markers;

  SavedRoutesScreen({this.auth, this.markers});
  @override
  SavedRouteScreenState createState() => SavedRouteScreenState();
}

class SavedRouteScreenState extends State<SavedRoutesScreen> {
  DatabaseService databaseService;
  List<charts.Series<dynamic, num>> seriesList =
      List<charts.Series<dynamic, num>>();

  final List<SavedRoute> routes = List<SavedRoute>();
  SavedRoute route;
  int _noOfWarnings = 0;

  @override
  void initState() {
    getRoutes();
    super.initState();
  }

  void getRoutes() async {
    var uid = await widget.auth.currentUser();
    databaseService = DatabaseService(uid: uid);
    var routeMap = await databaseService.getRoute();
    if (routeMap != null) {
      setState(() {
        for (SavedRoute sr in routeMap) {
          routes.add(sr);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(text: "Sparade rutter"),
        backgroundColor: Colors.grey[800],
        body: Container(
          margin: EdgeInsets.fromLTRB(
              ScreenUtil.instance.setWidth(35),
              ScreenUtil.instance.setHeight(55),
              ScreenUtil.instance.setWidth(35),
              ScreenUtil.instance.setHeight(55)),
          child: ListView.builder(
            itemBuilder: (ctx, index) {
              return Container(
                margin:
                    EdgeInsets.only(bottom: ScreenUtil.instance.setHeight(10)),
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: ScreenUtil.instance.setHeight(15),
                  ),
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => {
                          calculateWarnings(index),
                          _routeInfoAlert(context, index)
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                routes[index].name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ScreenUtil.instance.setHeight(22),
                                ),
                              ),
                              Icon(Icons.info_outline,
                                  color: Colors.white,
                                  size: ScreenUtil.instance.setHeight(30)),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                          color: Colors.white,
                          height: ScreenUtil.instance.setHeight(40))
                    ],
                  ),
                ),
              );
            },
            itemCount: routes.length,
          ),
        ),
      ),
    );
  }

  void calculateWarnings(int index) {
    _noOfWarnings = 0;
    SavedRoute route = routes[index];
    List<LatLng> coordinates = List<LatLng>();
    for (int i = 0; i < route.coordinates.length; i += 2) {
      coordinates.add(LatLng(route.coordinates[i], route.coordinates[i + 1]));
    }
    DistanceCalculator dc = DistanceCalculator();
    Marker lastAdded;
    print(widget.markers);
    for (Marker m in widget.markers) {
      for (LatLng wp in coordinates) {
        if (lastAdded == null || lastAdded != m) {
          var distance = dc.getDistanceBetween(m.position, wp);
          if (distance < 150) {
            setState(() {
              _noOfWarnings++;
              lastAdded = m;
            });
          }
        }
      }
    }
  }

  _routeInfoAlert(BuildContext context, int index) {
    SavedRoute route = routes[index];
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text(route.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(24),
          ),
          textAlign: TextAlign.center),
      content: Wrap(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: <Widget>[
                SizedBox(height: ScreenUtil.instance.setHeight(20)),
                buildRouteColumn(
                    time: route.time,
                    distance: route.distance,
                    savedC02: route.savedC02,
                    quietness: route.quietness,
                    trafficLights: route.trafficLights,
                    crosswalks: route.crosswalks,
                    walking: route.walking,
                    uphill: route.uphill,
                    warnings: "$_noOfWarnings varningar längs rutten"),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: ScreenUtil.instance.setHeight(30)),
                    FlatButton(
                      onPressed: () => {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return RoutePlannerScreen(
                              auth: widget.auth, route: route);
                        })),
                      },
                      child: Text(
                        "Se rutt",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil.instance.setHeight(22),
                        ),
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: ScreenUtil.instance.setHeight(40)),
                        child: Divider(color: Colors.white)),
                    FlatButton(
                      onPressed: () => {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return RoutePlannerScreen(
                            auth: widget.auth,
                            route: route,
                            navigating: true,
                            customPins: widget.markers,
                          );
                        })),
                      },
                      child: Text(
                        "Starta navigation",
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: ScreenUtil.instance.setHeight(22),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: ScreenUtil.instance.setHeight(40)),
                      child: Divider(
                        color: Colors.white,
                      ),
                    ),
                    FlatButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return _confirmDeletionAlert(index);
                          },
                        );
                      },
                      child: Text(
                        "Radera rutt",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: ScreenUtil.instance.setHeight(22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _confirmDeletionAlert(int index) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text("Radera rutt",
          style: TextStyle(
            color: Colors.red,
            fontSize: ScreenUtil.instance.setHeight(24),
          ),
          textAlign: TextAlign.center),
      content: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          Text(
            "Är du säker på att du vill radera denna rutt?",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(16),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ScreenUtil.instance.setHeight(30)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  deleteRoute(index);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Radera",
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: ScreenUtil.instance.setHeight(22),
                  ),
                ),
              ),
              Container(
                height: ScreenUtil.instance.setHeight(35),
                child: VerticalDivider(color: Colors.white),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Avbryt",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
    );
  }

  void setRoute(i) {
    setState(() {
      route = routes[i];
    });
  }

  void deleteRoute(int index) async {
    FirebaseUser user = await widget.auth.getUser();
    SavedRoute theRouteToDelete = routes[index];
    if (user != null) {
      DatabaseService(uid: user.uid).deleteRoute(theRouteToDelete);
      setState(() {
        routes.removeAt(index);
      });
    } else {
      print("Tydligen gick något väldigt fel :)");
    }
  }

  void createData(List<dynamic> dataPoints, List<dynamic> distances) {
    List<Elevation> elevations = List<Elevation>();

    for (int i = 0; i < dataPoints.length; i++) {
      elevations.add(Elevation(distances[i].toInt(), dataPoints[i].toInt()));
    }
    seriesList.clear();
    seriesList.add(new charts.Series<Elevation, num>(
      id: "Topologi-Graf",
      data: elevations,
      domainFn: (Elevation el, _) => el.startE,
      measureFn: (Elevation el, _) => el.endE,
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
    ));
  }

  _buildElevationDialog() {
    print("BYGGER");
    showDialog(
        context: context,
        builder: (_) => Center(
                // Aligns the container to center
                child: Material(
              type: MaterialType.transparency,
              child: _buildGraph(),
            )));
  }

  _startBuildingGraphDialog() {
    createData(route.elevation, route.distances);
    _buildElevationDialog();
  }

  Widget _buildGraph() {
    return Container(
      //color: Colors.grey[800],
      height: 235,
      width: double.infinity,
      padding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      decoration: BoxDecoration(
        borderRadius: new BorderRadius.only(
            bottomLeft: const Radius.circular(20.0),
            bottomRight: const Radius.circular(20.0),
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0)),
        color: Colors.grey[800],
      ),

      child: Column(children: <Widget>[
        Text(
          "Höjdskillnader",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: charts.LineChart(
            seriesList,
            animate: true,
            defaultRenderer:
                charts.LineRendererConfig(includeArea: true, stacked: true),
            primaryMeasureAxis: charts.NumericAxisSpec(
                tickProviderSpec:
                    charts.BasicNumericTickProviderSpec(zeroBound: false),
                renderSpec: charts.SmallTickRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                      fontSize: 14, // size in Pts.
                      color: charts.MaterialPalette.white),
                )),
            domainAxis: charts.NumericAxisSpec(
                tickProviderSpec:
                    charts.BasicNumericTickProviderSpec(zeroBound: false),
                renderSpec: charts.SmallTickRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                      fontSize: 14, // size in Pts.
                      color: charts.MaterialPalette.white),
                )),
            behaviors: [
              new charts.ChartTitle('m över havet',
                  behaviorPosition: charts.BehaviorPosition.start,
                  titleStyleSpec: charts.TextStyleSpec(
                      color: charts.MaterialPalette.white, fontSize: 14),
                  titleOutsideJustification:
                      charts.OutsideJustification.middleDrawArea),
              new charts.ChartTitle('Distans i meter',
                  behaviorPosition: charts.BehaviorPosition.bottom,
                  titleStyleSpec: charts.TextStyleSpec(
                      color: charts.MaterialPalette.white, fontSize: 14),
                  titleOutsideJustification:
                      charts.OutsideJustification.middleDrawArea),
            ],
          ),
        ),
        Divider(color: Colors.white),
        _buildRouteInfoRow("Totalt uppför: ", route.totalUp),
        SizedBox(height: 5),
        _buildRouteInfoRow("Totalt nedför: ", route.totalDown),
      ]),
    );
  }

  Widget _buildElevationRow(String leftText, String rightText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildText(leftText),
        Row(
          children: <Widget>[
            _buildText(rightText),
            GestureDetector(
              onTap: _startBuildingGraphDialog,
              child: Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildRouteColumn(
      {time,
      distance,
      savedC02,
      quietness,
      trafficLights,
      crosswalks,
      walking,
      uphill,
      warnings}) {
    return Wrap(
      children: <Widget>[
        _buildRouteInfoRow("Tid:", time),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Distans:", distance),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildElevationRow("Uppförsbackar:", uphill),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Sparad CO2-utsläpp:", savedC02),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Ljudnivå:", quietness),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Trafikljus:", trafficLights),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Övergångsställen:", crosswalks),
        SizedBox(height: ScreenUtil.instance.setHeight(15)),
        _buildRouteInfoRow("Varningar:", "$warnings"),
      ],
    );
  }

  Widget _buildRouteInfoRow(String leftText, String rightText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildText(leftText),
        _buildText(rightText),
      ],
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: ScreenUtil.instance.setHeight(16),
      ),
    );
  }
}
