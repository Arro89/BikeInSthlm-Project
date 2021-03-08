import 'dart:math';
import 'package:bikeinsthlm/artefacts/saved_route.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/distance_calculator.dart';
import 'package:bikeinsthlm/trafikverket_objects/situation.dart';
import 'package:bikeinsthlm/widgets/alerts/customAlertDialog.dart';
import 'package:charts_flutter/flutter.dart' as c;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:location/location.dart';
import 'package:oktoast/oktoast.dart';
import 'artefacts/saved_route.dart';
import 'authentication_login/authentication.dart';
import 'authentication_login/database.dart';
import "http_fetch_service.dart";
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import "package:google_maps_webservice/places.dart" as gmw;
import "package:flutter_google_places/flutter_google_places.dart";
import "./constants.dart";
import "artefacts/route_plan.dart" as rp;
import 'package:charts_flutter/flutter.dart' as charts;
import 'map_screen.dart';

const apiKey = "AIzaSyB1SCDPQTve0fb08847Wzgl-BoaYY8Qwuo";
const double CAMERA_ZOOM = 18;
//const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 0;
final DistanceCalculator distanceCalculator = DistanceCalculator();


class RoutePlannerScreen extends StatefulWidget {
  final Set<Marker> customPins;
  final Function updateLocalVar;
  final BaseAuth auth;
  final SavedRoute route;
  final Destination destination;
  final String currentUsername;
  final bool navigating;
  RoutePlannerScreen(
      {this.auth,
      this.customPins,
      this.updateLocalVar,
      this.route,
      this.currentUsername,
      this.destination,
      this.navigating});
  @override
  _RoutePlannerState createState() => _RoutePlannerState();
}

enum TtsState { playing, stopped }

class _RoutePlannerState extends State<RoutePlannerScreen> {
  @override
  void dispose() {
    location = null;
    flutterTts = null;
    _mapController = null;
    _controller = null;
    listener = null;
    currentLeg = 0 ;
    _descriptionFieldController.dispose();
    _startFieldController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _centerOnUser();
    if (widget.destination != null) {
      destination = widget.destination.position;
      setTo(widget.destination.place);
      _descriptionFieldController.text = _to;
    }
    initTts();
  }

  void setTo(String to) {
    setState(() {
      _to = to;
    });
  }

