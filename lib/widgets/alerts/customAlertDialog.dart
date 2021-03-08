import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;

  CustomAlertDialog({this.title, this.content});

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
      title: Text(title,
          style: TextStyle(
            color: Colors.red,
            fontSize: ScreenUtil.instance.setHeight(26),
          ),
          textAlign: TextAlign.center),
      content: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(16),
            ),
            textAlign: TextAlign.center,
          ),
          FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: TextStyle(
                color: Colors.green[400],
                fontSize: ScreenUtil.instance.setHeight(22),
              ),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
    );
  }
}
