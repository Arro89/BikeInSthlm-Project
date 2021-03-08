import 'dart:async';
import 'package:bikeinsthlm/artefacts/error_report.dart';
import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

class CustomPinSheet extends StatefulWidget {
  final ErrorReport customPin;
  final BaseAuth auth;
  CustomPinSheet(this.customPin, this.auth);
  @override
  _CustomPinSheetState createState() => _CustomPinSheetState();
}
class _CustomPinSheetState extends State<CustomPinSheet> {
  bool followPin = false;
  int likes;
  int dislikes;
  ErrorReport currentErrorReport;

  Query query;
  StreamSubscription<Event> likeOrDislikeUpdated;

  @override
  void initState() {
    likes = widget.customPin.likes;
    dislikes = widget.customPin.dislikes;
    currentErrorReport = widget.customPin;
    query = FirebaseDatabase.instance.reference().child("customMarkers");
    likeOrDislikeUpdated = query.onChildChanged.listen(onEntryUpdated);
    super.initState();
  }

  @override
  void dispose() {
    likeOrDislikeUpdated.cancel();
    super.dispose();
  }

  void onEntryUpdated(Event event){
    print("ON ENTRY UPDATED CALLED");
    ErrorReport errorReport = ErrorReport.fromSnapshot(event.snapshot);
    setState(() {
      currentErrorReport = errorReport;
      likes = errorReport.likes;
      dislikes = errorReport.dislikes;
    });
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800].withOpacity(0.9),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Wrap(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: ScreenUtil.instance.setWidth(170),
                  //color: Colors.red,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${widget.customPin.title}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil.instance.setHeight(20),
                        ),
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan(
                        "Plats: ",
                        widget.customPin.address == null
                            ? "Inte tillgängligt"
                            : "\n${widget.customPin.address}",
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan(
                        "Kategori: ",
                        "${widget.customPin.type}",
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan("Skapad: ",
                          "${widget.customPin.timeCreated}\nav ${widget.customPin.creator}"),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan(
                          "Slutdatum: ", "${currentErrorReport.endDate}"),
                    ],
                  ),
                ),
                Container(
                  width: ScreenUtil.instance.setWidth(180),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Text(
                            "Stämmer detta?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ScreenUtil.instance.setHeight(18),
                            ),
                          ),
                          SizedBox(height: ScreenUtil.instance.setHeight(10)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  _buildAgreeOrDisagreeButton(
                                      "Ja", Icons.thumb_up, true),
                                  _buildTextSpan(
                                      "Antal: ", "$likes"),
                                ],
                              ),
                              SizedBox(
                                  width: ScreenUtil.instance.setHeight(10)),
                              Column(
                                children: <Widget>[
                                  _buildAgreeOrDisagreeButton(
                                      "Nej", Icons.thumb_down, false),
                                  _buildTextSpan("Antal: ",
                                      "$dislikes"),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Följ denna pin?",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ScreenUtil.instance.setHeight(15)),
                              ),
                              Theme(
                                data: ThemeData(
                                    unselectedWidgetColor: Colors.white),
                                child: Checkbox(
                                  activeColor: Colors.green,
                                  value: followPin,
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        followPin = value;
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _buildTextSpan(String leftText, String rightText) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: leftText,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(12),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: rightText,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(12),
            ),
          ),
        ],
      ),
    );
  }
  _buildAgreeOrDisagreeButton(String text, IconData icon, bool agree) {
    return Container(
      width: ScreenUtil.instance.setWidth(80),
      child: RaisedButton(
        color: Colors.grey,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () {
          showToast(
            "Tack för din feedback",
            textStyle: TextStyle(
                color: Colors.white, fontSize: ScreenUtil.instance.setSp(14)),
            position: ToastPosition.center,
            backgroundColor: Colors.grey[800],
            textPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(20)),
          );
          setState(
            () {
              addLikeOrDislike(agree);
            },
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: ScreenUtil.instance.setHeight(18),
              color: Colors.white,
            ),
            Text(
              text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil.instance.setHeight(14)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void addLikeOrDislike(bool agree) async {
    FirebaseUser user = await widget.auth.getUser();
    agree ? currentErrorReport.updateLike(user.uid) : currentErrorReport.updateDislike(user.uid);
    if (user != null) {
      DatabaseService dbService = DatabaseService(uid: user.uid);
      //DatabaseService(uid: user.uid).updateRecord(widget.customPin);
      dbService.updateRecord(currentErrorReport);
      getCurrentLikeAndDislike(agree, user, dbService);
      print("AMOUNT OF LIKES ==> ${widget.customPin.likes}");
      print("AMOUNT OF DISLIKES ==> ${widget.customPin.dislikes}");
    }
  }
  void getCurrentLikeAndDislike(
      bool agree, FirebaseUser user, DatabaseService db) async {
    int dbLikes;
    int dbDislikes;
    agree ? dbLikes = await db.getLike(currentErrorReport) : dbDislikes = await db.getDislike(currentErrorReport);
    setState(() {
      agree ? likes = dbLikes : dislikes = dbDislikes;
    });
  }
}