  Marker tempMarker;
  LatLng start;
  LatLng destination;
  int currentLeg = 1;
  FlutterTts flutterTts = FlutterTts();
  TtsState ttsState = TtsState.stopped;
  DatabaseService databaseService = DatabaseService();
  Set<Marker> warnings = {};
  AnimationController _animationController;
  String _markerSnippet = "";
  var listener;
  bool _preWarned = false;
  bool _warned = false;
  bool _longPreWarned = false;
  bool _loading = false;
  bool _advancedSearch = false;
  int notOnRouteCounter = 0;
  final spinkit = SpinKitFadingCube(
    itemBuilder: (BuildContext context, int index) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: index.isEven ? Colors.red : Colors.green,
        ),
      );
    },
  );



  initTts() {
    flutterTts = FlutterTts();
    flutterTts.setStartHandler(() {
      setState(() {
        print("playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
    flutterTts.setLanguage("sv.SE");
    flutterTts.setSpeechRate(0.8);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  String _navInstructions = "";
  Future _speak() async {
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setPitch(1.0);
    if (_navInstructions != null) {
      if (_navInstructions.isNotEmpty) {
        var result = await flutterTts.speak(_navInstructions);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  AssetImage turnIcon = AssetImage("assets/images/straightOn.png");
  AssetImage straightOn = AssetImage("assets/images/straightOn.png");
  AssetImage bearLeft = AssetImage("assets/images/bearLeft.png");
  AssetImage bearRight = AssetImage("assets/images/bearRight.png");
  AssetImage turnLeft = AssetImage("assets/images/leftTurn.png");
  AssetImage turnRight = AssetImage("assets/images/rightTurn.png");

  final Set<Marker> _markers = {};
  gmw.GoogleMapsPlaces _places = gmw.GoogleMapsPlaces(apiKey: apiKey);
  GoogleMapController _mapController;
  bool _locationOn = false;
  bool _evaluateRoute = false;
  bool _showRouteInfo = false;
  bool _navigating = false;
  BitmapDescriptor roadworkPin;
  List<charts.Series<dynamic, num>> seriesList =
      List<charts.Series<dynamic, num>>();
  var actualSeries = List<charts.Series<Elevation, num>>();
  DatabaseReference _firestoreMarkers =
      FirebaseDatabase.instance.reference().child("customMarkers");
  Text _appbarText = Text(
    "Ruttplanering",
    style: TextStyle(
      color: Colors.green[400],
      fontSize: ScreenUtil.instance.setHeight(23),
    ),
  );
  String appBarTitle = "Ruttplanering";

  Completer<GoogleMapController> _controller = Completer();
  static const _center = LatLng(59.32000, 18.06000);
  String _selectedRouteType = "balanced";
  String _selectedRouteSpeed = "20";
  static LatLng yourLocation;
  LatLng test = LatLng(59.412046, 17.865930);
  loc.LocationData currentLocation;
  TextEditingController _startFieldController =
      TextEditingController(text: "Välj startpunkt");
  TextEditingController _descriptionFieldController =
      TextEditingController(text: "Välj destination");
  bool _routePlanned = true;

  loc.Location location;
  List<rp.Attributes> legs = List<rp.Attributes>();
  String _from = "";
  String _to = "";
  String _totalUp = "";
  String _totalDown = "";
  String _time = "";
  String _distance = "";
  String _savedC02 = "";
  String _quietness = "";
  String _trafficLights = "";
  String _crosswalks = "";
  String _walking = "";
  String _currLeg = "";
  String _currTurn = "";
  String _uphill = "";
  String _warnings = "";
  int _noOfWarnings = 0;
  int _distanceToTurn = 0;
  bool workRoute = false;
  //Icon _turnIcon = Icon(Icons.directions, color: Colors.white);
  rp.Attributes _routeData;
  MapType _currentMapType = MapType.normal;
  Service service = Service();
  List<DropdownMenuItem<String>> routeTypesItems;
  List<DropdownMenuItem<String>> getRouteTypes() {
    List<DropdownMenuItem<String>> routeTypes =
        List<DropdownMenuItem<String>>();
    routeTypes
        .add(DropdownMenuItem(child: Text("Snabbaste"), value: "fastest"));
    routeTypes
        .add(DropdownMenuItem(child: Text("Kortaste"), value: "shortest"));
    routeTypes.add(DropdownMenuItem(child: Text("Tystast"), value: "quietest"));
    routeTypes
        .add(DropdownMenuItem(child: Text("Balanserad"), value: "balanced"));
    return routeTypes;
  }

  Map<String, String> routeTypeValues = {
    "fastest": "Snabbaste",
    "shortest": "Kortaste",
    "quietest": "Tystast",
    "balanced": "Balanserad"
  };
  List<DropdownMenuItem<String>> getRouteSpeeds() {
    List<DropdownMenuItem<String>> routespeeds =
        List<DropdownMenuItem<String>>();
    routespeeds.add(DropdownMenuItem(child: Text("24km/h"), value: "24"));
    routespeeds.add(DropdownMenuItem(child: Text("20km/h"), value: "20"));
    routespeeds.add(DropdownMenuItem(child: Text("16km/h"), value: "16"));
    return routespeeds;
  }

  bool addingWaypoint;
  List<LatLng> waypoints;

  Set<Polyline> _polyLines = {};
  Map<PolylineId, Polyline> polyLines;

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    _mapController = controller;
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/constructionmarker.png")
        .then((onValue) {
      roadworkPin = onValue;
    });
    if (widget.route != null) {
      _drawRoute(url: widget.route.routeURL);
    } else {
      _getLocation();
    }
  }

  void _centerOnUser() async {
    var location = new loc.Location();
    try {
      currentLocation = await location.getLocation();
    } on Exception {
      currentLocation = null;
    }
    _moveCamera(LatLng(currentLocation.latitude, currentLocation.longitude));
  }

  void _moveCamera(LatLng location, {double prefZoom}) async {
    final GoogleMapController controller = await _controller.future;
    double zoom = prefZoom == null ? 13.0 : prefZoom;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 0,
        target: location,
        zoom: zoom,
      ),
    ));
  }

  void createData(List<num> dataPoints, List<num> distances) {
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

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation   CameraPosition cPosition = CameraPosition(

    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      //tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
    );
    if (_controller == null) {
      _controller = Completer();
    }
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        cPosition)); // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    /*setState(() {
      // updated position
      var pinPosition =
          LatLng(currentLocation.latitude, currentLocation.longitude);
      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == "curr_loc");
      _markers.add(Marker(
        markerId: MarkerId("curr_loc"),
        position: pinPosition, // updated position
        prefixIcon: bicycleMarker,
      ));
    });
     */
  }

  void _getLocation() async {
    var currentLocation = await Geolocator().getCurrentPosition();
    yourLocation = LatLng(currentLocation.latitude, currentLocation.longitude);
    _locationOn = true;

    setState(() {
      /* final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: yourLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        prefixIcon: bicycleMarker,
      );
      _markers.add(marker);
      */

      start = yourLocation;
      if (yourLocation != null)
        _startFieldController = TextEditingController(text: "Din position");
    });
    if (widget.route == null && yourLocation != null) {
      _from = await service.getAddress(start);
    }
  }

  Future<void> startSelected(gmw.Prediction p) async {
    gmw.PlacesDetailsResponse response =
        await _places.getDetailsByPlaceId(p.placeId);

    var location = response.result.geometry.location;
    start = LatLng(location.lat, location.lng);
    setState(() {
      _from = response.result.name;
    });
  }

  Future<void> destinationSelected(gmw.Prediction p) async {
    if (p != null) {
      gmw.PlacesDetailsResponse response =
          await _places.getDetailsByPlaceId(p.placeId);
      var location = response.result.geometry.location;
      String address = response.result.formattedAddress;

      print(response.result.name);
      setState(() {
        _to = response.result.name;
      });
      destination = LatLng(location.lat, location.lng);
      addTempMarker(destination, response.result.name);
    }
  }

  void changedRouteType(String selectedType) {
    setState(() {
      _selectedRouteType = selectedType;
      if (_evaluateRoute) {
        _drawRoute();
      }
    });
  }

  void changedRouteSpeed(String selectedType) {
    setState(() {
      _selectedRouteSpeed = selectedType;
    });
  }

  _drawRoute({String url}) async {

    setState(() {
      // ignore: unnecessary_statements
      _markers.clear();
      _noOfWarnings = 0;
      _loading = true;
    });


    rp.Marker marker = url != null
        ? await service.fetchSavedRoute(url)
        : await service.fetchRoute(
            waypoints: waypoints,
            routeType: _selectedRouteType,
            start: start,
            destination: destination);
    if (widget.customPins != null) {
      warnings.addAll(widget.customPins);
    }
    print("WARNINGS SIZE =======> ${warnings.length}");
    legs.clear();
    currentLeg = 1;
    for (rp.Marker2 m in marker.marker) {
      if (m.attributes.pointsList.isNotEmpty) legs.add(m.attributes);
    }
    calculateLegWarnings();

    //legs.addAll(marker.marker);
    createData(marker.marker[0].attributes.elevation,
        marker.marker[0].attributes.distanceList);

    setState(() {
      _routeData = marker.marker[0].attributes;
      appBarTitle = _from == null || _from.isEmpty
          ? _routeData.start
          : "$_from till $_to";
      double height = appBarTitle.length > 32 ? 15 : 17;
      _appbarText = Text(
        appBarTitle,
        style: TextStyle(
          color: Colors.green[400],
          fontSize: ScreenUtil.instance.setHeight(height),
        ),
      );
      _routePlanned = false;
      var coordinates = _routeData.coordinateList;

      Marker lastAdded;
      for (Marker m in warnings) {
        for (int i = 0; i < coordinates.length; i++) {
          if (lastAdded == null || m != lastAdded) {
            var distance = distanceCalculator.getDistanceBetween(
                coordinates[i], m.position);
            if (distance < 150) {
              _markers.add(m);
              _noOfWarnings++;
              lastAdded = m;
            }
          }
        }
      }

      updateRouteData(marker.marker[0].attributes);
      _evaluateRoute = true;

      //List<num> elevation = _routeData.setElevation;

      _polyLines.add(getPolyLine(coordinates));
      _markers.removeWhere((m) => m.markerId.value == "Temporary pin");
      _markers.add(Marker(
        position: coordinates[coordinates.length - 1],
        markerId: MarkerId("destination"),
        infoWindow: InfoWindow(title: _to, snippet: _markerSnippet),
      ));

      LatLng startLatlng = coordinates[0];
      LatLng endLatlng = coordinates[coordinates.length - 1];
      _routePlanned = false;

      _evaluateRoute = true;
      LatLngBounds bound;
      if (startLatlng.latitude > endLatlng.latitude &&
          startLatlng.longitude > endLatlng.longitude) {
        bound = LatLngBounds(southwest: endLatlng, northeast: endLatlng);
      } else if (startLatlng.longitude > endLatlng.longitude) {
        bound = LatLngBounds(
            southwest: LatLng(startLatlng.latitude, endLatlng.longitude),
            northeast: LatLng(startLatlng.latitude, startLatlng.longitude));
      } else if (startLatlng.latitude > endLatlng.latitude) {
        bound = LatLngBounds(
            southwest: LatLng(endLatlng.latitude, startLatlng.longitude),
            northeast: LatLng(startLatlng.latitude, endLatlng.longitude));
      } else {
        bound = LatLngBounds(southwest: startLatlng, northeast: endLatlng);
      }

      CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
      _mapController.animateCamera(u2).then((void v) {
        check(u2, _mapController);
      });
      _loading = false;
      if (widget.navigating != null && widget.navigating == true) {
        startNavigation();
      }

      //moveCamera(coordinates[0]);
      //startNavigation();
    });
  }

  void updateRouteData(rp.Attributes route) {
    setState(() {
      _totalUp = "${route.totalUp} meter";
      _totalDown = "${route.totalDown} meter";

      var number = double.parse(route.time) ~/ 60;
      double roundDouble(double value, int places) {
        double mod = pow(10.0, places);
        return ((value * mod).round().toDouble() / mod);
      }

      //number = roundDouble(number, 2);
      _time = number < 60
          ? "$number minuter"
          : "${number ~/ 60} h och ${number % 60.toInt()} min";
      var m = num.parse(route.length);
      _distance = "${m / 1000} km";
      _markerSnippet = "$m meter, $number minuter";
      var upPerKm = route.totalUp / (m / 1000);
      if (upPerKm <= 14) {
        _uphill = "Låg";
      } else {
        _uphill = upPerKm > 30 ? "Hög" : "Medel";
      }
      _savedC02 = "${num.parse(route.grammesCO2saved) / 1000} kg";
      var value = num.parse(route.quietness);
      if (value < 50) _quietness = "Hög";
      if (value >= 50) _quietness = "Medel";
      if (value >= 70) _quietness = "Låg";
      _trafficLights = "${route.signalledJunctions}";
      _crosswalks = "${route.signalledCrossings}";
      _warnings = _noOfWarnings != 1 ? "$_noOfWarnings varningar längs rutten" : "$_noOfWarnings varning längs rutten";

      double walkingDistance = 0;
      for (int i = 1; i < legs.length; i++) {
        if (int.parse(legs[i].walk) != 0) {
          walkingDistance += double.parse(legs[i].distance);
        }
      }
      _walking = "${roundDouble(walkingDistance / m, 2).toInt()}%";
    });
  }

  _mapTapped(LatLng location) async {
    if (_routePlanned) {
      String address = await service.getAddress(location);
      addTempMarker(location, address);
      _to = address;
      destination = location;
      _descriptionFieldController.text = address;
    }
  }

  void addTempMarker(LatLng location, String address) {
    tempMarker = Marker(
      position: location,
      markerId: MarkerId("Temporary pin"),
      infoWindow: InfoWindow(title: address),
    );
    setState(() {
      _markers.add(tempMarker);
      moveCamera(location);
    });
  }

  void startNavigation() {
    setState(() {
      _showRouteInfo = false;
      _evaluateRoute = false;
      _navigating = true;
      location = new loc.Location();

      listener = location.onLocationChanged.listen((LocationData cLoc) {
        // cLoc contains the lat and long of the
        // current user's position in real time,
        // so we're holding on to it
        currentLocation = cLoc;
        updatePinOnMap();
        updateNavContainer();
      });
    });
  }

  Polyline getPolyLine(List<LatLng> coordinates) {
    Map<PolylineId, Polyline> _mapPolylines = {};
    int _polylineIdCounter = 1;
    String polylineIdVal = 'polyline_id_$_polylineIdCounter';
    _polylineIdCounter++;
    PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.green[500],
      width: 3,
      points: coordinates,
      onTap: _polyLineTapped,
    );
    _mapPolylines[polylineId] = polyline;
    return polyline;
  }

  void _polyLineTapped() {
    setState(() {
      _evaluateRoute = true;
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _mapController.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void moveCamera(LatLng location) async {
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 10,
        ),
      ),
    );
  }

  void showInfo() {
    setState(() {
      if (!_showRouteInfo)
        _showRouteInfo = true;
      else
        _showRouteInfo = false;
    });
  }

  void calculateLegWarnings() {
    for (int i = 0; i < legs.length; i++) {
      //print(legs[i].coordinates);
      rp.Attributes current = legs[i];
      if (current.turn == null) {
        current.turn = legs[i + 1].turn;
        //current.straightOn = true;
      }

      if (i != 0 &&
          i != legs.length - 1 &&
          !(legs[i + 1].straightOn) &&
          current.legLength != null &&
          current.legLength < 15) {
        if (current.legLength < 8) {
          current.extraInfo = " och sedan ${current.turn}";
        } else {
          current.extraInfo =
              " och sedan efter ${current.legLength} meter ${current.turn}";
        }
      }

      /*if(current.roundAbout){
        rp.Attributes next = legs[i+1];
        current.turn += " och sedan ${next.turn}";
      }
       */

    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ScreenUtil.instance.setHeight(45)),
          child: AppBar(
            backgroundColor: Colors.grey[800].withOpacity(0.9),
            centerTitle: true,
            title: _appbarText,
            leading: GestureDetector(
              child: Icon(
                Icons.keyboard_arrow_left,
                size: ScreenUtil.instance.setHeight(34),
                color: Colors.green[400],
              ),
              onTap: () => Navigator.pop(context),
            ),
            actions: <Widget>[
              Visibility(
                visible: _routePlanned,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => showToast(
                        "Sök på en plats eller tryck och håll på kartan för att välja destination",
                        textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: ScreenUtil.instance.setSp(14)),
                        position: ToastPosition.center,
                        backgroundColor: Colors.grey[800],
                        textPadding:
                            EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.green,
                        size: ScreenUtil.instance.setHeight(28),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: _evaluateRoute,
                child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => {
                          switchStartAndDestination(),
                          _drawRoute(),
                        },
                        child: Icon(
                          Icons.swap_horiz,
                          color: Colors.green[400],
                          size: ScreenUtil.instance.setHeight(40),
                        ),
                      ),
                    )),
              ),
            ],
          ),
        ),
        body: Stack(
          children: <Widget>[
            _buildGoogleMap(),
            Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _centerOnUser();
                  });
                },
                backgroundColor: Colors.grey[800].withOpacity(0.9),
                child: Icon(Icons.location_searching),
              ),
            ),
            Visibility(
              visible: _routePlanned,
              child: _buildSearchContainer(),
            ),
            Visibility(
              visible: _evaluateRoute,
              child: _buildContainer(),
            ),
            Visibility(
              visible: _navigating,
              child: _buildNavBar(),
            ),
            Visibility(
              visible: _loading,
              child: Container(
                alignment: Alignment.center,
                child: Center(
                  child: SpinKitFadingCube(color: Colors.green[400]),
                ),
              ),
            )
            //_buildContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onLongPress: _mapTapped,
      mapToolbarEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 17.0,
      ),
      polylines: _polyLines,
      mapType: _currentMapType,
      markers: _markers,
    );
  }

  Widget _buildSearchContainer() {
    return Wrap(
      children: <Widget>[
        Container(
          color: Colors.grey[800].withOpacity(0.9),
          child: Container(
            /*margin: EdgeInsets.fromLTRB(
                ScreenUtil.instance.setWidth(45),
                ScreenUtil.instance.setHeight(15),
                ScreenUtil.instance.setWidth(5),
                0),

             */
            child: Column(
              children: <Widget>[
                Container(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                        ScreenUtil.instance.setWidth(0), 0, 0, 0),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.fromLTRB(
                                    ScreenUtil.instance.setWidth(45),
                                    ScreenUtil.instance.setHeight(15),
                                    0,
                                    0,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Flexible(
                                          child: Stack(
                                              alignment: Alignment.centerRight,
                                              children: <Widget>[
                                            _buildStartField(),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 15.0),
                                              child: GestureDetector(
                                                onTap: () => {
                                                  _getLocation(),
                                                },
                                                child: Icon(
                                                  Icons.location_searching,
                                                  color: Colors.grey[800],
                                                  size: ScreenUtil.instance
                                                      .setHeight(20),
                                                ),
                                              ),
                                            ),
                                          ])),
                                    ],
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.fromLTRB(
                                        ScreenUtil.instance.setWidth(45),
                                        0,
                                        0,
                                        0),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          SizedBox(
                                              height: ScreenUtil.instance
                                                  .setHeight(5)),
                                          Flexible(
                                              child: _buildDestinationField()),
                                          SizedBox(
                                              height: ScreenUtil.instance
                                                  .setHeight(15)),
                                        ]))
                              ]),
                        ),
                        Container(
                          width: 40,
                          child: GestureDetector(
                            onTap: () => {
                              switchStartAndDestination(),
                            },
                            child: Icon(
                              Icons.swap_vert,
                              color: Colors.green[400],
                              size: ScreenUtil.instance.setHeight(40),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.fromLTRB(ScreenUtil.instance.setWidth(50),
                      0, ScreenUtil.instance.setWidth(50), 0),
                  child: Visibility(
                    visible: !_advancedSearch,
                    child: GestureDetector(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.green[400],
                          size: ScreenUtil.instance.setHeight(40),
                        ),
                        onTap: () => {
                              setState(() {
                                _advancedSearch = true;
                              }),
                            }),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(ScreenUtil.instance.setWidth(50),
                      0, ScreenUtil.instance.setWidth(50), 0),
                  child: Visibility(
                      visible: _advancedSearch,
                      child: Column(children: <Widget>[
                        _buildDropDownButtonRow(
                          "Typ av rutt",
                          _buildDropDownButton(getRouteTypes(),
                              _selectedRouteType, changedRouteType),
                        ),
                        SizedBox(height: ScreenUtil.instance.setHeight(5)),
                        _buildDropDownButtonRow(
                          "Hastighet:",
                          _buildDropDownButton(getRouteSpeeds(),
                              _selectedRouteSpeed, changedRouteSpeed),
                        ),
                        GestureDetector(
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.green[400],
                            size: ScreenUtil.instance.setHeight(40),
                          ),
                          onTap: () => {
                            setState(() {
                              _advancedSearch = false;
                            }),
                          },
                        ),
                      ])),
                ),
                //SizedBox(height: ScreenUtil.instance.setHeight(5)),
                Container(
                  margin: EdgeInsets.fromLTRB(ScreenUtil.instance.setWidth(50),
                      0, ScreenUtil.instance.setWidth(50), 0),
                  child: Container(
                    margin:
                        EdgeInsets.only(top: ScreenUtil.instance.setHeight(0)),
                    width: ScreenUtil.instance.setHeight(200),
                    child: Divider(
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(ScreenUtil.instance.setWidth(50),
                      0, ScreenUtil.instance.setWidth(50), 0),
                  child: _buildSearchRouteButton("Sök rutt", 24),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void switchStartAndDestination() {
    setState(() {
      var oldStart = start;
      start = destination;
      destination = oldStart;
      String oldTo = _to;
      _to = _from;
      _from = oldTo;
      String oldDestinationField = _descriptionFieldController.text;
      String oldStartField = _startFieldController.text;
      _descriptionFieldController.text = oldStartField == "Välj startpunkt"
          ? "Välj destination"
          : oldStartField;
      _startFieldController.text = oldDestinationField == "Välj destination"
          ? "Välj startpunkt"
          : oldDestinationField;
      if (_markers.contains(tempMarker)) {
        _markers.removeWhere((m) => m.markerId.value == "Temporary pin");
        addTempMarker(destination, _to);
      }
    });
  }

  Widget _buildContainer() {
    return Container(
      color: Colors.grey[800].withOpacity(0.9),
      child: Container(
        margin: EdgeInsets.fromLTRB(
            ScreenUtil.instance.setWidth(50),
            ScreenUtil.instance.setHeight(0),
            ScreenUtil.instance.setWidth(50),
            0),
        child: Wrap(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
                  child: _buildDropDownButtonRow(
                    "Kategori:",
                    _buildDropDownButton(
                        getRouteTypes(), _selectedRouteType, changedRouteType),
                  ),
                ),
                _buildPadding(
                  SizedBox(height: ScreenUtil.instance.setHeight(5)),
                ),
                _buildPadding(
                  _buildDropDownButtonRow(
                    "Hastighet:",
                    _buildDropDownButton(getRouteSpeeds(), _selectedRouteSpeed,
                        changedRouteSpeed),
                  ),
                ),
                SizedBox(height: ScreenUtil.instance.setHeight(15)),
                _buildPadding(
                  Visibility(
                    visible: !_showRouteInfo,
                    child: Column(
                      children: <Widget>[
                        _buildRouteInfoRow(
                            "Tid: $_time", "Distans: $_distance"),
                        GestureDetector(
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.green[400],
                            size: ScreenUtil.instance.setHeight(40),
                          ),
                          onTap: showInfo,
                        ),
                        Container(
                          width: ScreenUtil.instance.setHeight(250),
                          child: Divider(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPadding(_buildInfoContainer(_time, _distance, _savedC02,
                    _quietness, _trafficLights, _crosswalks, _walking)),
                _buildPadding(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildSaveButton(),
                      Center(
                          child: Container(
                              height: 26,
                              child: VerticalDivider(color: Colors.white),
                              alignment: Alignment.center)),
                      _buildStartNavigationButton(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartNavigationButton() {
    return FlatButton(
      onPressed: startNavigation,
      child: Text(
        "Navigera",
        style: TextStyle(
          color: Colors.green[400],
          fontSize: ScreenUtil.instance.setHeight(18),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FlatButton(
      onPressed: () {
        widget.currentUsername == "Gäst"
            ? showDialog(
                context: context,
                builder: (_) {
                  return CustomAlertDialog(
                      title: "Fel",
                      content:
                          "Du kan inte spara rutter som gäst. Logga in med ditt Cadence eller Google-konto.");
                })
            : _buildSaveRouteDialog();
      },
      child: Text(
        "Spara rutt",
        style: TextStyle(
          color: Colors.white,
          fontSize: ScreenUtil.instance.setHeight(18),
        ),
      ),
    );
  }

  Widget _buildSearchRouteButton(String text, double height) {
    return FlatButton(
      onPressed: () => {
        if(destination != null && start != null){
          _drawRoute(),
        }else
          showToast(
            destination == null && start == null
                ? "Ingen startpunkt eller destination vald"
                : start == null
                ? "Ingen startpunkt vald"
                : "Ingen destination vald!",
            textStyle: TextStyle(
                color: Colors.white, fontSize: ScreenUtil.instance.setSp(14)),
            position: ToastPosition.bottom,
            backgroundColor: Colors.grey[800],
            textPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
            dismissOtherToast: true,
          ),
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.green[400],
          fontSize: ScreenUtil.instance.setHeight(height),
        ),
      ),
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
              onTap: () => _buildElevationDialog(),
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

  _buildElevationDialog() {
    showDialog(
        context: context,
        builder: (_) => Center(
                // Aligns the container to center
                child: Material(
              type: MaterialType.transparency,
              child: _buildGraph(),
            )));
  }

  _buildSaveRouteDialog() {
    TextEditingController nameFieldController = TextEditingController();
    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.grey[800],
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      title: Text(
        "Spara rutt",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white, fontSize: ScreenUtil.instance.setHeight(22)),
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Wrap(
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(
                  ScreenUtil.instance.setHeight(10),
                  ScreenUtil.instance.setHeight(10),
                  ScreenUtil.instance.setHeight(10),
                  ScreenUtil.instance.setHeight(0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Från $_from till $_to",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    createRow(
                      <Widget>[
                        Text("Jobbrutt", style: TextStyle(color: Colors.white)),
                        Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.white),
                          child: Checkbox(
                            value: workRoute,
                            focusColor: Colors.green[400],
                            activeColor: Colors.green[400],
                            checkColor: Colors.white,
                            onChanged: (value) {
                              setState(
                                () {
                                  workRoute = value;
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Theme(
                      data: ThemeData.dark(),
                      child: TextField(
                        controller: nameFieldController,
                        textCapitalization: TextCapitalization.sentences,
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Namnge rutt",
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green[400],
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.white,
                            //fontWeight: FontWeight.w200,
                            //fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ScreenUtil.instance.setHeight(10)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width * 0.20,
                            child: FlatButton(
                              onPressed: () => {
                                saveRoute(nameFieldController.text == ""
                                    ? "Namnlös rutt"
                                    : nameFieldController.text),
                                nameFieldController.clear(),
                                Navigator.of(context).pop(),
                                showToast(
                                  "Rutt sparad. Du kan se den i mina sparade rutter",
                                  textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: ScreenUtil.instance.setSp(14)),
                                  position: ToastPosition.center,
                                  backgroundColor: Colors.grey[800],
                                  textPadding: EdgeInsets.all(
                                      ScreenUtil.instance.setHeight(20)),
                                ),
                              },
                              child: Text(
                                "Spara",
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: ScreenUtil.instance.setHeight(18),
                                ),
                              ),
                            ),
                          ),
                          Center(
                              child: Container(
                                  height: ScreenUtil.instance.setHeight(40),
                                  child: VerticalDivider(color: Colors.white),
                                  alignment: Alignment.center)),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.20,
                            child: FlatButton(
                              onPressed: () => {
                                resetWorkRoute,
                                nameFieldController.clear(),
                                Navigator.of(context).pop(),
                              },
                              child: Text(
                                "Avbryt",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: ScreenUtil.instance.setHeight(18),
                                ),
                              ),
                            ),
                          ),
                        ])
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

//  saveRoute(String name) async{
//    String username;
//    await widget.auth.getUser().then((user) {
//      if (user != null)
//        DatabaseService(uid: user.uid).getUserData("name").then((name) {
//            username = name;
//        });
//       else
//          return;
//
//    });
//    SavedRoute savedRoute = SavedRoute(creator: "LALALA", name: name,to: _to,from: _from, routeURL: service.lastRouteSearched,workRoute: workRoute);
//    databaseService.saveRoute(savedRoute);
//  }

  saveRoute(String name) async {
    String uid = await widget.auth.currentUser();
    String creator = await DatabaseService(uid: uid).getCreator();
    List<double> routecoordinates = List<double>();
    for (LatLng l in _routeData.coordinateList) {
      routecoordinates.add(l.latitude);
      routecoordinates.add(l.longitude);
    }

    SavedRoute savedRoute = SavedRoute(
        creator: creator,
        name: name,
        to: _to,
        from: _from,
        routeURL: service.lastRouteSearched,
        workRoute: workRoute,
        totalUp: _totalUp,
        totalDown: _totalDown,
        time: _time,
        distance: _distance,
        savedC02: _savedC02,
        quietness: _quietness,
        trafficLights: _trafficLights,
        crosswalks: _crosswalks,
        coordinates: routecoordinates,
        elevation: _routeData.elevation,
        uphill: _uphill,
        distances: _routeData.distanceList);
    DatabaseService(uid: uid).saveRoute(savedRoute);
  }

  void resetWorkRoute() {
    setState(() {
      workRoute = false;
    });
  }

  Widget _buildGraph() {
    return Container(
      //color: Colors.grey[800],
      height: ScreenUtil.instance.setHeight(300),
      width: double.infinity,
      margin: EdgeInsets.all(ScreenUtil.instance.setHeight(40)),
      decoration: BoxDecoration(
        borderRadius: new BorderRadius.all(Radius.circular(10)),
        color: Colors.grey[800],
      ),

      child: Container(
        margin: EdgeInsets.all(ScreenUtil.instance.setSp(20)),
        child: Column(children: <Widget>[
          Text(
            "Höjdskillnader",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setSp(18),
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
                    titleStyleSpec: c.TextStyleSpec(
                        color: charts.MaterialPalette.white, fontSize: 14),
                    titleOutsideJustification:
                        charts.OutsideJustification.middleDrawArea),
                new charts.ChartTitle('Distans i meter',
                    behaviorPosition: charts.BehaviorPosition.bottom,
                    titleStyleSpec: c.TextStyleSpec(
                        color: charts.MaterialPalette.white, fontSize: 14),
                    titleOutsideJustification:
                        charts.OutsideJustification.middleDrawArea),
              ],
            ),
          ),
          Container(
              margin: EdgeInsets.symmetric(
                  horizontal: ScreenUtil.instance.setHeight(30)),
              child: Divider(
                  color: Colors.white,
                  height: ScreenUtil.instance.setHeight(40))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildText("Totalt uppför: ", fontWeight: FontWeight.bold),
              _buildText(_totalUp),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildText("Totalt nedför: ", fontWeight: FontWeight.bold),
              _buildText(_totalDown),
            ],
          ),
        ]),
      ),
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

  Widget _buildDropDownButtonRow(String text, Widget widget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildText(text),
        widget,
      ],
    );
  }

  Widget _buildText(String text, {FontWeight fontWeight}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: ScreenUtil.instance.setHeight(14),
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _buildDropDownButton(
      List<DropdownMenuItem<String>> items, String value, Function function) {
    return Container(
      height: 30,
      width: 140,
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.grey[600],
          brightness: Brightness.dark,
        ),
        child: DropdownButton(
          isExpanded: true,
          items: items,
          value: value,
          style: TextStyle(
              color: Colors.white, fontSize: ScreenUtil.instance.setHeight(14)),
          onChanged: function,
        ),
      ),
    );
  }

  Widget _buildStartField() {
    return PlacesAutocompleteField(
      controller: _startFieldController,
      apiKey: apiKey,
      onSelected: startSelected,
      mode: Mode.overlay,
      language: "se",
      components: [new gmw.Component(gmw.Component.country, "se")],
      inputDecoration:
          buildTextFieldDecoration(text: "", prefixIcon: Icons.add_location),
    );
  }

  Widget _buildDestinationField() {
    return PlacesAutocompleteField(
      controller: _descriptionFieldController,
      apiKey: apiKey,
      mode: Mode.overlay,
      language: "se",
      components: [new gmw.Component(gmw.Component.country, "se")],
      onSelected: destinationSelected,
      inputDecoration:
          buildTextFieldDecoration(text: "", prefixIcon: Icons.add_location),
    );
  }

  Widget _buildPadding(Widget child) {
    return Padding(
        padding: EdgeInsets.only(left: 10.0, right: 10.0), child: child);
  }

  /////////////////////////////////////////////////////////////
  Widget createContainer({Wrap child}) {
    return Container(
      padding: EdgeInsets.all(10.0),
      color: Colors.grey[800],
      child: child,
    );
  }

  Widget _buildInfoContainer(
      time, distance, savedC02, quietness, trafficLights, crosswalks, walking) {
    return Visibility(
      visible: _showRouteInfo,
      child: Column(children: <Widget>[
        _buildRouteInfoRow("Tid:", _time),
        _buildPadding(SizedBox(height: ScreenUtil.instance.setHeight(5))),
        _buildRouteInfoRow("Distans:", _distance),
        SizedBox(height: ScreenUtil.instance.setHeight(5)),
        _buildElevationRow("Uppförsbackar:", _uphill),
        SizedBox(height: ScreenUtil.instance.setHeight(5)),
        _buildRouteInfoRow("Sparad CO2-utsläpp:", _savedC02),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        _buildRouteInfoRow("Ljudnivå:", _quietness),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        _buildRouteInfoRow("Trafikljus:", _trafficLights),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        _buildRouteInfoRow("Övergångsställen:", _crosswalks),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        _buildRouteInfoRow("Varningar:", "$_warnings"),
        GestureDetector(
          child: Icon(
            Icons.keyboard_arrow_up,
            color: Colors.green[400],
            size: ScreenUtil.instance.setHeight(40),
          ),
          onTap: showInfo,
        ),
        //IconButton(prefixIcon: Icon(Icons.keyboard_arrow_up), color: Colors.white, onPressed: showInfo),
        SizedBox(height: ScreenUtil.instance.setHeight(2)),
        Container(
          width: ScreenUtil.instance.setHeight(250),
          child: Divider(
            color: Colors.white,
          ),
        ),
      ]),
    );
  }

  Widget createRow(var children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: children,
    );
  }

  Widget createColumn({children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  dynamic createText(String text) {
    Text responseText;
    switch (text) {
      case "Från: ":
        responseText = Text("HEH");
    }

    var createdText = <Widget>[
      Text(text),
    ];
    return createdText;
  }

  Widget createRouteInfoBar() {
    return createContainer(
        child: Wrap(
            children: <Widget>[createColumn(children: createText("Från: "))]));
  }

  void reRoute(LatLng currPos) async {
    rp.Marker newRoute = await service.fetchRoute(
        waypoints: waypoints,
        routeType: _selectedRouteType,
        start: currPos,
        destination: destination);

    setState(() {
      legs.clear();
      currentLeg = 1;
      _warned = false;
      _preWarned = false;
      _longPreWarned = false;
      for (rp.Marker2 m in newRoute.marker) {
        legs.add(m.attributes);
      }
      calculateLegWarnings();

      //legs.addAll(marker.marker);
      _routeData = newRoute.marker[0].attributes;
      var coordinates = _routeData.coordinateList;
      _polyLines.clear();
      _polyLines.add(getPolyLine(coordinates));
    });
    startNavigation();
  }

  void updateNavContainer() {
    LatLng currPos = LatLng(currentLocation.latitude, currentLocation.longitude);
    bool onRoute = false;
    int loopCount = legs.length - (currentLeg -1) ;
    loopCount = loopCount > 5 ? currentLeg +5 : loopCount;
    for(int  i = currentLeg; (i < loopCount) ; i++){
        var leg = legs[i];
        for(int j = 0; j < leg.pointsList.length -1  ; j++){
          var distanceDiff;
          distanceDiff = getDistanceDiff(
                currPos,
                leg.pointsList[j],
                leg.pointsList[j+1]);
          if (distanceDiff <= 7 && distanceDiff >= -7) {
            if (currentLeg != i ) {
              resetDirections();
              currentLeg = i+1;
            }
            _distanceToTurn = distanceCalculator
                .getDistanceBetween(
                currPos,
                leg.pointsList[leg.pointsList.length -1])
                .toInt();

            leg = legs[currentLeg];
            String turn = leg.turn;
            updateInstructions(turn, leg);
            updateTurnIcon(turn);
            updateLegInfo();
            onRoute = true;
          }
        }
    }


    if (!onRoute) {
      notOnRouteCounter++;
      if (notOnRouteCounter > 4) {
        listener.cancel();
        reRoute(currPos);
      }
    }
  }

  void resetDirections(){
    _preWarned = false;
    _warned = false;
    _longPreWarned = false;
  }

  void updateTurnIcon(String turn){
    setState(() {
      switch(turn){
        case "sväng vänster": turnIcon = turnLeft;
        break;
        case "sväng höger": turnIcon = turnRight;
        break;
        case "sväng svagt höger" : turnIcon = bearRight;
        break;
        case "sväng svagt vänster" : turnIcon = bearLeft;
        break;
        case "sväng skarpt till höger" : turnIcon = turnRight;
        break;
        case "sväng skarpt till vänster" : turnIcon = turnLeft;
        break;
        default: turnIcon = straightOn;
      }
    });

  }

  void updateInstructions(String turn, rp.Attributes leg){
    if (!_longPreWarned) {
      if (currentLeg != 0 &&
          legs[currentLeg - 1].longLeg &&
          !_longPreWarned &&
          !leg.straightOn) {
        _longPreWarned = true;
        turnHandler(
          leg,
          _distanceToTurn,
          turn,
        );
      }
    }
    if (!_preWarned) {
      if (leg.straightOn) {
        straightOnHandler(leg, _distanceToTurn, turn);
      } else if (!leg.straightOn &&
          _distanceToTurn < 50 &&
          _distanceToTurn > 15) {
        _preWarned = true;
        turnHandler(leg, _distanceToTurn, turn);
      }
    }
    if (_distanceToTurn < 10 && !_warned && !leg.straightOn) {
      turnNow(leg, turn);
    }
  }

  bool isOnRoute(num value) {
    return value <= 2 && value >= -2;
  }

  dynamic getDistanceDiff(currPos, pos1, pos2) {
    return distanceCalculator.getDistanceBetween(currPos, pos1) +
        distanceCalculator.getDistanceBetween(currPos, pos2) -
        distanceCalculator.getDistanceBetween(pos1, pos2);
  }

  int roundDown(int distance) {
    if (_distanceToTurn < 20) {
      return _distanceToTurn;
    } else {
      return _distanceToTurn % 10 == 0
          ? _distanceToTurn
          : _distanceToTurn - (_distanceToTurn % 10);
    }
  }

  void turnNow(rp.Attributes leg, String turn) {
    setState(() {
      String extra = leg.extraInfo == null ? "" : leg.extraInfo;
      _navInstructions = "$turn $extra";
      _warned = true;
      _speak();
    });
  }

  void turnHandler(rp.Attributes leg, int distance, String turn) {
    setState(() {
      String extra = leg.extraInfo == null ? "" : leg.extraInfo;
      int m = roundDown(_distanceToTurn);
      _navInstructions = "om $m meter $turn $extra";
      _speak();
    });
  }

  void straightOnHandler(rp.Attributes leg, int distance, String turn) {
    String extra = leg.extraInfo == null ? "" : leg.extraInfo;
    setState(() {
      if (distance >= 20) {
        int m = roundDown(_distanceToTurn);
        _navInstructions =
            extra == "" ? "$turn i $m meter" : "$turn i $m meter $extra";
        _preWarned = true;
        _speak();
      }
    });
  }

  void updateLegInfo() {
    setState(() {
      _currLeg = legs[currentLeg].name;
      _currTurn =
          legs[currentLeg + 1].turn == null ? "" : legs[currentLeg].turn;
    });
  }

  Widget _buildNavBar() {
    return Container(
        color: Colors.grey[800],
        child: Wrap(children: <Widget>[
          Column(children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _currLeg,
                  style: TextStyle(color: Colors.white, fontSize: 17),
                )),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _distanceToTurn == 0
                      ? "Laddar information"
                      : "$_distanceToTurn meter",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container( width: 50, height: 50, decoration: BoxDecoration(image: DecorationImage(image: turnIcon)),),
                  Text(_currTurn,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ],
              ),
            )
          ]),
        ]));
  }
}

class Elevation {
  final int startE;
  final int endE;
  Elevation(this.startE, this.endE);

  int getElevation() {
    return endE;
  }

  int getElevation2() {
    return startE;
  }
}
