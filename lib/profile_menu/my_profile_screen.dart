import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'edit_account_screen.dart';

enum Address {
  home,
  work,
}

class MyProfileScreen extends StatefulWidget {
  MyProfileScreen(
      {this.username,
      this.email,
      this.auth,
      this.onSignedOut,
      this.updateLocalVar});

  final String username;
  final String email;
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final Function updateLocalVar;

  void _signOut() async {
    try {
      await auth.signOut();
      onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String _homeAddress = "Ingen adress ifylld";
  String _workAddress = "Ingen adress ifylld";

  final _controller = new TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        updateHomeAddress();
        updateWorkAddress();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: CustomAppBar(text: "Min profil"),
        backgroundColor: Colors.grey[800],
        body: Stack(
          children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(
                  ScreenUtil.instance.setWidth(30),
                  ScreenUtil.instance.setHeight(20),
                  ScreenUtil.instance.setWidth(30),
                  ScreenUtil.instance.setHeight(30)),
              child: Column(
                children: <Widget>[
                  Container(
                    child: _buildDataPart(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            _buildAddressRow(
                              Icons.home,
                              "Hem",
                              "$_homeAddress",
                              () => changeAddress("Välj  hemadress",
                                  "Fyll i din hemadress", Address.home),
                            ),
                            SizedBox(height: ScreenUtil.instance.setHeight(10)),
                            _buildAddressRow(
                              Icons.work,
                              "Jobb",
                              "$_workAddress",
                              () => changeAddress("Välj jobbadress",
                                  "Fyll i din jobbadress", Address.work),
                            ),
                          ],
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: ScreenUtil.instance.setHeight(120),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                              widget._signOut();
                            },
                            child: Text(
                              "Logga ut",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: ScreenUtil.instance.setHeight(20),
                              ),
                            ),
                          ),
                        ),
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

  void changeAddress(String title, String hintText, Address address) async {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text(title,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(22),
          ),
          textAlign: TextAlign.center),
      content: Container(
        height: ScreenUtil.instance.setHeight(140),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(height: ScreenUtil.instance.setHeight(5)),
            Theme(
              data: ThemeData(brightness: Brightness.dark),
              child: TextField(
                controller: _controller,
                cursorColor: Colors.white,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  onPressed: () {
                    address == Address.home
                        ? saveHomeAddress()
                        : saveWorkAddress();
                    Navigator.of(context).pop();
                    _controller.clear();
                  },
                  child: Text(
                    "Spara",
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: ScreenUtil.instance.setHeight(22),
                    ),
                  ),
                ),
                Container(
                  height: ScreenUtil.instance.setHeight(40),
                  child: VerticalDivider(color: Colors.white),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _controller.clear();
                  },
                  child: Text(
                    "Avbryt",
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: ScreenUtil.instance.setHeight(22),
                    ),
                  ),
                )
              ],
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

  Widget _setProfilePicture() {
    return Icon(
      Icons.person,
      color: Colors.grey[800],
      size: ScreenUtil.instance.setHeight(60),
    );
  }

  Widget _buildDataPart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          backgroundColor: Colors.grey,
          radius: ScreenUtil.instance.setHeight(40),
          child: _setProfilePicture(),
        ),
        SizedBox(height: ScreenUtil.instance.setHeight(10)),
        Text(
          "${widget.username}"[0].toUpperCase() +
              "${widget.username}".substring(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(16),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "${widget.email}",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil.instance.setHeight(16),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EditAccountScreen(
                        auth: widget.auth, onSignedOut: widget.onSignedOut)),
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: ScreenUtil.instance.setHeight(30),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.white,
          height: ScreenUtil.instance.setHeight(40),
        )
      ],
    );
  }

  Widget _buildAddressRow(
      IconData icon, String leftText, String rightText, Function function) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: function,
          child: Container(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.edit,
              color: Colors.white,
              size: ScreenUtil.instance.setHeight(30),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Icon(
                  icon,
                  color: Colors.white,
                  size: ScreenUtil.instance.setHeight(26),
                ),
                SizedBox(width: ScreenUtil.instance.setHeight(15)),
                Text(
                  leftText,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: ScreenUtil.instance.setSp(16)),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(right: ScreenUtil.instance.setHeight(40)),
              child: Text(
                rightText,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: ScreenUtil.instance.setSp(16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ///Sparar hemadressen man fyllt i, i databasen
  void saveHomeAddress() async {
    setState(() {
      _homeAddress = _controller.text;
    });
    FirebaseUser user = await widget.auth.getUser();
    DatabaseService(uid: user.uid).updateHomeAddress(homeAddress: _homeAddress);
  }

  ///Sparar jobbadressen man fyllt i, i databasen
  void saveWorkAddress() async {
    setState(() {
      _workAddress = _controller.text;
    });
    FirebaseUser user = await widget.auth.getUser();
    DatabaseService(uid: user.uid).updateWorkAddress(workAddress: _workAddress);
  }

  ///OBS SPAGHETTI NEDAN
  ///
  ///Hämtar in användarens hemadress så det visas i Widget
  Future updateHomeAddress() async {
    FirebaseUser user = await widget.auth.getUser();
    if (!user.isAnonymous) {
      String address =
          await DatabaseService(uid: user.uid).getUsersHomeAddress();
      if (address != null) {
        setState(() {
          _homeAddress = address;
        });
      } else {
        return;
      }
    } else {
      return;
    }
  }

  ///Hämtar in användarens arbetsadress så det visas i Widget
  Future updateWorkAddress() async {
    FirebaseUser user = await widget.auth.getUser();
    if (!user.isAnonymous) {
      String address =
          await DatabaseService(uid: user.uid).getUsersWorkAddress();
      if (address != null) {
        setState(() {
          _workAddress = address;
        });
      } else {
        return;
      }
    } else {
      return;
    }
  }
}
