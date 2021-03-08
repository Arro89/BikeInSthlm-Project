import 'package:firebase_database/firebase_database.dart';
import "package:intl/intl.dart";

class ErrorReport {
  String creator;
  String address;
  String _timeCreated;
  String type;
  String _endDate;
  int agreements;
  String title;
  String description; //string? :S känns opraktiskt med string
  double lat;
  double lon;
  String markerId;
  bool isAdded = false;
  int likes = 0;
  int dislikes = 0;
  List voters;



  ErrorReport(String type, String creator, String title, double lat, double lon,
      {String description, String timeCreated, String endDate, String address}) {
    this.type = type;
    this.creator = creator;
    this.title = title;
    this.lat = lat;
    this.lon = lon;
    this.description = description;
    this.timeCreated = timeCreated;
    this.endDate = endDate;
    this.address = address;
    this.likes = likes;
    this.dislikes = dislikes;
  }

  ErrorReport.fromSnapshot(DataSnapshot snapshot)
      : type = snapshot.value["Typ"],
        creator = snapshot.value["Rapported av"],
        title = snapshot.value["Titel"],
        lat = snapshot.value["Lat"],
        lon = snapshot.value["Lon"],
        description = snapshot.value["Beskrivning"],
        _timeCreated = snapshot.value["Skapad"],
        _endDate = snapshot.value["Slutdatum"],
        markerId = snapshot.value["MarkerId"],
        address = snapshot.value["Address"],
        //Extra tillägg
        likes = snapshot.value["Likes"],
        dislikes = snapshot.value["Dislikes"],
        voters = snapshot.value["Röstat"];


  toJson() {
    return {
      "Typ": type,
      "Rapported av": creator,
      "Titel": title,
      "Lat": lat,
      "Lon": lon,
      "Beskrivning": description,
      "Skapad": timeCreated,
      "Slutdatum": endDate,
      "MarkerId": markerId,
      "Address": address,
      //EXTRA TILLÄGG
      "Likes": likes,
      "Dislikes": dislikes,
      "Röstat": voters,
    };
  }

  String get timeCreated => _timeCreated;
  String get endDate => _endDate;

  //Om man skickat med en tid, dvs vid återskapande från firestore, så tilldelas
  //objektet den tid som finns, annars så tilldelas den NU som tid.
  set timeCreated(String value) {
    if (value != null) {
      _timeCreated = value;
    } else {
      _timeCreated = DateFormat("yyyy-MM-dd - HH:mm").format(DateTime.now());
    }
  }

  //Hanterar endDate, om inget tillgängligt skriv ut det
  //Egentligen samma princip som set timeCreated, behövs value för återskapande från
  //firestore.
  set endDate(String value) {
    if (endDate != null) {
      _endDate = value;
    } else {
      //Välj ett endDate beroende på typ av kategori
      _endDate = getEndDate();
    }
  }

  //Avgör vad för slutdatum objekten har baserat på sina kategorier
  String getEndDate() {
    String createdTrimmed = _timeCreated.replaceAll("-" + " ", "");
    DateTime creation = DateTime.parse(createdTrimmed);
    DateTime end;

    switch (this.type) {
      case "Vägproblem":
        return "Tillsvidare";
      case "Övrigt":
        end = creation.add(Duration(days: 3));
        break;
      case "Avstängd väg":
        end = creation.add(Duration(days: 2));
        break;
      case "Vägarbete":
        end = creation.add(Duration(days: 7));
        break;
      case "Hinder":
        end = creation.add(Duration(days: 2));
        break;
      case "Hög trafik":
        end = creation.add(Duration(days: 1));
        break;
      case "Felaktig skyltning":
        return "Tillsvidare";
      default:
        return "Inget slutdatum tillgängligt";
    }
    return DateFormat("yyyy-MM-dd - HH:mm").format(end);
  }

  DateTime getDateTimeCreated() {
    return trimDateTime(_timeCreated);
  }

  DateTime getDateTimeEnd() {
    return trimDateTime(_endDate);
  }

  DateTime trimDateTime(String date) {
    String trimmedDate = date.replaceAll("-" + " ", "");
    try {
      return DateTime.parse(trimmedDate);
    } catch (e) {
      if (e is FormatException){
//        print("Datum ej tillgängligt");
      }
    }
  }

  updateLike(String uid) {
    if (!alreadyVoted(uid)) {
      likes += 1;
      voters.add(uid);
      if (likes <= 5) {
        DateTime oldEnd = getDateTimeEnd();
        if (oldEnd != null) {
          DateTime newEnd = oldEnd.add(Duration(hours: 10));
          endDate = formatDate(newEnd);
        }
      }
    } else {
      return;
    }
  }

  updateDislike(String uid) {
    if (!alreadyVoted(uid)){
      dislikes += 1;
      voters.add(uid);
    } else {
      return;
    }
  }

  bool alreadyVoted(String uid){
    if (voters == null){
      voters = new List();
      return false;
    } else {
      bool alreadyVoted = voters.contains(uid) ? true : false;
      return alreadyVoted;
    }
  }

  formatDate(DateTime date){
    return DateFormat("yyyy-MM-dd - HH:mm").format(date);
  }

}
