import "dart:async";
import 'package:bikeinsthlm/authentication_login/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:firebase_auth/firebase_auth.dart";
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class BaseAuth {
  Future signInWithEmailAndPassword(String email, String password);
  Future createUserWithEmailAndPassword(String email, String password, String name, String phoneNumber);
  Future<String> currentUser();
  Future<FirebaseUser> getUser();
  Future signOut();
  Future resetPassword(String email);
  Future signInWithGoogle();
  Future signInAnon();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future signInWithEmailAndPassword(String email, String password) async {
    FirebaseUser user = (await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password)
    ).user;
    print(user.uid);
    //Eventuellt om man vill returnera något men tvek på det vid signIn.
  }

  Future createUserWithEmailAndPassword(String email, String password, String name, String phoneNr) async {
    FirebaseUser user = (await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password)
    ).user;
    generateUser(user.uid, name, email, phoneNr: phoneNr);
    return user.uid;
  }

  Future<String> currentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    if (user != null){
      return user.uid;
    } else {
      print("ERROR ===============> currentUser() is null");
      return null;
    }
  }

  Future<FirebaseUser> getUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    if (user != null){
      return user;
    } else {
      print("ERROR ==============> getUser() is null");
      return null;
    }
  }

  Future signOut() async {
    return _firebaseAuth.signOut();
  }

  Future resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future signInWithGoogle() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email"], hostedDomain: "", clientId: "");
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
      final FirebaseUser user = (await _firebaseAuth.signInWithCredential(credential)).user;
      if (user != null){
        generateUser(user.uid, user.displayName, user.email);
      } else {
        print("ERROR ===============> signInWithGoogle USER WAS NULL");
        return null;
      }
    } catch (e){
      print (e);
    }
  }

  Future signInAnon() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } catch (e) {
      print("ERROR ===============> signInAnon COULD NOT SIGN IN ANONYMOUSLY");
    }
  }

  //Metoden genererar användare i Firestore genom DatabaseService metoden i
  //database.dart
  Future generateUser(String uid, String name, String email, {String phoneNr}) async {
    await DatabaseService(uid: uid).updateUserData(name: name, email: email, phoneNumber: phoneNr);
  }
}
