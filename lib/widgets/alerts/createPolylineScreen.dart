import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class CreatePolyLineScreen extends StatefulWidget {
  @override
  _CreatePolyLineScreenState createState() => _CreatePolyLineScreenState();
}

class _CreatePolyLineScreenState extends State<CreatePolyLineScreen> {
  File _image;

  Future getPhoto() async {
    var photo = await ImagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = photo;
    });
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
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

    return Column(
      children: <Widget>[],
    );
  }
}
