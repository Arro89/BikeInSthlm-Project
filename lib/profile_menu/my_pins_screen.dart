import 'package:bikeinsthlm/constants.dart';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyPinsScreen extends StatefulWidget {
  @override
  _MyPinsScreenState createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(text: "Mina pins"),
        backgroundColor: Colors.grey[800],
        body: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(
              ScreenUtil.instance.setWidth(0),
              ScreenUtil.instance.setHeight(0),
              ScreenUtil.instance.setWidth(0),
              ScreenUtil.instance.setHeight(0)),
          child: ListView(
            children: <Widget>[],
          ),
        ),
      ),
    );
  }
}
