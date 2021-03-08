import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/widgets/alerts/createPinScreen.dart';
import 'package:bikeinsthlm/widgets/alerts/createPolylineScreen.dart';
import 'package:bikeinsthlm/widgets/alerts/customAlertDialog.dart';
import 'package:bikeinsthlm/widgets/alerts/myNotificationsAlert.dart';
import 'package:bikeinsthlm/widgets/customPinSheet.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/widgets/pumpSheet.dart';
import 'package:bikeinsthlm/widgets/roadWorkSheet.dart';
import 'package:bikeinsthlm/route_planner_screen.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'artefacts/polyline_snapper.dart' as pl;
import "http_fetch_service.dart";
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import "package:google_maps_webservice/places.dart" as gmw;
import 'package:bikeinsthlm/coordinate_conversion/SWEREF99Position.dart';
import "dataportalen_objects/feature.dart";
import 'package:bikeinsthlm/trafikverket_objects/situation.dart';
import "package:bikeinsthlm/custom_infowindow.dart";
import "authentication_login/authentication.dart";
import "package:bikeinsthlm/artefacts/error_report.dart";
import 'package:bikeinsthlm/widgets/drawer.dart';

const apiKey = "AIzaSyB1SCDPQTve0fb08847Wzgl-BoaYY8Qwuo";
var tappedPump;

enum PinType {
  pin,
  polyline,
}

enum PinCategory {
  roadProblem,
  closedRoad,
  obstacle,
  heavyTraffic,
  other,
  roadWork,
  icyRoad,
  roadSign,
}

class MainPage extends StatefulWidget {
  MainPage(
      {this.auth,
      this.onSignedOut,
      this.placingMarker,
      this.tempType,
      this.tempTitle,
      this.tempDescription,
      this.showNavBar});

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final dynamic placingMarker;
  final String tempType;
  final String tempTitle;
  final String tempDescription;

  bool showNavBar;

  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static StreamController<Map<String, dynamic>> _onMessageStreamController =
      StreamController.broadcast();
  static StreamController<Map<String, dynamic>> _streamController =
      StreamController.broadcast();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static final Stream<Map<String, dynamic>> onFcmMessage =
      _streamController.stream;

