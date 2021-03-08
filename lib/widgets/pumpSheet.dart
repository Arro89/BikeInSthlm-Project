import 'package:bikeinsthlm/constants.dart';
import 'package:bikeinsthlm/coordinate_conversion/SWEREF99Position.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:bikeinsthlm/map_screen.dart";

import '../route_planner_screen.dart';

class PumpSheet extends StatefulWidget {
  PumpSheet(this.auth, this.customPins, this.pump);
  final auth;
  final customPins;
  final pump;

  @override
  _PumpSheetState createState() => _PumpSheetState();
}

class _PumpSheetState extends State<PumpSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800].withOpacity(0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Wrap(
        children: <Widget>[
          Container(
            margin: EdgeInsets.fromLTRB(
                ScreenUtil.instance.setHeight(20),
                ScreenUtil.instance.setHeight(5),
                ScreenUtil.instance.setHeight(20),
                ScreenUtil.instance.setHeight(20)),
            child: Stack(
              children: <Widget>[
                Container(
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.maximize,
                      color: Colors.white,
                      size: ScreenUtil.instance.setHeight(30)),
                ),
                Container(
                  margin:
                      EdgeInsets.only(top: ScreenUtil.instance.setHeight(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Cykelpump",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil.instance.setHeight(24),
                        ),
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(25)),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Status: ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ScreenUtil.instance.setHeight(14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: "${widget.pump.properties.status}",
                              style: TextStyle(
                                color: (widget.pump.properties.working)
                                    ? Colors.greenAccent
                                    : Colors.red,
                                fontSize: ScreenUtil.instance.setHeight(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan(
                          "Adress: ", "${widget.pump.properties.adress}"),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan("Senast uppdaterad: ",
                          "${widget.pump.properties.uppdaterad}"),
                      SizedBox(height: ScreenUtil.instance.setHeight(20)),
                      _buildButton(
                          "Vägbeskrivning",
                          Colors.green[400],
                          Colors.white,
                          onNavigatePressed,
                          Icons.directions),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  onNavigatePressed(){
    Destination destination = Destination(widget.pump.properties.adress, SWEREF99Position(widget.pump.geometry.coordinates[1],
        widget.pump.geometry.coordinates[0])
        .toWGS84()
        .toLatLng(),);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext) {
      return RoutePlannerScreen(auth: widget.auth, customPins: widget.customPins, destination: destination);}),
    );}


  Widget _buildTextSpan(String leftText, String rightText) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: leftText,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(14),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: rightText,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      String text, Color color, Color textColor, Function function,
      [IconData icon]) {
    return Container(
      width: ScreenUtil.instance.setHeight(200),
      child: RaisedButton(
        onPressed: function,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: textColor),
            Text(
              text,
              style: TextStyle(
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
