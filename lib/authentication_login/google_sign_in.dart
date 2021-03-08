///KAN ANVÄNDAS FÖR ATT BRYTA UT SIGN IN WITH GOOGLE. Dock borde widget.onSignedIn()
///vara kvar för det är en client-relaterad grej.
///
/// OBS ANVÄNDS EJ JUST NU

import 'package:bikeinsthlm/authentication_login/authentication.dart';
import 'package:flutter/cupertino.dart';

class GoogleSignIn{
  GoogleSignIn({this.auth, this.onSignedIn});
  final BaseAuth auth;
  final VoidCallback onSignedIn;

  Future signIn() async {
    String userId = await auth.signInWithGoogle();
    if (userId != null){
      print("Signed in: $userId");
      onSignedIn();
    } else {
      return;
    }
  }
}

