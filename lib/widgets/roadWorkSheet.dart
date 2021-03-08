import 'package:bikeinsthlm/constants.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoadWorkSheet extends StatefulWidget {
  RoadWorkSheet(this.sit);

  final sit;

  @override
  _RoadWorkSheetState createState() => _RoadWorkSheetState();
}

class _RoadWorkSheetState extends State<RoadWorkSheet> {
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
                        "Vägarbete",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil.instance.setHeight(24),
                        ),
                      ),
                      SizedBox(height: ScreenUtil.instance.setHeight(25)),
                      _buildTextSpan("Starttid: ", "${widget.sit.startTime}"),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan("Sluttid: ", "${widget.sit.endTime}"),
                      SizedBox(height: ScreenUtil.instance.setHeight(5)),
                      _buildTextSpan("Meddelande: ", "${widget.sit.actualMessage}"),
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
}
