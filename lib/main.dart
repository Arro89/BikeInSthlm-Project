import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/root_page.dart';
import 'package:bikeinsthlm/route_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import "authentication_login/authentication.dart";
import "root_page.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      animationCurve: Curves.easeIn,
      animationBuilder: Miui10AnimBuilder(),
      animationDuration: Duration(milliseconds: 200),
      duration: Duration(seconds: 3),
      child: MaterialApp(
        color: Colors.grey[800],
        theme: ThemeData(canvasColor: Colors.grey[800]),
        debugShowCheckedModeBanner: false,
        initialRoute: "/",
        routes: {"/routePlannerScreen": (context) => RoutePlannerScreen()},
        title: 'Cykla i Stockholm',
        home: new RootPage(auth: new Auth()),
      ),
    );
  }
}
