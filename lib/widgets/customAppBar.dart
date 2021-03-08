import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String text;

  CustomAppBar({this.text});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        backgroundColor: Colors.grey[800].withOpacity(0.9),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.keyboard_arrow_left,
            color: Colors.green[400],
            size: ScreenUtil.instance.setHeight(40),
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            color: Colors.green[400],
            fontSize: ScreenUtil.instance.setHeight(25),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(ScreenUtil.instance.setHeight(65));
}
