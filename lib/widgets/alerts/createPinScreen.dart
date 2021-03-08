import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class CreatePinScreen extends StatefulWidget {
  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
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
      children: <Widget>[
        Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              height: ScreenUtil.instance.setHeight(200),
              width: ScreenUtil.instance.setHeight(400),
              child: _image == null
                  ? Text(
                      "Lägg gärna till en bild",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ScreenUtil.instance.setHeight(18),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.topRight,
                      children: <Widget>[
                        Image.file(_image),
                        GestureDetector(
                          onTap: () => setState(
                            () {
                              _image = null;
                            },
                          ),
                          child: Icon(Icons.close,
                              color: Colors.white,
                              size: ScreenUtil.instance.setHeight(30)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        SizedBox(height: ScreenUtil.instance.setHeight(20)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: getPhoto,
              child: Icon(Icons.add_a_photo, color: Colors.white),
            ),
            SizedBox(width: ScreenUtil.instance.setHeight(20)),
            GestureDetector(
              onTap: getImage,
              child: Icon(Icons.photo_album, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
