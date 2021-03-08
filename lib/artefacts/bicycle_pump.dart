import 'package:google_maps_flutter/google_maps_flutter.dart';
//Ska jag ha sweref här också??


class BicyclePump{
  //Position i LatLng format
  LatLng _position;
  //Unik id
  String _id;
  //Kommentar
  String _comment;
  //Driftsatt eller inte
  bool _commissioned;
  //Senast uppdaterad
  DateTime _lastUpdated;
  //Pumpens address
  String _address;

  //Konstruktor
  // ignore: unnecessary_statements
  BicyclePump(){this._address; this._comment; this._id; this._commissioned; this._lastUpdated; this._position; }

  LatLng getPosition(){
    return _position;
  }

  String getId(){
    return _id;
  }

  String getComment(){
    return _comment;
  }

  bool working(){
    return _commissioned;
  }

  DateTime getLastUpdated(){
    return _lastUpdated;
  }

  String getAddress(){
    return _address;
  }




}