  setupFCMListeners() {
    print("Registered FCM Listeners");
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _onMessageStreamController.add(message);
        goToRoutePlanner();
      },
      onLaunch: (Map<String, dynamic> message) async {
        _streamController.add(message);
        goToRoutePlanner();
      },
      onResume: (Map<String, dynamic> message) async {
        _streamController.add(message);
        goToRoutePlanner();
      },
    );
  }

  void handlePath(Map<String, dynamic> dataMap) {
    var path = dataMap["route"];
    var id = dataMap["id"];
    handlePathByRoute(path, id);
  }

  void handlePathByRoute(String route, String routeId) {
    goToRoutePlanner();
  }

  Service service = new Service();
  TextEditingController _searchFieldController =
      TextEditingController(text: "Sök på en plats");

  Map<String, bool> _switchedList = {
    "Cykelpumpar": false,
    "Vägproblem": false,
    "Avstängd väg": false,
    "Hinder": false,
    "Hög trafik": false,
    "Övrigt": false,
    "Vägarbete": false,
    "Halka": false,
    "Felaktig skyltning": false,
  };

  //bool placingMarker = false;
  bool placingCustomPin = false;
  bool placingPinOnMap = false;
  bool customPinPlaced = false;
  bool draggableToastShown = false;
  bool showingButtons = true;
  bool placeSearched = false;
  String placeName = "";
  Destination searchedDestination;
  Marker customPin;

  bool creatingPin = false;

  String tempType;
  String tempTitle;
  String tempDescription;

  ///TEMPORARY SOLUTION ARVIN
  String currentUsername;
  String currentEmail;

  int pinCounter = 0;

  BitmapDescriptor workingPumpPin;
  BitmapDescriptor notWorkingPumpPin;
  BitmapDescriptor roadworkPin;
  BitmapDescriptor warningPin;
  BitmapDescriptor heavyTrafficPin;
  BitmapDescriptor icyRoadPin;
  BitmapDescriptor obstaclePin;
  BitmapDescriptor otherDangerPin;
  BitmapDescriptor roadClosedPin;
  BitmapDescriptor roadDamagePin;
  BitmapDescriptor roadSignPin;
  BitmapDescriptor customRoadWorkPin;

  gmw.GoogleMapsPlaces _places = gmw.GoogleMapsPlaces(apiKey: apiKey);
  StreamSubscription _mapIdleSubscription;
  InfoWidgetRoute _infoWidgetRoute;
  GoogleMapController _mapController;
  Completer<GoogleMapController> _controller = Completer();
  static const _center = LatLng(59.32000, 18.06000);
  List<LatLng> _linePoints = List<LatLng>();
  Set<Polyline> _polyLines = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var tappedMarkerData;
  final Set<Marker> _markers = {};

  static LatLng latLng;
  MapType _currentMapType = MapType.normal;
  //Ändring nedan
  loc.LocationData currentLocation;
  bool markerTapped = false;

  //DATABASE-RELATED
  Query _customPinQuery;

  final databaseReference = FirebaseDatabase.instance.reference();
  DatabaseReference _firestoreMarkers =
      FirebaseDatabase.instance.reference().child("customMarkers");
  List<ErrorReport> _errorReportList = new List<ErrorReport>();
  StreamSubscription<Event> _onMarkerAdded;
  StreamSubscription<Event> _onMarkerUpdated;
  StreamSubscription<Event> _onMarkerDeleted;

  int _currentIndex;
  int _selectedScreen;
  List<StatefulWidget> _screens;

  Map<String, Set<Marker>> customPinMap = Map<String, Set<Marker>>();

  @override
  void initState() {
    super.initState();
    createPinSets();
    _searchFieldController.buildTextSpan(style: TextStyle(color: Colors.black));
    setMarkerImage();
    _updatePumps();
    _updateRoadWork();
    updateSharedPreferences();
    _centerOnUser();

    _customPinQuery = _firestoreMarkers;
    _onMarkerAdded = _customPinQuery.onChildAdded.listen(onEntryAdded);
    _onMarkerUpdated = _customPinQuery.onChildChanged.listen(onEntryUpdated);
    _onMarkerDeleted = _customPinQuery.onChildRemoved.listen(onEntryDeleted);

    _selectedScreen = 0;
    _screens = [
      RoutePlannerScreen(
        auth: widget.auth,
        currentUsername: currentUsername,
      ),
      //updateLocalVar: updateLocalVar),
    ];
  }

  void createPinSets() {
    Set<Marker> pumps = {};
    Set<Marker> roadwork = {};
    Set<Marker> otherPins = {};
    Set<Marker> roadProblemPins = {};
    Set<Marker> closedRoadPins = {};
    Set<Marker> obstaclePins = {};
    Set<Marker> heavyTrafficPins = {};
    Set<Marker> icyRoadPins = {};
    Set<Marker> roadSignPins = {};
    setState(() {
      customPinMap.addAll({
        "Cykelpumpar": pumps,
        "Vägarbete": roadwork,
        "Övrigt": otherPins,
        "Vägproblem": roadProblemPins,
        "Avstängd väg": closedRoadPins,
        "Hinder": obstaclePins,
        "Hög trafik": heavyTrafficPins,
        "Halka": icyRoadPins,
        "Felaktig skyltning": roadSignPins,
      });
    });
  }

  @override
  void dispose() {
    _onMarkerAdded.cancel();
    _onMarkerUpdated.cancel();
    _onMarkerDeleted.cancel();
    super.dispose();
  }

  //ARVIN - Metod för att centrera på användaren vid inloggning.
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

  void startPlacingPin() {
    setState(() {
      placeSearched = false;
      creatingPin = true;
      showingButtons = false;
    });
  }

  void _pinAtLocation() async {
    var location = new loc.Location();
    currentLocation = await location.getLocation();
    LatLng pos = LatLng(currentLocation.latitude, currentLocation.longitude);
    String address = await service.getAddress(pos);
    createTempPin(pos, address);
  }

  void onEntryAdded(Event event) {
    checkDatabaseIntegrity(ErrorReport.fromSnapshot(event.snapshot));
    ErrorReport toAdd = ErrorReport.fromSnapshot(event.snapshot);
    setState(() {
      _errorReportList.add(toAdd);
      _addPinsAsMarkers(type: toAdd.type);
    });
  }

  void onEntryUpdated(Event event) {
    var oldEntry = _errorReportList.singleWhere((entry) {
      return entry.markerId == event.snapshot.key;
    });
    var updatedEntry = ErrorReport.fromSnapshot(event.snapshot);
    print("OLD ENTRY ===> ${oldEntry.isAdded}");
    print(updatedEntry.isAdded);

    setState(() {
      _errorReportList[_errorReportList.indexOf(oldEntry)] = updatedEntry;
      customPinMap[updatedEntry.type].removeWhere(
          (toUpdate) => toUpdate.markerId.value == updatedEntry.markerId);
      _markers.removeWhere(
          (toUpdate) => toUpdate.markerId.value == updatedEntry.markerId);
      print(
          "ENTRY UPDATED ====> ${_errorReportList[_errorReportList.indexOf(updatedEntry)].creator}");
      print("LIKES ${updatedEntry.likes}");
      print("DISLIKES ${updatedEntry.dislikes}");
      _addPinsAsMarkers(type: updatedEntry.type);
    });
  }

  void onEntryDeleted(Event event) {
    ErrorReport deletedEntry = _errorReportList.singleWhere((entry) {
      return entry.markerId == event.snapshot.key;
    });

    setState(() {
      _errorReportList.removeAt(_errorReportList.indexOf(deletedEntry));
      print("ERROR REPORT LIST AFTER DEL  $_errorReportList");
      customPinMap[deletedEntry.type].removeWhere(
          (toRemove) => toRemove.markerId.value == deletedEntry.markerId);
      print("CUSTOMPINMAP AFTER ${customPinMap[deletedEntry.type]}");
      _markers.removeWhere(
          (toRemove) => toRemove.markerId.value == deletedEntry.markerId);
      print("MARKERS $_markers");
    });
  }

  void updateCustomPin(ErrorReport errorReport) {
    String type = errorReport.type;
    databaseReference
        .reference()
        .child(type)
        .child(errorReport.markerId)
        .set(errorReport.toJson());
  }

  void deleteCustomPin(ErrorReport errorReport, int index) {
    databaseReference
        .reference()
        .child(errorReport.markerId)
        .remove()
        .then((_) {
      setState(() {});
    });
  }

  //ADD PIN IN DATABASE
  void addInDatabase(String type, String title, double lat, double lon,
      {String description, String endDate, String address}) async {
    String uid = await widget.auth.currentUser();
    String creator = await DatabaseService(uid: uid).getCreator();
    var errorReport = new ErrorReport(type, creator, title, lat, lon,
        description: description, endDate: endDate, address: address);
    print(errorReport.type);
    DatabaseService(uid: uid).createRecord(errorReport);
    //clearLocalData();
  }

  @override
  Widget build(BuildContext context) {
    double defaultScreenWidth = 400.0;
    double defaultScreenHeight = 810.0;
    ScreenUtil.instance = ScreenUtil(
      width: defaultScreenWidth,
      height: defaultScreenHeight,
      allowFontScaling: true,
    )..init(context);

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: ProfileDrawer(
          auth: widget.auth,
          onSignedOut: widget.onSignedOut,
          currentEmail: currentEmail,
          currentUsername: currentUsername,
          markers: getAllPins(),
        ),
        appBar: PreferredSize(
          preferredSize: Size(ScreenUtil.instance.setHeight(70),
              ScreenUtil.instance.setHeight(70)),
          child: Container(
            margin: EdgeInsets.only(top: ScreenUtil.instance.setHeight(10)),
            child: AppBar(
              automaticallyImplyLeading: false,
              title: _buildSearchField(),
              textTheme: Typography.blackCupertino,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            GoogleMap(
              padding: EdgeInsets.only(top: ScreenUtil.instance.setHeight(100)),
              mapToolbarEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: _onMapCreated,
              onTap: _mapTapped,
              onLongPress: _mapLongPress,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              mapType: _currentMapType,
              markers: _markers,
              polylines: _polyLines,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.topCenter,
                        color: Colors.grey[800].withOpacity(0.9),
                        child: Stack(
                          children: <Widget>[
                            Visibility(
                              visible: showingButtons,
                              child: ExpandableNotifier(
                                child: Expandable(
                                  collapsed: _buildTopContainerCollapsed(),
                                  expanded: _buildTopContainerExpanded(),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: creatingPin,
                              child: _buildPinAppBar(),
                            ),
                            Visibility(
                              visible: placeSearched,
                              child: _buildSearchedPlacedContainer(),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.bottomRight,
                      padding:
                          EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(
                            () {
                              _centerOnUser();
                            },
                          );
                        },
                        backgroundColor: Colors.grey[800].withOpacity(0.9),
                        child: Icon(Icons.location_searching),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(seconds: 1),
                      height: widget.showNavBar
                          ? ScreenUtil.instance.setHeight(75)
                          : 0.0,
                      child: widget.showNavBar
                          ? BottomNavigationBar(
                              backgroundColor:
                                  Colors.grey[800].withOpacity(0.9),
                              selectedItemColor: Colors.white,
                              unselectedItemColor: Colors.white,
                              type: BottomNavigationBarType.fixed,
                              iconSize: ScreenUtil.instance.setHeight(40),
                              selectedFontSize:
                                  ScreenUtil.instance.setHeight(14),
                              unselectedFontSize:
                                  ScreenUtil.instance.setHeight(14),
                              currentIndex: _selectedScreen,
                              onTap: (int index) {
                                _onTap(index);
                              },
                              items: [
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.directions),
                                      title: Text("Sök rutt")),
                                  BottomNavigationBarItem(
                                    icon: Icon(
                                      Icons.add_location,
                                      color: creatingPin
                                          ? Colors.green[400]
                                          : Colors.white,
                                    ),
                                    title: Text(
                                      "Skapa pin",
                                      style: TextStyle(
                                          color: creatingPin
                                              ? Colors.green[400]
                                              : Colors.white),
                                    ),
                                  ),
                                  BottomNavigationBarItem(
                                      icon: Icon(Icons.notifications),
                                      title: Text("Notiser")),
                                ])
                          : SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void startPlaceOnMap() {
    setState(() {
      if (!placingPinOnMap) {
        showToast(
          "Klicka på kartan där du vill placera markören.",
          textStyle: TextStyle(
              color: Colors.white, fontSize: ScreenUtil.instance.setSp(14)),
          position: ToastPosition.bottom,
          backgroundColor: Colors.grey[800],
          textPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
          dismissOtherToast: true,
        );
      }
      placingPinOnMap = !placingPinOnMap;
    });
  }

  _buildPinAppBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
          ScreenUtil.instance.setHeight(20),
          ScreenUtil.instance.setHeight(70),
          ScreenUtil.instance.setHeight(20),
          ScreenUtil.instance.setHeight(10)),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: ScreenUtil.instance.setHeight(40),
                width: ScreenUtil.instance.setHeight(120),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: startPlaceOnMap,
                  color: placingPinOnMap ? Colors.green[400] : Colors.grey[350],
                  child: Text(
                    "Välj på kartan",
                    style: TextStyle(
                      fontSize: ScreenUtil.instance.setHeight(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ScreenUtil.instance.setHeight(20)),
              Container(
                height: ScreenUtil.instance.setHeight(40),
                width: ScreenUtil.instance.setHeight(120),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () => {
                    _pinAtLocation(),
                  },
                  child: Text(
                    "På min plats",
                    style: TextStyle(
                      fontSize: ScreenUtil.instance.setHeight(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ScreenUtil.instance.setHeight(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.centerRight,
                height: ScreenUtil.instance.setHeight(40),
                width: ScreenUtil.instance.setHeight(140),
                child: FlatButton(
                  onPressed: openCategoryDialog,
                  child: Text(
                    "Rapportera",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: ScreenUtil.instance.setHeight(18),
                    ),
                  ),
                ),
              ),
              Container(
                height: ScreenUtil.instance.setHeight(30),
                child: VerticalDivider(color: Colors.white),
              ),
              Container(
                alignment: Alignment.centerLeft,
                height: ScreenUtil.instance.setHeight(40),
                width: ScreenUtil.instance.setHeight(140),
                child: FlatButton(
                  onPressed: stopPlacingPin,
                  child: Text(
                    "Avbryt",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: ScreenUtil.instance.setHeight(18),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void openCategoryDialog() {
    setState(
      () {
        if (_markers.contains(customPin))
          _chooseCategoryAlert();
        else
          showDialog(
            context: context,
            builder: (_) {
              return CustomAlertDialog(
                  title: "Ingen plats vald",
                  content:
                      "Klicka på \"På min plats\" för att placera markören på din position. Du kan även placera markören direkt på kartan genom att söka på platsen i sökfältet eller klicka på \"Välj på kartan\".");
            },
          );
      },
    );
  }

  void stopPlacingPin() {
    setState(() {
      creatingPin = !creatingPin;
      showingButtons = true;
      placingPinOnMap = false;
      //_markers.removeWhere((m) => m.markerId.value == "temporary pin");
      _markers.remove(customPin);
      customPin = null;
    });
  }

  _chooseCategoryAlert() {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text("Välj kategori",
          style: TextStyle(
            color: Colors.green[400],
            fontSize: ScreenUtil.instance.setHeight(22),
          ),
          textAlign: TextAlign.center),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Wrap(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(height: ScreenUtil.instance.setHeight(20)),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.roadProblem),
                        AssetImage("assets/images/roadDamage.png"),
                        "Vägproblem"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.closedRoad),
                        AssetImage(
                          "assets/images/closedRoad.png",
                        ),
                        "Avstängd väg"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.pin, PinCategory.obstacle),
                        AssetImage("assets/images/obstacle.png"),
                        "Hinder"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.heavyTraffic),
                        AssetImage("assets/images/heavyTraffic.png"),
                        "Hög trafik"),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(height: ScreenUtil.instance.setHeight(20)),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.other),
                        AssetImage("assets/images/otherDanger.png"),
                        "Övrigt"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.roadWork),
                        AssetImage(
                          "assets/images/roadWork.png",
                        ),
                        "Vägarbete"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.polyline, PinCategory.icyRoad),
                        AssetImage("assets/images/icyRoad.png"),
                        "Halka"),
                    _buildObjects(
                        () => _errorReportAlert(
                            PinType.pin, PinCategory.roadSign),
                        AssetImage("assets/images/roadSign.png"),
                        "Felaktig skyltning"),
                  ],
                ),
              ],
            ),
            Container(
              alignment: Alignment.center,
              child: _buildBackButton(),
            ),
          ],
        ),
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

  confirmationAlert() {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text("Pin ej sparad",
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(20),
          ),
          textAlign: TextAlign.center),
      content: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text("Du har inte skapat någon pin. Vill du avbryta?",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil.instance.setHeight(16),
              ),
              textAlign: TextAlign.center),
          SizedBox(height: ScreenUtil.instance.setHeight(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Fortsätt skapa pin",
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: ScreenUtil.instance.setHeight(16),
                  ),
                ),
              ),
              FlatButton(
                onPressed: () => {
                  stopPlacingPin,
                  Navigator.pop(context),
                  goToRoutePlanner(),
                },
                child: Text(
                  "Avbryt",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(16),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _errorReportAlert(PinType type, PinCategory category) {

    tempType = _handleCategory(category);
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text(_handleCategory(category),
          style: TextStyle(
            color: Colors.green[400],
            fontSize: ScreenUtil.instance.setHeight(26),
          ),
          textAlign: TextAlign.center),
      content: Container(
        child: Wrap(
          children: <Widget>[
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  type == PinType.pin
                      ? CreatePinScreen()
                      : CreatePolyLineScreen(),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: ScreenUtil.instance.setHeight(10)),
                        _buildTitleField(),
                        SizedBox(height: ScreenUtil.instance.setHeight(10)),
                        _buildCreateButton(),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: ScreenUtil.instance.setHeight(80)),
                          child: Divider(
                            color: Colors.white,
                          ),
                        ),
                        _buildBackButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildCreateButton() {
    return FlatButton(
      onPressed: () {
        if (tempTitle == null) {
          showDialog(
            context: context,
            builder: (_) {
              return CustomAlertDialog(
                  title: "Fel",
                  content: "Vänligen ange en rubrik för att skapa din pin.");
            },
          );
        } else {
          setState(
            () {
              _markers.removeWhere((m) => m.markerId.value == "temporary pin");
              _switchedList[tempType] = true;
              creatingPin = false;
              showingButtons = true;
              _switchedList[tempType] = true;
            },
          );
          addInDatabase(
            tempType,
            tempTitle,
            customPin.position.latitude,
            customPin.position.longitude,
            description: tempDescription,
            address: customPin.infoWindow.title,
          );
          customPin = null;
          tempTitle = tempType = tempDescription = null;

          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Text(
        "Skapa",
        style: TextStyle(
          color: Colors.green[400],
          fontSize: ScreenUtil.instance.setHeight(24),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return FlatButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        "Avbryt",
        style: TextStyle(
          color: Colors.red,
          fontSize: ScreenUtil.instance.setHeight(24),
        ),
      ),
    );
  }

  _handleCategory(PinCategory category) {
    switch (category) {
      case PinCategory.roadProblem:
        return "Vägproblem";
        break;
      case PinCategory.closedRoad:
        return "Avstängd väg";
        break;
      case PinCategory.obstacle:
        return "Hinder";
        break;
      case PinCategory.heavyTraffic:
        return "Hög trafik";
        break;
      case PinCategory.other:
        return "Övrigt";
        break;
      case PinCategory.roadWork:
        return "Vägarbete";
        break;
      case PinCategory.icyRoad:
        return "Halka";
        break;
      case PinCategory.roadSign:
        return "Felaktig skyltning";
        break;
    }
  }

  Widget _buildTitleField() {
    return Container(
      height: ScreenUtil.instance.setHeight(50),
      child: TextFormField(
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (title) => tempTitle = title,
        cursorColor: Colors.grey[800],
        decoration: _buildTextFieldDecoration(
          "Rubrik",
          Colors.grey[350],
          Colors.grey[800],
        ), //Ligger i constants
      ),
    );
  }

  _buildTextFieldDecoration(String text, Color fillColor, Color textColor) {
    return InputDecoration(
      fillColor: fillColor,
      filled: true,
      hintText: text,
      hintStyle: TextStyle(
          fontSize: ScreenUtil.instance.setHeight(16), color: textColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Colors.green[400], width: ScreenUtil.instance.setWidth(2)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildObjects(Function onTap, AssetImage logo, String text) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: ScreenUtil.instance.setHeight(80),
            width: ScreenUtil.instance.setHeight(80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                image: logo,
              ),
            ),
          ),
        ),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        Text(
          text,
          style: TextStyle(
            fontSize: ScreenUtil.instance.setHeight(18),
            color: Colors.white,
          ),
        ),
        SizedBox(height: ScreenUtil.instance.setHeight(20)),
      ],
    );
  }

  goToRoutePlanner({Destination destination}) {
    setState(() {
      creatingPin = false;
      placeSearched = false;
      showingButtons = true;
    });
    if (destination != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return RoutePlannerScreen(
          auth: widget.auth,
          customPins: getAllPins(),
          currentUsername: currentUsername,
          destination: destination,
        );
      }));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return RoutePlannerScreen(
            auth: widget.auth,
            customPins: getAllPins(),
            currentUsername: currentUsername);
      }));
    }
  }

  _onTap(int index) async {
    FirebaseUser user = await widget.auth.getUser();
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        if (creatingPin)
          confirmationAlert();
        else
          goToRoutePlanner();
        break;
      case 1:
        print("SOMETHINGS");
        user.isAnonymous
            ? showDialog(
                context: context,
                builder: (_) {
                  return CustomAlertDialog(
                      title: "Fel",
                      content:
                          "Du kan inte skapa pins som gäst. Logga in med ditt Cadence eller Google-konto.");
                },
              )
            : startPlacingPin();
        break;
      case 2:
        user.isAnonymous
            ? showDialog(
                context: context,
                builder: (_) {
                  return CustomAlertDialog(
                      title: "Fel",
                      content:
                          "Du kan inte se notiser som gäst. Logga in med ditt Cadence eller Google-konto.");
                },
              )
            : showDialog(
                context: context,
                builder: (_) {
                  return MyNotificationsAlert();
                },
              );
        break;
    }
  }

  _buildSearchField() {
    return PlacesAutocompleteField(
      apiKey: apiKey,
      //ändringar nedan för att se bara svenska autocompletes
      language: "se",
      components: [new gmw.Component(gmw.Component.country, "se")],
      mode: Mode.overlay,
      controller: _searchFieldController,
      onSelected: placeSelected,
      inputDecoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 2),
        suffixIcon: Icon(
          Icons.search,
          color: Colors.grey[800],
          size: ScreenUtil.instance.setHeight(30),
        ),
        prefixIcon: GestureDetector(
          onTap: () => _scaffoldKey.currentState.openDrawer(),
          child: Icon(
            Icons.menu,
            color: Colors.grey[800],
            size: ScreenUtil.instance.setHeight(30),
          ),
        ),
        fillColor: Colors.grey[300].withOpacity(0.9),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      //  ),
    );
  }

  Future<void> placeSelected(gmw.Prediction p) async {
    gmw.PlacesDetailsResponse response =
        await _places.getDetailsByPlaceId(p.placeId);
    var location = response.result.geometry.location;
    LatLng pos = LatLng(location.lat, location.lng);
    var latLng = pos;
    if (creatingPin) {
      createTempPin(latLng, response.result.name);
    } else {
      _moveCamera(latLng, prefZoom: 17.0);
      setState(() {
        showingButtons = false;
        placeSearched = true;
        placeName = response.result.name;
        searchedDestination = Destination(placeName, pos);
        createTempPin(pos, response.result.name,
            draggable: false,
            function: () => {
                  setState(() {
                    if (showingButtons) {
                      showingButtons = false;
                      placeSearched = true;
                    }
                  })
                });
      });
    }
  }

  void createTempPin(LatLng location, String title,
      {bool draggable, Function function}) {
    draggable = draggable ?? true;
    setState(() {
      customPin = Marker(
        markerId: MarkerId("temporary pin"),
        position: location,
        draggable: draggable,
        onTap: function ?? () => {},
        onDragEnd: ((value) {
          createTempPin(value, title);
        }),
        infoWindow: InfoWindow(title: title),
      );
      _markers.remove(customPin);
      _markers.add(customPin);
      placingCustomPin = false;
      placingPinOnMap = false;
      customPinPlaced = true;
    });
    if (!draggableToastShown && draggable) {
      showToast(
        "Håll och dra markören för att flytta den.",
        textStyle: TextStyle(
            color: Colors.white, fontSize: ScreenUtil.instance.setSp(14)),
        position: ToastPosition.bottom,
        backgroundColor: Colors.grey[800],
        textPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
        dismissOtherToast: true,
      );
    }
    double prefZoom = !draggable ? 12.0 : 17.0;
    _moveCamera(location, prefZoom: prefZoom);
  }

  _buildTopContainerCollapsed() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil.instance.setHeight(70)),
      child: Stack(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _handleRoadWorks(),
              _handleObstacles(),
              _handleClosedRoads(),
            ],
          ),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: ScreenUtil.instance.setHeight(45)),
            child: ExpandableButton(
              child: Icon(
                Icons.keyboard_arrow_down,
                size: ScreenUtil.instance.setHeight(40),
                color: Colors.green[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildTopContainerExpanded() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil.instance.setHeight(70)),
      child: Column(
        children: <Widget>[
          Wrap(
            children: <Widget>[
              _handleRoadWorks(),
              _handleObstacles(),
              _handleClosedRoads(),
              _handleRoadProblems(),
              _handleHeavyTraffic(),
              _handleRoadSigns(),
              _handleOtherDanger(),
              _handleIcyRoads(),
              _handlePumps(),
            ],
          ),
          Container(
            child: ExpandableButton(
              child: Icon(
                Icons.keyboard_arrow_up,
                size: ScreenUtil.instance.setHeight(40),
                color: Colors.green[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _handleRoadProblems() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Vägproblem"] = !_switchedList["Vägproblem"];

            ///SHAREDPREFERENCES
            addButtonPreferences("roadProblems", _switchedList["Vägproblem"]);
          },
        ),
        updateCustomPins(toUpdate: "Vägproblem"),
      },
      child: _buildTopNavigationBarButton(
          "Vägproblem", _switchedList["Vägproblem"]),
    );
  }

  _handleClosedRoads() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Avstängd väg"] = !_switchedList["Avstängd väg"];

            ///SHAREDPREFERENCES
            addButtonPreferences("closedRoads", _switchedList["Avstängd väg"]);
          },
        ),
        updateCustomPins(toUpdate: "Avstängd väg"),
      },
      child: _buildTopNavigationBarButton(
          "Avstängd väg", _switchedList["Avstängd väg"]),
    );
  }

  _handleObstacles() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Hinder"] = !_switchedList["Hinder"];

            ///SHAREDPREFERENCES
            addButtonPreferences("obstacles", _switchedList["Hinder"]);
          },
        ),
        updateCustomPins(toUpdate: "Hinder"),
      },
      child: _buildTopNavigationBarButton("Hinder", _switchedList["Hinder"]),
    );
  }

  _handleHeavyTraffic() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Hög trafik"] = !_switchedList["Hög trafik"];

            ///SHAREDPREFERENCES
            addButtonPreferences("heavyTraffic", _switchedList["Hög trafik"]);
          },
        ),
        updateCustomPins(toUpdate: "Hög trafik"),
      },
      child: _buildTopNavigationBarButton(
          "Hög trafik", _switchedList["Hög trafik"]),
    );
  }

  _handleOtherDanger() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Övrigt"] = !_switchedList["Övrigt"];

            ///SHAREDPREFERENCES
            addButtonPreferences("others", _switchedList["Övrigt"]);
          },
        ),
        //_placeCustomPins(),
        //_addPinsAsMarkers(_errorReportList, _switchedList["Övrigt"])
        updateCustomPins(toUpdate: "Övrigt"),
      },
      child: _buildTopNavigationBarButton("Övrigt", _switchedList["Övrigt"]),
    );
  }

  _handleRoadWorks() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Vägarbete"] = !_switchedList["Vägarbete"];

            ///SHAREDPREFERENCES
            addButtonPreferences("roadWorks", _switchedList["Vägarbete"]);
          },
        ),
        updateCustomPins(toUpdate: "Vägarbete"),
      },
      child:
          _buildTopNavigationBarButton("Vägarbete", _switchedList["Vägarbete"]),
    );
  }

  _handleIcyRoads() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Halka"] = !_switchedList["Halka"];

            ///SHAREDPREFERENCES
            addButtonPreferences("icyRoads", _switchedList["Halka"]);
          },
        ),
        updateCustomPins(toUpdate: "Halka"),
      },
      child: _buildTopNavigationBarButton("Halka", _switchedList["Halka"]),
    );
  }

  _handleRoadSigns() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Felaktig skyltning"] =
                !_switchedList["Felaktig skyltning"];

            ///SHAREDPREFERENCES
            addButtonPreferences(
                "roadSigns", _switchedList["Felaktig skyltning"]);
          },
        ),
        updateCustomPins(toUpdate: "Felaktig skyltning"),
      },
      child: _buildTopNavigationBarButton(
          "Felaktig skyltning", _switchedList["Felaktig skyltning"]),
    );
  }

  _handlePumps() {
    return GestureDetector(
      onTap: () => {
        setState(
          () {
            _switchedList["Cykelpumpar"] = !_switchedList["Cykelpumpar"];

            ///SHAREDPREFERENCES
            addButtonPreferences("pumps", _switchedList["Cykelpumpar"]);
          },
        ),
        updateCustomPins(toUpdate: "Cykelpumpar")
      },
      child: _buildTopNavigationBarButton(
          "Cykelpumpar", _switchedList["Cykelpumpar"]),
    );
  }

  _buildTopNavigationBarButton(String text, bool isSwitched) {
    return Container(
      margin: EdgeInsets.all(ScreenUtil.instance.setHeight(2.5)),
      alignment: Alignment.center,
      height: ScreenUtil.instance.setHeight(40),
      width: ScreenUtil.instance.setHeight(110),
      decoration: BoxDecoration(
        color: isSwitched ? Colors.green[400] : Colors.grey[350],
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey[800],
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: ScreenUtil.instance.setHeight(13),
        ),
      ),
    );
  }

  Widget _buildSearchedPlacedContainer() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil.instance.setHeight(70)),
      child: Column(
        children: <Widget>[
          Center(
              child: Text(placeName,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
          Center(
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: navigateHerePressed,
              //goToRoutePlanner(destination: searchedDestination),
              color: Colors.grey[350],
              //color: Colors.green[400],
              //_chooseCategoryAlert(),

              child: Text("Navigera hit"),
            ),
          )
        ],
      ),
    );
  }

