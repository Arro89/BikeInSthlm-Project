import 'dart:async';

import 'package:bikeinsthlm/artefacts/error_report.dart';
import 'package:bikeinsthlm/artefacts/saved_route.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:firebase_auth/firebase_auth.dart';
import "package:firebase_database/firebase_database.dart";
import 'package:flutter/services.dart';

import 'authentication.dart';

class DatabaseService {
  DatabaseService({this.uid, this.auth});
  final String uid;
  final BaseAuth auth;

  ///För Firestore (user profiles/saved routes)
  final CollectionReference userProfiles =
      Firestore.instance.collection("userProfiles");

  ///För RealTime Database
  //Antagligen ta bort final metoden.
  final DatabaseReference ref = FirebaseDatabase.instance.reference().child("customMarkers");


  /// ----------------- USER PROFILE RELATED --------------------------///
  ///


  ///Uppdatera all info användaren har
  Future updateUserData({String name, String email, String phoneNumber, String homeAddress, String workAddress}) async {
    DocumentReference dbRef = userProfiles.document(uid).collection("myProfile").document("myInfo");
    createAddressDocument();
    if (phoneNumber == null || phoneNumber == "") {
      dbRef.setData({
        "name": name,
        "email": email,
      }, merge: true);
    } else {
      dbRef.setData({
        "name": name,
        "phoneNr": phoneNumber,
        "email": email,
      }, merge: true);
    }
//      return await userProfiles.document(uid).collection("myProfile").document("myInfo").setData({
//        "name": name,
//        "phoneNr": phoneNumber,
//        "email": email,
//      });
  }

  void createAddressDocument() async {
    userProfiles.document(uid).collection("myProfile").document("myAddresses").setData({
    }, merge: true);
  }

  ///Uppdatera hemadressen
  Future updateHomeAddress({String homeAddress}) async {
    return await userProfiles.document(uid).collection("myProfile").document("myAddresses").setData({
      "homeAddress": homeAddress,
    }, merge: true);
  }

  ///Uppdatera arbetsadressen
  Future updateWorkAddress({String workAddress}) async {
    return await userProfiles.document(uid).collection("myProfile").document("myAddresses").setData({
      "workAddress": workAddress,
    }, merge:  true);
  }

  ///Onödig metod egentligen, blir svårare att ändra på varenda ställe där man
  ///anropar vad för info man vill ha än att duplicate kod som hämtar olika
  ///data.. Kan simplifieras ännu mer tbh but aint nobody got time for that
  Future<String> getUserData(String info) async {
    try {
      return await userProfiles.document(uid).collection("myProfile").document("myInfo").get().then((documentSnapshot) =>
      documentSnapshot.data["$info"].toString());
    } catch (e) {
      print (e);
    }
  }

  //METODER SOM KOMMER BEHÖVA ANVÄNDAS ISTÄLLET FÖR GETUSERDATA!!!!
  //TODO jag (Arvin) får fixa de som använder getUserData sen
  Future<String> getUsersName() async {
    String username = await _getFromDatabase("myInfo", "name");
    return username;
  }

  Future<String> getUsersEmail() async {
    String email = await _getFromDatabase("myInfo", "email");
    return email;
  }

  Future<String> getUsersPhoneNr() async {
    String phoneNr = await _getFromDatabase("myInfo", "phoneNr");
    return phoneNr;
  }


  Future<String> getUsersHomeAddress() async {
    String homeAddress = await _getFromDatabase("myAddresses", "homeAddress");
    return homeAddress;
  }

  Future<String> getUsersWorkAddress() async {
    String workAddress = await _getFromDatabase("myAddresses", "workAddress");
    return workAddress;
  }

  Future<String> _getFromDatabase(String typeOfInfo, String info) async {
    try {
      return await userProfiles.document(uid).collection("myProfile").document("$typeOfInfo").get().then((documentSnapshot) =>
      documentSnapshot.data["$info"].toString());
    } catch (e) {
      print(e);
      return null;
    }
  }

