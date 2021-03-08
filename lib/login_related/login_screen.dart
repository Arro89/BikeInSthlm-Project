import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/constants.dart';
import 'package:bikeinsthlm/validation_classes/validation_email.dart';
import 'package:bikeinsthlm/validation_classes/validation_password.dart';
import 'package:bikeinsthlm/widgets/alerts/customAlertDialog.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

import "./register_screen.dart";
import "./reset_password_screen.dart";

class LoginScreen extends StatefulWidget {
  LoginScreen({this.auth, this.onSignedIn});

  final BaseAuth auth;
  final VoidCallback onSignedIn;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = new GlobalKey<FormState>();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool showPassword = false;

  String _email;
  String _password;

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

    double defaultScreenWidth = 400.0;
    double defaultScreenHeight = 810.0;
    ScreenUtil.instance = ScreenUtil(
      width: defaultScreenWidth,
      height: defaultScreenHeight,
      allowFontScaling: true,
    )..init(context);

    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: ScreenUtil.instance.setHeight(50)),
              alignment: Alignment.center,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/logotype.png"),
                        ),
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: SizedBox(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                _buildEmailField(),
                                SizedBox(
                                    height: ScreenUtil.instance.setHeight(10)),
                                _buildPasswordField(),
                                SizedBox(
                                    height: ScreenUtil.instance.setHeight(5)),
                                _buildForgotPasswordButton(),
                                SizedBox(
                                    height: ScreenUtil.instance.setHeight(20)),
                                _buildLoginButton(context),
                                SizedBox(
                                    height: ScreenUtil.instance.setHeight(10)),
                                _buildSignInWithSocialMediaText(),
                                SizedBox(
                                    height: ScreenUtil.instance.setHeight(20)),
                                _buildSocialButtonRow(),
                              ],
                            ),
                            _buildSignupButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _handleFocus(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Widget _buildEmailField() {
    return Container(
      child: TextFormField(
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.grey[800],
        decoration:
            buildTextFieldDecoration(text: "E-post", prefixIcon: Icons.email),
        validator: (email) => ValidateEmail().validateEmail(email),
        onSaved: (email) => _email = email,
        onFieldSubmitted: (term) {
          _handleFocus(context, _emailFocus, _passwordFocus);
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      child: TextFormField(
        focusNode: _passwordFocus,
        cursorColor: Colors.grey[800],
        obscureText: (showPassword) ? false : true,
        decoration: _buildPasswordDecoration(),
        validator: (password) => ValidatePassword().validatePassword(password),
        onSaved: (password) => _password = password,
      ),
    );
  }

  _buildPasswordDecoration() {
    return InputDecoration(
      fillColor: Colors.grey[350],
      filled: true,
      hintText: "Lösenord",
      hintStyle: TextStyle(fontSize: ScreenUtil.instance.setHeight(16)),
      errorStyle: TextStyle(fontSize: ScreenUtil.instance.setHeight(12)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          EdgeInsets.symmetric(horizontal: ScreenUtil.instance.setWidth(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Colors.green[400], width: ScreenUtil.instance.setWidth(2)),
          borderRadius: BorderRadius.circular(10)),
      prefixIcon: Icon(
        Icons.lock,
        color: Colors.grey[800],
      ),
      suffixIcon: GestureDetector(
        onTap: () => setState(() {
          showPassword = !showPassword;
        }),
        child: Icon(
          (showPassword) ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Container(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(auth: widget.auth)),
        ),
        child: Text(
          "Glömt lösenordet?",
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: RaisedButton(
        onPressed: () => validateAndSubmit(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.grey[350],
        child: Text(
          "LOGGA IN",
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: ScreenUtil.instance.setHeight(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInWithSocialMediaText() {
    return Container(
      height: ScreenUtil.instance.setHeight(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "- ELLER -",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(14),
            ),
          ),
          Text(
            "Logga in med",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildSocialButton(
          () {
            signInWithGoogle();
          },
          AssetImage(
            "assets/images/google.png",
          ),
          "Google",
        ),
        Column(
          children: <Widget>[
            GestureDetector(
              onTap: () => _buildLoginAsGuestAlert(),
              child: Container(
                height: ScreenUtil.instance.setHeight(60),
                width: ScreenUtil.instance.setHeight(60),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[800],
                    size: ScreenUtil.instance.setHeight(55),
                  ),
                ),
              ),
            ),
            SizedBox(height: ScreenUtil.instance.setHeight(5)),
            Text(
              "Gäst",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil.instance.setHeight(14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _buildLoginAsGuestAlert() {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      title: Text(
        "OBS",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
      content: Wrap(
        children: <Widget>[
          Text(
            "Som gästanvändare får du inte åtkomst till all funktionalitet. Vi rekommenderar att du loggar in med ditt Cadence eller Google-konto.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  anonSignIn();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Fortsätt som gäst",
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: ScreenUtil.instance.setHeight(18),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Avbryt",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(18),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void anonSignIn() {
    widget.auth.signInAnon();
    widget.onSignedIn();
  }

  Widget _buildSocialButton(Function onTap, AssetImage logo, String text) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: ScreenUtil.instance.setHeight(60),
            width: ScreenUtil.instance.setHeight(60),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                image: logo,
              ),
            ),
          ),
        ),
        SizedBox(height: ScreenUtil.instance.setHeight(5)),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil.instance.setHeight(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return Container(
      padding: EdgeInsets.only(bottom: ScreenUtil.instance.setHeight(5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Har du inget konto?",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(14),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(
                    auth: widget.auth, onSignedIn: widget.onSignedIn),
              ),
            ),
            child: Text(
              " Skapa konto",
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

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      print("Form is valid");
      return true;
    } else {
      print("Form is invalid");
      return false;
    }
  }

  void validateAndSubmit(BuildContext context) async {
    try {
      if (validateAndSave()) {
        String userId =
            await widget.auth.signInWithEmailAndPassword(_email, _password);
        print("Signed in: $userId");
        widget.onSignedIn();
      }
    } catch (signInError) {
      if (signInError is PlatformException) {
        if (signInError.code == "ERROR_USER_NOT_FOUND") {
          showDialog(
              context: context,
              builder: (_) {
                return CustomAlertDialog(
                    title: "Fel e-post",
                    content:
                        "Det finns inget konto med denna e-post. Försök igen.");
              });
          print("WRONG EMAIL: $signInError");
        } else if (signInError.code == "ERROR_WRONG_PASSWORD") {
          showDialog(
              context: context,
              builder: (_) {
                return CustomAlertDialog(
                    title: "Fel lösenord",
                    content: "Det angivna lösenordet är fel. Försök igen.");
              });

          print("WRONG PASSWORD --> $signInError");
        }
      }
    }
  }

  void signInWithGoogle() async {
    await widget.auth.signInWithGoogle();
    widget.onSignedIn();
  }
}
