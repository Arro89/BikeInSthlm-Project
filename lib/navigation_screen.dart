

import 'package:bikeinsthlm/distance_calculator.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:location/location.dart';
import "http_fetch_service.dart";
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import "package:google_maps_webservice/places.dart";
import "./constants.dart";
import "artefacts/route_plan.dart" as rp;
import 'package:charts_flutter/flutter.dart' as charts;
const apiKey = "AIzaSyB1SCDPQTve0fb08847Wzgl-BoaYY8Qwuo";
const double CAMERA_ZOOM = 16;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
final DistanceCalculator distanceCalculator = DistanceCalculator();

class NavigationScreen extends StatefulWidget {
  final Function updateLocalVar;
  final Set<Marker> markers;
  final Text appBarText;
  final Set<Polyline> polylines;
  final List<LatLng> coordinateList;
  final List<rp.Attributes> legs;

  NavigationScreen({this.markers, this.appBarText, this.polylines, this.coordinateList, this.legs, this.updateLocalVar});
  @override

  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<NavigationScreen>{
  LatLng start;
  LatLng destination;
  int currentLeg = 1;


  final Set<Marker> _markers = {};
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: apiKey);
  GoogleMapController _mapController;
  bool _locationOn = false;
  bool _evaluateRoute = false;
  bool _showRouteInfo = false;
  bool _navigating = false;
  BitmapDescriptor roadworkPin;
  List<charts.Series<dynamic, num>> seriesList = List<charts.Series<dynamic, num>>();

  DatabaseReference _firestoreMarkers = FirebaseDatabase.instance.reference()
      .child("customMarkers");
  String appBarTitle = "Ruttplanering";

  Completer<GoogleMapController> _controller = Completer();
  static const _center = LatLng(59.32000, 18.06000);
  static LatLng yourLocation;
  LatLng test = LatLng(59.412046, 17.865930);
  loc.LocationData currentLocation;
  loc.Location location;
  List<rp.Marker2> legs = List<rp.Marker2>();
  String _currLeg = "";
  String _currTurn = "";
  int _distanceToTurn = 0;
  Icon _turnIcon = Icon(Icons.directions);
  MapType _currentMapType = MapType.normal;
  BitmapDescriptor bicycleMarker;


  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    _mapController = controller;
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
        "assets/images/constructionmarker.png")
        .then((onValue) {
      roadworkPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5, size: Size(12.0, 12.0)),
        'assets/bicyclepin.png')
        .then((onValue) {
      bicycleMarker = onValue;
    });
    _getLocation();
    startNavigation();
  }

  void _getLocation() async {
    var currentLocation = await Geolocator().getCurrentPosition();
    yourLocation = LatLng(currentLocation.latitude, currentLocation.longitude);
    _locationOn = true;

    setState(() {

      final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: yourLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: bicycleMarker,
      );
      _markers.add(marker);
      start = yourLocation;

    });
  }

  void startNavigation() {
    setState(() {
      _showRouteInfo = false;
      _evaluateRoute = false;
      _navigating = true;
      location = new loc.Location();
      location.onLocationChanged.listen((LocationData cLoc) {
        // cLoc contains the lat and long of the
        // current user's position in real time,
        // so we're holding on to it
        currentLocation = cLoc;
        updatePinOnMap();
      });
    });
  }

  void updateNavContainer() {

    LatLng currPos;
    var coordinateList = widget.coordinateList;
    currPos = LatLng(currentLocation.latitude, currentLocation.longitude);
    bool onRoute = false;
    int i = 0;
    if(currentLeg%10 == 0){
      i = currentLeg-10;
    }
    while(!onRoute && i != coordinateList.length){
      var distanceDiff = distanceCalculator.getDistanceBetween(currPos, coordinateList[i]) + distanceCalculator.getDistanceBetween(currPos, coordinateList[i+1]) - (distanceCalculator.getDistanceBetween(coordinateList[i], coordinateList[i+1]));
      if(distanceDiff <= 10 && distanceDiff >= -10){
        currentLeg = i+1;
        _distanceToTurn = distanceCalculator.getDistanceBetween(currPos, coordinateList[i+1]).toInt();
        print("CURRENT LEG ==> $currentLeg");
        print("Currentdistance ==> $_distanceToTurn");
        updateLegInfo();
        onRoute = true;
      }
      i++;
    }
  }

  void updateLegInfo(){
    setState(() {
      _currLeg = legs[currentLeg].attributes.name;
      _currTurn = legs[currentLeg].attributes.turn;
    });
  }

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation   CameraPosition cPosition = CameraPosition(

    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        cPosition)); // do this inside the setState() so Flutter gets notified
    // that a widget update is due
    setState(() {
      // updated position
      var pinPosition =
      LatLng(currentLocation.latitude, currentLocation.longitude);

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      widget.markers.removeWhere((m) => m.markerId.value == "curr_loc");
      widget.markers.add(Marker(
        markerId: MarkerId("curr_loc"),
        position: pinPosition, // updated position
        icon: bicycleMarker,
      ));
    });
  }





  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ScreenUtil.instance.setHeight(45)),
          child: AppBar(
            backgroundColor: Colors.grey[800].withOpacity(0.9),
            centerTitle: true,
            title: widget.appBarText,
            leading: IconButton(
              icon:
              Icon(Icons.keyboard_arrow_left, size: 34, color: Colors.green[400]),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            _buildGoogleMap(),
            _buildNavBar()
            //_buildContainer(),
          ],
        ),
      ),
    );
  }


  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      //onTap: _mapTapped,
      mapToolbarEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 17.0,
      ),
      polylines: widget.polylines,
      mapType: _currentMapType,
      markers: widget.markers,
    );
  }

  Widget _buildNavBar() {
    return Container(
        color: Colors.grey[800],
        child: Wrap(
            children: <Widget>[
              Column(
                  children: <Widget> [
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:  Text(_currLeg, style: TextStyle(color: Colors.white, fontSize: 17),)
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:  Text("$_distanceToTurn meter", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),)
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _turnIcon,
                          Text(_currTurn, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                        ], ),
                    )
                  ]
              ),
            ]
        )
    );
  }


}
