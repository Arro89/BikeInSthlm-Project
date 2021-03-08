import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/http_fetch_service.dart';
import 'package:bikeinsthlm/map_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import "http_fetch_service.dart";
import "authentication_login/authentication.dart";

const apiKey = "AIzaSyB1SCDPQTve0fb08847Wzgl-BoaYY8Qwuo";
var tappedPump;

class Home extends StatefulWidget {
  Home({this.auth, this.onSignedOut});
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final bool showNavBar = false;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Service service = new Service();

  String currentUsername;
  String currentEmail;
  bool placingMarker;
  String tempType;
  String tempTitle;
  String tempDescription;

  @override
  void initState() {
    super.initState();
    updateCurrentUsername();
    updateCurrentEmail();

    _selectedScreen = 0;
    _screens = [
      MainPage(
          auth: widget.auth,
          onSignedOut: widget.onSignedOut,
          placingMarker: placingMarker,
          tempType: tempType,
          tempTitle: tempTitle,
          tempDescription: tempDescription,
          showNavBar: true),
    ];
  }

  int pinCounter = 0;

  int _selectedScreen;
  List<StatefulWidget> _screens;

  void updateCurrentUsername() async {
    await widget.auth.getUser().then((user) {
      if (user != null) {
        DatabaseService(uid: user.uid).getUserData("name").then((name) {
          setState(() {
            currentUsername = name;
          });
        });
      } else {
        currentUsername = "Gäst";
      }
    });
  }

  void updateCurrentEmail() async {
    await widget.auth.getUser().then((user) {
      if (user != null) {
        DatabaseService(uid: user.uid).getUserData("email").then((email) {
          setState(() {
            currentEmail = email;
          });
        });
      } else {
        setState(() {
          currentEmail = "Gäst-konto";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _screens[_selectedScreen],
    );
  }
}
