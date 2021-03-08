import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/constants.dart';
import 'package:bikeinsthlm/validation_classes/validation_email.dart';
import 'package:bikeinsthlm/validation_classes/validation_password.dart';
import 'package:bikeinsthlm/validation_classes/validation_phone_number.dart';
import "package:bikeinsthlm/validation_classes/validation_username.dart";
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_field_validator/form_field_validator.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({this.auth, this.onSignedIn});
  final BaseAuth auth;
  final VoidCallback onSignedIn;

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = new GlobalKey<FormState>();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  var _banner = Container(
    height: ScreenUtil.instance.setHeight(40),
    color: Colors.transparent,
  );

  String _email;
  String _password;
  String _username;
  String _phoneNr;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[800],
      ),
    );

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(text: "Skapa konto"),
        backgroundColor: Colors.grey[800],
        body: Builder(builder: (context) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Container(
                height: ScreenUtil.instance.setHeight(690),
                alignment: Alignment.center,
                child: Form(
                  key: formKey,
                  child: Column(
                    children: <Widget>[
                      _banner,
                      Container(
                        height: ScreenUtil.instance.setHeight(600),
                        width: ScreenUtil.instance.setWidth(300),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _buildNameField(),
                            _buildPhoneNoField(),
                            _buildEmailField(),
                            _buildPasswordField(),
                            _buildConfirmPasswordField(),
                            _buildRegisterButton(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        bottomNavigationBar: BottomAppBar(
          color: Colors.grey[800],
          child: _buildSignInButton(
            () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  _makeBannerInvisible() {
    setState(() {
      _banner = Container(
        color: Colors.transparent,
      );
    });
  }

  _makeBannerVisible() {
    setState(() {
      _banner = Container(
        color: Colors.yellow,
        height: ScreenUtil.instance.setHeight(50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Icon(Icons.info_outline,
                color: Colors.grey[800],
                size: ScreenUtil.instance.setHeight(30)),
            Text(
              "Det finns redan ett konto med denna e-post",
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: ScreenUtil.instance.setHeight(16),
              ),
            ),
            GestureDetector(
              child: Icon(Icons.close,
                  color: Colors.grey[800],
                  size: ScreenUtil.instance.setHeight(30)),
              onTap: () => _makeBannerInvisible(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNameField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        focusNode: _nameFocus,
        onFieldSubmitted: (term) {
          _handleFocus(context, _nameFocus, _phoneFocus);
        },
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        cursorColor: Colors.grey[800],
        decoration:
            buildTextFieldDecoration(text: "Namn", prefixIcon: Icons.person),
        validator: (username) =>
            new ValidateUsername().validateUserName(username),
        onSaved: (username) => _username = username.toUpperCase(),
      ),
    );
  }

  Widget _buildPhoneNoField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        focusNode: _phoneFocus,
        onFieldSubmitted: (term) {
          _handleFocus(context, _phoneFocus, _emailFocus);
        },
        keyboardType: TextInputType.number,
        cursorColor: Colors.grey[800],
        decoration: buildTextFieldDecoration(
            text: "Telefonnummer", prefixIcon: Icons.phone_android),
        validator: (phoneNr) => new ValidatePhoneNr().validatePhoneNr(phoneNr),
        onSaved: (phoneNr) => _phoneNr = phoneNr,
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        focusNode: _emailFocus,
        onFieldSubmitted: (term) {
          _handleFocus(context, _emailFocus, _passwordFocus);
        },
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.grey[800],
        decoration:
            buildTextFieldDecoration(text: "E-post", prefixIcon: Icons.email),
        validator: (email) => new ValidateEmail().validateEmail(email),
        onSaved: (email) => _email = email,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        focusNode: _passwordFocus,
        onFieldSubmitted: (term) {
          _handleFocus(context, _passwordFocus, _confirmPasswordFocus);
        },
        cursorColor: Colors.grey[800],
        obscureText: true,
        decoration:
            buildTextFieldDecoration(text: "Lösenord", prefixIcon: Icons.lock),
        validator: (password) {
          var validating = new ValidatePassword().validatePassword(password);
          _password = password;
          return validating;
        },
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: TextFormField(
        focusNode: _confirmPasswordFocus,
        cursorColor: Colors.grey[800],
        obscureText: true,
        decoration: buildTextFieldDecoration(
            text: "Bekräfta lösenord", prefixIcon: Icons.lock),
        validator: (confirm) =>
            MatchValidator(errorText: "Lösenorden matchar inte")
                .validateMatch(confirm, _password),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      width: double.infinity,
      child: RaisedButton(
        onPressed: () => validateAndSubmit(context),
        padding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.grey[350],
        child: Text(
          "REGISTRERA",
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: ScreenUtil.instance.setHeight(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(Function function) {
    return Container(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Har du redan ett konto?",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(14),
            ),
          ),
          GestureDetector(
            onTap: function,
            child: Text(
              " Logga in",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil.instance.setHeight(14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _handleFocus(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      print("Form is valid. User registered with email: $_email");
      return true;
    } else {
      print("Form is invalid");
      return false;
    }
  }

  void validateAndSubmit(BuildContext context) async {
    if (validateAndSave()) {
      try {
        String userId = await widget.auth.createUserWithEmailAndPassword(
            _email, _password, _username, _phoneNr);
        print("Registered user: $userId");
        Navigator.of(context).pop();
        widget.onSignedIn();
      } catch (signUpError) {
        if (signUpError is PlatformException) {
          if (signUpError.code == "ERROR_EMAIL_ALREADY_IN_USE") {
            _makeBannerVisible();
          }
        } else {
          print("ERROR CODE: -----------> $signUpError");
        }
      }
    }
  }
}
