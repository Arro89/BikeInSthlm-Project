import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/profile_menu/climate_data_screen.dart';
import 'package:bikeinsthlm/profile_menu/my_pins_screen.dart';
import 'package:bikeinsthlm/profile_menu/my_profile_screen.dart';
import 'package:bikeinsthlm/profile_menu/saved_routes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileDrawer extends StatelessWidget {
  ProfileDrawer({
    this.auth,
    this.onSignedOut,
    this.currentUsername,
    this.currentEmail,
    this.markers,
  });
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String currentUsername;
  final String currentEmail;
  Set<Marker> markers;

  void _signOut() async {
    try {
      await auth.signOut();
      onSignedOut();
    } catch (e) {
      print(e);
    }
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

    return Theme(
      data: ThemeData(
        canvasColor: Colors.grey[800],
      ),
      child: Drawer(
        child: Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin:
                    EdgeInsets.only(right: ScreenUtil.instance.setHeight(10)),
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.green[400],
                  size: ScreenUtil.instance.setHeight(40),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: ScreenUtil.instance.setHeight(20)),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding:
                        EdgeInsets.only(left: ScreenUtil.instance.setWidth(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: ScreenUtil.instance.setHeight(40),
                          child: _setProfilePicture(),
                        ),
                        SizedBox(height: ScreenUtil.instance.setHeight(10)),
                        Text(
                          "$currentUsername",
                          style: TextStyle(
                              fontSize: ScreenUtil.instance.setSp(18),
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ScreenUtil.instance.setHeight(20)),
                  Container(
                    child: Column(
                      children: <Widget>[
                        Visibility(
                          visible: currentUsername != "Gäst",
                          child: Column(
                            children: <Widget>[
                              _createListTile(
                                Icons.person,
                                "Min profil",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyProfileScreen(
                                          auth: auth,
                                          onSignedOut: onSignedOut,
                                          username: currentUsername,
                                          email: currentEmail)),
                                ),
                              ),
                              _createListTile(
                                Icons.local_library,
                                "Mina sparade rutter",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SavedRoutesScreen(auth: auth, markers: markers)),
                                ),
                              ),
                              _createListTile(
                                Icons.place,
                                "Mina pins",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyPinsScreen()),
                                ),
                              ),
                              _createListTile(
                                Icons.public,
                                "Min klimatdata",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MyClimateDataScreen()),
                                ),
                              ),
                              Divider(
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        _createListTile(Icons.exit_to_app, "Logga ut", () {
                          Navigator.of(context).pop();
                          _signOut();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setProfilePicture() {
    return Icon(
      Icons.person,
      color: Colors.grey[800],
      size: ScreenUtil.instance.setHeight(60),
    );
  }

  Widget _createListTile(IconData icon, String text, Function function) {
    return ListTile(
      onTap: function,
      leading: Icon(
        icon,
        color: icon == Icons.exit_to_app ? Colors.red : Colors.white,
        size: ScreenUtil.instance.setHeight(28),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: text == "Logga ut" ? Colors.red : Colors.white,
          fontSize: ScreenUtil.instance.setSp(16),
        ),
      ),
    );
  }
}
