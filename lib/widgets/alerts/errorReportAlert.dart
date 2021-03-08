import 'dart:io';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bikeinsthlm/map_screen.dart';


///Lämna så länge, Arvin ska använda denna sen
Future savePrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
}

class ErrorReportAlert extends StatefulWidget {
  final PinType type;
  final PinCategory category;

  ErrorReportAlert({this.type, this.category});

  @override
  _ErrorReportAlertState createState() => _ErrorReportAlertState();
}

class _ErrorReportAlertState extends State<ErrorReportAlert> {
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

    return AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text(_handleCategory(widget.category),
          style: TextStyle(
            color: Colors.green[400],
            fontSize: ScreenUtil.instance.setHeight(26),
          ),
          textAlign: TextAlign.center),
      content: Container(
        child: Wrap(
          children: <Widget>[
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  widget.type == PinType.pin
                      ? _buildPinScreen()
                      : _buildPolylineScreen(),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: ScreenUtil.instance.setHeight(10)),
                        _buildTitleField(),
                        SizedBox(height: ScreenUtil.instance.setHeight(10)),
                        _buildCreateButton(),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: ScreenUtil.instance.setHeight(80)),
                          child: Divider(
                            color: Colors.white,
                          ),
                        ),
                        _buildBackButton(),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildCreateButton() {
    return FlatButton(
      onPressed: () {},
      child: Text(
        "Skapa",
        style: TextStyle(
          color: Colors.green[400],
          fontSize: ScreenUtil.instance.setHeight(24),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
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

  _handleCategory(PinCategory category) {
    switch (category) {
      case PinCategory.roadProblem:
        return "Vägproblem";
        break;
      case PinCategory.closedRoad:
        return "Avstängd väg";
        break;
      case PinCategory.obstacle:
        return "Hinder";
        break;
      case PinCategory.heavyTraffic:
        return "Hög trafik";
        break;
      case PinCategory.other:
        return "Övrigt";
        break;
      case PinCategory.roadWork:
        return "Vägarbete";
        break;
      case PinCategory.icyRoad:
        return "Halka";
        break;
      case PinCategory.roadSign:
        return "Felaktig skyltning";
        break;
    }
  }

  Widget _buildTitleField() {
    return Container(
      height: ScreenUtil.instance.setHeight(50),
      child: TextFormField(
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        //onSaved: (title) => _title = title,
        cursorColor: Colors.grey[800],
        decoration: _buildTextFieldDecoration(
            "Rubrik", Colors.grey[350], Colors.grey[800]), //Ligger i constants
      ),
    );
  }

  _buildTextFieldDecoration(String text, Color fillColor, Color textColor) {
    return InputDecoration(
      fillColor: fillColor,
      filled: true,
      hintText: text,
      hintStyle: TextStyle(
          fontSize: ScreenUtil.instance.setHeight(16), color: textColor),
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

  _buildPinScreen() {
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

  _buildPolylineScreen() {
    return Column(
      children: <Widget>[],
    );
  }
}
