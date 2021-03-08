import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyNotificationsAlert extends StatelessWidget {
  final String title = "Notiser";
  final List<String> notifications = [
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
    "Hej",
  ];

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
      backgroundColor: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      title: Text("Notiser",
          style: TextStyle(
            color: Colors.green[400],
            fontSize: ScreenUtil.instance.setHeight(26),
          ),
          textAlign: TextAlign.center),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            Container(
              height: ScreenUtil.instance.setHeight(450),
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  return Column(
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        height: ScreenUtil.instance.setHeight(55),
                        child: Text(
                          notifications[index],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: ScreenUtil.instance.setHeight(16)),
                        ),
                      ),
                      Divider(color: Colors.white)
                    ],
                  );
                },
                itemCount: notifications.length,
              ),
            ),
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Stäng",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
