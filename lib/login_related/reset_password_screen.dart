import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/constants.dart';
import 'package:bikeinsthlm/validation_classes/validation_email.dart';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResetPasswordScreen extends StatefulWidget {
  ResetPasswordScreen({this.auth});

  final BaseAuth auth;

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = new GlobalKey<FormState>();
  String _email;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );

    double defaultScreenWidth = 400.0;
    double defaultScreenHeight = 810.0;
    ScreenUtil.instance = ScreenUtil(
      width: defaultScreenWidth,
      height: defaultScreenHeight,
      allowFontScaling: true,
    )..init(context);

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(text: "Återställ lösenordet"),
        backgroundColor: Colors.grey[800],
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.grey[800],
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Container(
                height: ScreenUtil.instance.setHeight(700),
                alignment: Alignment.center,
                child: Form(
                  key: formKey,
                  child: Container(
                    height: ScreenUtil.instance.setWidth(350),
                    width: ScreenUtil.instance.setWidth(300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        _buildEmailField(),
                        _buildResetButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.grey[800],
        decoration: buildTextFieldDecoration(text: "E-post", prefixIcon: Icons.email),
        validator: (email) => new ValidateEmail().validateEmail(email),
        onSaved: (email) => _email = email,
      ),
    );
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  Widget _buildResetButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      width: double.infinity,
      child: RaisedButton(
        onPressed: () {
          if (validateAndSave()) {
            widget.auth.resetPassword(_email);
          } else {
            print("Error");
          }
        },
        elevation: 5.0,

        ///hantering av validateAndSubmit()
        padding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.grey[350],
        child: Text(
          "Återställ lösenordet",
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: ScreenUtil.instance.setHeight(16),
          ),
        ),
      ),
    );
  }
}
