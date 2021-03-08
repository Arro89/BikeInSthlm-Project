import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

buildTextFieldDecoration({String text, IconData prefixIcon}) {
  return InputDecoration(
    fillColor: Colors.grey[350],
    filled: true,
    contentPadding: EdgeInsets.symmetric(
        vertical: 0, horizontal: ScreenUtil.instance.setWidth(10)),
    hintText: text,
    hintStyle: TextStyle(fontSize: ScreenUtil.instance.setHeight(16)),
    errorStyle: TextStyle(fontSize: ScreenUtil.instance.setHeight(12)),
    prefixIcon: Icon(
      prefixIcon,
      color: Colors.grey[800],
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: Colors.green[400], width: ScreenUtil.instance.setWidth(2)),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