//hello
  void navigateHerePressed() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "temporary pin");
      _searchFieldController.text = "Sök på en plats";
    });
    goToRoutePlanner(destination: searchedDestination);
  }

  void updateCurrentUsername() async {
    FirebaseUser user = await widget.auth.getUser();
    if (user != null) {
      String username = await DatabaseService(uid: user.uid).getUsersName();
      setState(() {
        currentUsername = username;
      });
    } else {
      setState(() {
        currentUsername = "Gäst";
      });
    }
  }

  void updateCurrentEmail() async {
    FirebaseUser user = await widget.auth.getUser();
    if (user != null) {
      String email = await DatabaseService(uid: user.uid).getUsersEmail();
      setState(() {
        currentEmail = email;
      });
    } else {
      setState(() {
        currentEmail = "Gäst-konto";
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    updateCurrentUsername();
    updateCurrentEmail();
    //service.fetchPumps();
    //service.fetchWork();

    _controller.complete(controller);
    _mapController = controller;

    //_placeCustomPins();
  }

  void setMarkerImage() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/pumpWorkingMarker.png")
        .then((onValue) {
      workingPumpPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/pumpNotWorkingMarker.png")
        .then((onValue) {
      notWorkingPumpPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/roadWorkMarker.png")
        .then((onValue) {
      roadworkPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/warningPin.png")
        .then((onValue) {
      warningPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/heavyTrafficPin.png")
        .then((onValue) {
      heavyTrafficPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/icyRoadPin.png")
        .then((onValue) {
      icyRoadPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/obstaclePin.png")
        .then((onValue) {
      obstaclePin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/otherDangerPin.png")
        .then((onValue) {
      otherDangerPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/roadClosedPin.png")
        .then((onValue) {
      roadClosedPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/roadDamagePin.png")
        .then((onValue) {
      roadDamagePin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/roadSignPin.png")
        .then((onValue) {
      roadSignPin = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5, size: Size(50.0, 50.0)),
            "assets/images/customRoadworkPin.png")
        .then((onValue) {
      customRoadWorkPin = onValue;
    });
  }

  //ARVIN
  void clearLocalData() {
    tempType = null;
    tempTitle = null;
    tempDescription = null;
  }

  Future<void> _updateRoadWork() async {
    List<Situation> situations = await service.fetchWork();
    for (int i = 0; i < situations.length; i++) {
      Situation situation = situations[i];
      for (int j = 0; j < situation.deviation.length; j++) {
        var sit = situation.deviation[0];
        if (sit.actualMessage != null) {
          customPinMap["Vägarbete"].add(
            Marker(
              position: LatLng(situation.deviation[j].geometry.coordinates[0],
                  situation.deviation[j].geometry.coordinates[1]),
              markerId: MarkerId(situation.deviation[j].geometry.wGS84),
              icon: roadworkPin,
              onTap: () => _showModal(sit, "roadwork"),
            ),
          );
        }
      }
    }
    updateCustomPins(toUpdate: "Vägarbete");
  }

  void _mapLongPress(LatLng location) async {
    if (!creatingPin) {
      String address = await service.getAddress(location);
      setState(() {
        searchedDestination = Destination(address, location);
        placeSearched = true;
        showingButtons = false;
        placeName = address ?? "Ingen adress hittades";
      });
      createTempPin(location, address, draggable: false);
    }
  }

  void _mapTapped(LatLng location,
      {String type, String title, String description}) async {
    //=========RITA POLYLINE FÖR FELANMÄLNING AV VÄGAR, SKALL WRAPAS I EN BOOLEAN===================================
    /* _linePoints.add(location);
    pinCounter++;
    if(pinCounter > 2)
      setState(() {
        _polyLines.add(getPolyLine(_linePoints));
      });
    if(pinCounter > 3){
      _polyLines.clear();
      drawSnappedLine();
    }
    */

    if (placingPinOnMap) {
      String address = await service.getAddress(location);
      createTempPin(location, address);
    } else if (placeSearched) {
      setState(() {
        placeSearched = false;
        showingButtons = true;
      });
    } else
      _moveCamera(
        location,
      );
  }

  void drawSnappedLine() async {
    pl.SnappedLine line = await service.getSnappedLine(_linePoints);
    List<LatLng> listan = List<LatLng>();
    for (pl.SnappedPoints sp in line.snappedPoints) {
      listan.add(LatLng(sp.location.latitude, sp.location.longitude));
    }
    setState(() {
      _polyLines.add(getPolyLine(listan));
    });
  }

  void _showModal(var dataObject, String type) {
    Widget sheet;
    switch (type) {
      case "pump":
        sheet = PumpSheet(widget.auth, getAllPins(), dataObject);
        break;
      case "roadwork":
        sheet = RoadWorkSheet(dataObject);
        break;
      case "custompin":
        sheet = CustomPinSheet(dataObject, widget.auth);
        break;
    }
    //Future<void> future = vad är detta?
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return sheet;
        },
        context: _scaffoldKey.currentContext);
  }

//Lägger till pumparna som markers
  Future<void> _updatePumps() async {
    List<Features> feature = await service.fetchPumps();
    for (int i = 0; i < feature.length; i++) {
      var pump = feature[i];
      BitmapDescriptor pumpPin =
          (pump.properties.working) ? workingPumpPin : notWorkingPumpPin;
      print(pump.geometry.position);
      customPinMap["Cykelpumpar"].add(
        Marker(
          position: SWEREF99Position(pump.geometry.coordinates[1],
                  feature[i].geometry.coordinates[0])
              .toWGS84()
              .toLatLng(),
          markerId: MarkerId(pump.properties.adress.toString()),
          icon: pumpPin,
          onTap: () => _showModal(pump, "pump"),
        ),
      );
    }
    updateCustomPins(toUpdate: "Cykelpumpar");
  }

  Polyline getPolyLine(List<LatLng> listan) {
    Map<PolylineId, Polyline> _mapPolylines = {};
    int _polylineIdCounter = 1;
    String polylineIdVal = 'polyline_id_$_polylineIdCounter';
    _polylineIdCounter++;
    PolylineId polylineId = PolylineId(polylineIdVal);
    final Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.red,
      width: 4,
      points: listan,
    );
    _mapPolylines[polylineId] = polyline;

    return polyline;
  }

  _addPinsAsMarkers({type}) {
    setState(
      () {
        for (ErrorReport errRep in _errorReportList) {
          BitmapDescriptor pinImage = getMarkerImage(errRep.type);
          if (!errRep.isAdded) {
            Marker toAdd = Marker(
                position: LatLng(errRep.lat, errRep.lon),
                markerId: MarkerId(errRep.markerId),
                icon: pinImage,
                onTap: () => _showModal(errRep, "custompin"));
            customPinMap[errRep.type].add(toAdd);
            print(customPinMap[errRep.type]);
            errRep.isAdded = true;
          }
        }
      },
    );
    type != null ? updateCustomPins(toUpdate: type) : updateCustomPins();
  }

  BitmapDescriptor getMarkerImage(String type) {
    BitmapDescriptor pin;
    switch (type) {
      case "Hinder":
        pin = obstaclePin;
        break;
      case "Vägproblem":
        pin = roadDamagePin;
        break;
      case "Avstängd väg":
        pin = roadClosedPin;
        break;
      case "Hög trafik":
        pin = heavyTrafficPin;
        break;
      case "Halka":
        pin = icyRoadPin;
        break;
      case "Felaktig skyltning":
        pin = roadSignPin;
        break;
      case "Övrigt":
        pin = otherDangerPin;
        break;
      case "Vägarbete":
        pin = customRoadWorkPin;
        break;
    }
    return pin;
  }

  void updateCustomPins({String toUpdate}) {
    //checkDatabaseIntegrity();
    setState(() {
      if (toUpdate != null) {
        if (_switchedList[toUpdate])
          _markers.addAll(customPinMap[toUpdate]);
        else
          _markers.removeAll(customPinMap[toUpdate]);
      } else {
        for (MapEntry<String, bool> entry in _switchedList.entries) {
          var toAdd = customPinMap[entry.key];
          if (toAdd != null) {
            if (entry.value)
              _markers.addAll(toAdd);
            else
              _markers.removeAll(toAdd);
          }
        }
      }
    });
  }

  ///SHARED PREFERENCES
  void addButtonPreferences(String button, bool pressed) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(button, pressed);
    //printSP();
  }

  void printSP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(
        "SHAREDPREFS ROADWORK ===============> ${prefs.getBool("roadWorks")}");
    print("SHAREDPREFS PUMPS ==================> ${prefs.getBool("pumps")}");
    print(
        "SHAREDPREFS ROADPROBS ==============> ${prefs.getBool("roadProblems")}");
    print(
        "SHAREDPREFS CLOSEDROADS ============> ${prefs.getBool("closedRoads")}");
    print(
        "SHAREDPREFS OBSTACLES ==============> ${prefs.getBool("obstacles")}");
    print(
        "SHAREDPREFS HEAVY TRAFFIC ==========> ${prefs.getBool("heavyTraffic")}");
    print("SHAREDPREFS OTHERS =================> ${prefs.getBool("others")}");
    print("SHAREDPREFS ICYROADS ===============> ${prefs.getBool("icyRoads")}");
    print(
        "SHAREDPREFS ROADSIGNS ==============> ${prefs.getBool("roadSigns")}");
  }

  void updateSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, bool> sharedPrefs = {
      "Cykelpumpar": prefs.getBool("pumps"),
      "Vägproblem": prefs.getBool("roadProblems"),
      "Avstängd väg": prefs.getBool("closedRoads"),
      "Hinder": prefs.getBool("obstacles"),
      "Hög trafik": prefs.getBool("heavyTraffic"),
      "Övrigt": prefs.getBool("others"),
      "Vägarbete": prefs.getBool("roadWorks"),
      "Halka": prefs.getBool("icyRoads"),
      "Felaktig skyltning": prefs.getBool("roadSigns"),
    };

    setState(() {
      _switchedList.keys.forEach((k) =>
          _switchedList[k] = sharedPrefs[k] == null ? false : sharedPrefs[k]);
    });
    updateCustomPins();
  }

  ///SHAREDPREFERENCES

  Set<Marker> getAllPins() {
    Set<Marker> allPins = {};
    customPinMap.forEach((c, v) => {
          if (c != "Cykelpumpar") allPins.addAll(v),
        });
    return allPins;
  }

  void checkDatabaseIntegrity(ErrorReport errRep) async {
    DateTime now = DateTime.now();
    FirebaseUser user = await widget.auth.getUser();
    DatabaseService dbService = DatabaseService(uid: user.uid);
    try {
      if (errRep.getDateTimeCreated() != null) {
        print("ERROR REPORTS CREATED ${errRep.getDateTimeCreated()}");
        print("ERROR REPORTS END DATE ${errRep.getDateTimeEnd()}");
        if (now.isAfter(errRep.getDateTimeEnd())) {
          dbService.deleteRecord(errRep);
          print("ERROR REPORT REMOVED ${errRep.markerId}");
        }
      }
    } catch (e) {
      if (e is NoSuchMethodError) {
        print("Inget datum (tillsvidare inlagt, kan ej kontrollera)");
      }
    }
  }
}

class Destination {
  String place;
  LatLng position;

  Destination(this.place, this.position);
}