  void deleteUser(FirebaseUser user) {
    DocumentReference toDelete = userProfiles.document(user.uid);
    deleteMyInfo(toDelete);
    deleteMyAddresses(toDelete);
    deleteSavedRoutes(toDelete);
    deleteAuth(user);
  }

  void deleteMyInfo(DocumentReference toDelete) {
    toDelete.collection("myProfile").document("myInfo").delete();
  }

  void deleteMyAddresses(DocumentReference toDelete) {
    toDelete.collection("myProfile").document("myAddresses").delete();
  }

  void deleteSavedRoutes(DocumentReference toDelete) {
    toDelete.collection("savedRoutes").getDocuments().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents){
        ds.reference.delete();
      }
      });
  }

  void deleteAuth(FirebaseUser user){
    user.delete();
  }

//  void deleteUser(FirebaseUser user) async {
//    if (user.uid == uid){
//      _deleteFromFirestore(user);
//    }
//  }
//
//  void _deleteFromFirestore(FirebaseUser user) async {
//    DocumentReference toDelete = userProfiles.document(user.uid);
//    CollectionReference myProfile = toDelete.collection("myProfile");
//    myProfile.document("myInfo").delete();
//    myProfile.document("myAddresses").delete();
//    myProfile.document("savedRoutes").delete();
//    toDelete.delete();
//    print("Documents deleted?");
//  }

  /// ------------ END OF USER PROFILE RELATED---------------------///




  /// ---------------------- SAVE ROUTES -------------------------///
  Future saveRoute(SavedRoute route) async {
//    CollectionReference routeRef = userProfiles.document(uid).collection("savedRoutes");
//    return await routeRef.add(route.toMap());
    CollectionReference routeRef = userProfiles.document(uid).collection("savedRoutes");
    DocumentReference docRef = routeRef.document();
    route.routeID = docRef.documentID;
    return await docRef.setData(route.toMap());
  }

  Future getRoute() async {
    CollectionReference routeRef = userProfiles.document(uid).collection("savedRoutes");
    try {
      var savedRoute = await routeRef.getDocuments();
      if (savedRoute.documents.isNotEmpty){
        return savedRoute.documents.map((snapshot) => SavedRoute.fromMap(snapshot.data));
      }
    } catch (e){
      print (e);
    }
  }

  Future deleteRoute(SavedRoute route) async {
    CollectionReference routeRef = userProfiles.document(uid).collection("savedRoutes");
    print(routeRef.document(route.routeID).documentID);
    routeRef.document(route.routeID).delete();
  }


  /// ----------------------- CUSTOM PINS -------------------------------///
  ///
  ///

  //Uppdaterat createRecord för att ta in rätt info i RTDB.
  void createRecord(ErrorReport errorReport) async {
    var newRef = ref.push();
    String refKey = newRef.key;
    //testprint nyckeln
    print(refKey);
    errorReport.markerId = refKey;

      newRef.set(
        errorReport.toJson()).catchError((error) {
          if (error is PlatformException){
            if (error.message == "Permission denied") {
              print(error);
            }
          }
      });
  }

  void updateRecord(ErrorReport errorReport) async {
    String pinRef = errorReport.markerId;
    ref.child(pinRef).update(errorReport.toJson());
  }

  ///FÖR ATT TA BORT AUTOMATISKT
  void deleteRecord(ErrorReport errorReport) {
    ref.child(errorReport.markerId).remove();
  }

  Future<int> getLike(ErrorReport rep) async {
    int likes;
    var like = await ref.child(rep.markerId).once().then((value) => {
      value.value["Likes"],
    });
    for (int amountOfLikes in like){
      likes = amountOfLikes;
    }
    return likes;
  }

  Future<int> getDislike(ErrorReport rep) async {
    int dislikes;
    var like = await ref.child(rep.markerId).once().then((value) => {
      value.value["Dislikes"],
    });
    for (int amountOfLikes in like){
      dislikes = amountOfLikes;
    }
    return dislikes;
  }

  Future<String> getCreator() async {
    return userProfiles.document(uid).collection("myProfile").document("myInfo").get().then((documentSnapshot) =>
        documentSnapshot.data["name"].toString());
  }

  ///------------------END OF CUSTOM PINS -------------------------------///
}