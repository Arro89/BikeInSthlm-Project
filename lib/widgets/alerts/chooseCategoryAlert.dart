import 'package:bikeinsthlm/map_screen.dart';
import 'package:bikeinsthlm/widgets/alerts/errorReportAlert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChooseCategoryAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double defaultScreenWidth = 400.0;
    double defaultScreenHeight = 810.0;
    ScreenUtil.instance = ScreenUtil(
      width: defaultScreenWidth,
      height: defaultScreenHeight,
      allowFontScaling: true,
    )..init(context);

    return AlertDialog(
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
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.roadProblem,
                          );
                        },
                      );
                    }, AssetImage("assets/images/roadDamage.png"),
                        "Vägproblem"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.closedRoad,
                          );
                        },
                      );
                    },
                        AssetImage(
                          "assets/images/closedRoad.png",
                        ),
                        "Avstängd väg"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.pin,
                            category: PinCategory.obstacle,
                          );
                        },
                      );
                    }, AssetImage("assets/images/obstacle.png"), "Hinder"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.heavyTraffic,
                          );
                        },
                      );
                    }, AssetImage("assets/images/heavyTraffic.png"),
                        "Hög trafik"),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(height: ScreenUtil.instance.setHeight(20)),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.other,
                          );
                        },
                      );
                    }, AssetImage("assets/images/otherDanger.png"), "Övrigt"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.roadWork,
                          );
                        },
                      );
                    },
                        AssetImage(
                          "assets/images/roadWork.png",
                        ),
                        "Vägarbete"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.polyline,
                            category: PinCategory.icyRoad,
                          );
                        },
                      );
                    }, AssetImage("assets/images/icyRoad.png"), "Halka"),
                    _buildObjects(() {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return ErrorReportAlert(
                            type: PinType.pin,
                            category: PinCategory.roadSign,
                          );
                        },
                      );
                    }, AssetImage("assets/images/roadSign.png"),
                        "Felaktig skyltning"),
                  ],
                ),
              ],
            ),
            Container(
              alignment: Alignment.center,
              child: _buildBackButton(context),
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

  Widget _buildBackButton(BuildContext context) {
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
}
