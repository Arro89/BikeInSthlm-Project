

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoadWork{
  //position för vägarbetet
  LatLng _position;
  //Unik id
  String _id;
  //Meddelandet om vad det innebär
  String _message;
  //Starttid
  DateTime _startTime;
  //Planerad sluttid (om applicerbart annars null)
  DateTime _endTime;
  //Typ av problem (vanligtvis roadwork)
  String _type;

  //Konstruktor
  // ignore: unnecessary_statements
  RoadWork(){this._position; this._id; this._message; this._startTime; this._endTime; this._type;}

  LatLng getPosition(){
    return _position;
  }

  String getId(){
    return _id;
  }

  String getMessage(){
    return _message;
  }

  DateTime getStartTime(){
    return _startTime;
  }

  DateTime getEndTime(){
    return _endTime;
  }

  String getType(){
    return _type;
  }
}