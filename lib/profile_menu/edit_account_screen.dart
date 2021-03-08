import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:bikeinsthlm/widgets/customAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditAccountScreen extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  void _signOut() async {
    try {
      await auth.signOut();
      onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  EditAccountScreen({this.auth, this.onSignedOut});

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    print("${widget.auth}");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: CustomAppBar(text: "Redigera konto"),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.grey[800],
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              alignment: Alignment.bottomCenter,
              margin:
                  EdgeInsets.only(bottom: ScreenUtil.instance.setHeight(20)),
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) {
                    return _confirmDeletionAlert();
                  },
                ),
                child: Text(
                  "Radera konto",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _confirmDeletionAlert() {
    return AlertDialog(
      contentPadding: EdgeInsets.all(ScreenUtil.instance.setHeight(10)),
      backgroundColor: Colors.grey[800],
      title: Text("Radera konto",
          style: TextStyle(
            color: Colors.red,
            fontSize: ScreenUtil.instance.setHeight(24),
          ),
          textAlign: TextAlign.center),
      content: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          Text(
            "Är du säker på att du vill radera ditt konto? Detta kommer genast att logga ut dig och du kommer inte kunna logga in igen",
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil.instance.setHeight(16),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ScreenUtil.instance.setHeight(60)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                onPressed: () async {
                  await _deleteAccount();
                },
                child: Text(
                  "Radera",
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: ScreenUtil.instance.setHeight(22),
                  ),
                ),
              ),
              Container(
                height: ScreenUtil.instance.setHeight(35),
                child: VerticalDivider(color: Colors.white),
              ),
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Avbryt",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil.instance.setHeight(22),
                  ),
                ),
              ),
            ],
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

  Future _deleteAccount() async {
    FirebaseUser user = await widget.auth.getUser();
    if (user != null) {
      DatabaseService(uid: user.uid).deleteUser(user);
      widget._signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
