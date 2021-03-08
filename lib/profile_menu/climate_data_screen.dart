import 'package:bikeinsthlm/widgets/customAppBar.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyClimateDataScreen extends StatefulWidget {

  @override
  _MyClimateDataScreenState createState() => _MyClimateDataScreenState();
}

class _MyClimateDataScreenState extends State<MyClimateDataScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(text: "Min klimatdata"),
        //backgroundColor: Colors.grey[800],
        body: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(
              ScreenUtil.instance.setWidth(0),
              ScreenUtil.instance.setHeight(0),
              ScreenUtil.instance.setWidth(0),
              ScreenUtil.instance.setHeight(0)),
        ),
      ),
    );
  }
}
