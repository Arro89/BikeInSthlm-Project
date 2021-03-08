import 'package:google_maps_flutter/google_maps_flutter.dart';
Map<String, String> translations = {
  "straight on": "följ vägen",
  "bear left" : "sväng svagt vänster",
  "bear right" : "sväng svagt höger",
  "turn right" : "sväng höger",
  "turn left" : "sväng vänster",
  "sharp right" : "sväng skarpt till höger",
  "sharp left" : "sväng skarpt till vänster",
  "join roundabout" : "åk in i rondellen",
  "first exit" : "åk ut ur rondellen vid första avfarten",
  "second exit" : "åk ut ur rondellen vid andra avfarten",
  "third exit" : "åk ut ur rondellen vid tredje avfarten",
  "fourth exit" : "åk ut ur rondellen vid fjärde avfarten",
};
class Marker {
  List<Marker2> marker;
  //List<Waypoint> waypoint;

  Marker({this.marker});

  Marker.fromJson(Map<String, dynamic> json) {
    if (json['marker'] != null) {
      marker = new List<Marker2>();
      json['marker'].forEach((v) {
        marker.add(new Marker2.fromJson(v));
      });
    }
    /*if (json['waypoint'] != null) {
      waypoint = new List<Waypoint>();
      json['waypoint'].forEach((v) {
        waypoint.add(new Waypoint.fromJson(v));
      });
    }

     */
    

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.marker != null) {
      data['marker'] = this.marker.map((v) => v.toJson()).toList();
    }
    /*if (this.waypoint != null) {
      data['waypoint'] = this.waypoint.map((v) => v.toJson()).toList();
    }
    
     */
    return data;
  }
}

class Marker2 {
  Attributes attributes;

  Marker2({this.attributes});

  Marker2.fromJson(Map<String, dynamic> json) {
    attributes = json['@attributes'] != null
        ? new Attributes.fromJson(json['@attributes'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.attributes != null) {
      data['@attributes'] = this.attributes.toJson();
    }
    return data;
  }
}

class Attributes {
  String start;
  String finish;
  String startBearing;
  String startSpeed;
  String startLongitude;
  String startLatitude;
  String finishLongitude;
  String finishLatitude;
  String crowFlyDistance;
  String event;
  String whence;
  String speed;
  String itinerary;
  String clientRouteId;
  String plan;
  String note;
  String length;
  String time;
  String busynance;
  String quietness;
  String signalledJunctions;
  String signalledCrossings;
  String west;
  String south;
  String east;
  String north;
  String name;
  String walk;
  String leaving;
  String arriving;
  String coordinates;
  String elevations;
  String distances;
  String grammesCO2saved;
  String calories;
  String edition;
  String type;
  String legNumber;
  String distance;
  String flow;
  String turn;
  String color;
  String points;

  String provisionName;
  String nextTurn;
  String extraInfo;
  bool straightOn;
  bool longLeg;
  int legLength;
  int toAdd;
  bool roundAbout;
  List<num> elevation = List<num>();
  List<num> distanceList = List<num>();
  List<LatLng> pointsList = List<LatLng>();
  List<LatLng> coordinateList = List<LatLng>();
  num totalUp = 0;
  num totalDown = 0;


  Attributes(
      {this.start,
        this.finish,
        this.startBearing,
        this.startSpeed,
        this.startLongitude,
        this.startLatitude,
        this.finishLongitude,
        this.finishLatitude,
        this.crowFlyDistance,
        this.event,
        this.whence,
        this.speed,
        this.itinerary,
        this.clientRouteId,
        this.plan,
        this.note,
        this.length,
        this.time,
        this.busynance,
        this.quietness,
        this.signalledJunctions,
        this.signalledCrossings,
        this.west,
        this.south,
        this.east,
        this.north,
        this.name,
        this.walk,
        this.leaving,
        this.arriving,
        this.coordinates,
        this.elevations,
        this.distances,
        this.grammesCO2saved,
        this.calories,
        this.edition,
        this.type,
        this.legNumber,
        this.distance,
        this.flow,
        this.turn,
        this.color,
        this.points,
        this.provisionName});
  static bool root = true;

  Attributes.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    finish = json['finish'];
    startBearing = json['startBearing'];
    startSpeed = json['startSpeed'];
    startLongitude = json['start_longitude'];
    startLatitude = json['start_latitude'];
    finishLongitude = json['finish_longitude'];
    finishLatitude = json['finish_latitude'];
    crowFlyDistance = json['crow_fly_distance'];
    event = json['event'];
    whence = json['whence'];
    speed = json['speed'];
    itinerary = json['itinerary'];
    clientRouteId = json['clientRouteId'];
    plan = json['plan'];
    note = json['note'];
    length = json['length'];
    time = json['time'];
    busynance = json['busynance'];
    quietness = json['quietness'];
    elevations = json['elevations'];
    signalledJunctions = json['signalledJunctions'];
    signalledCrossings = json['signalledCrossings'];
    west = json['west'];
    south = json['south'];
    east = json['east'];
    north = json['north'];
    name = json['name'];
    walk = json['walk'];
    leaving = json['leaving'];
    arriving = json['arriving'];
    coordinates = json['coordinates'];



    var arr;
    if(coordinates!=null){
      arr = coordinates.split(" ");
    }
    if(arr!=null){
      arr.forEach((string){
        var arr2;
        if(string!=null){
          arr2 = string.split(",");
        }
        try{
          double test = (double.parse(arr2[1]));
          double test2 = (double.parse(arr2[0]));

          if(test!=null && test2 != null){
            LatLng latLng = LatLng(test,test2);
            coordinateList.add(latLng);
          }


          //coordinateList.add(LatLng(test,test2));
        }catch(e){

        }
        //coordinateList.add(LatLng(double.parse(arr2[1]), double.parse(arr2[0])));

      });
    }

    //print(coordinateList);
    elevations = json['elevations'];


    var data = elevations.split(",");
    for(String s in data){
      elevation.add(num.parse(s));
    }
    for(num n in elevation){
      n = n.round();
    }

    for(int i = 0; i<elevation.length-1; i++){
      var current = elevation[i];
      var next = elevation [i+1];
      if(next != null){
        num sum = current - next;
        (sum < 0) ? totalUp += (sum*-1) : totalDown += sum;
      }
    }

    distances = json['distances'];
    var distancesArr  = distances.split(",");
    for(String s in data){
      distanceList.add(num.parse(s));
    }
    for(int i = 0; i<distanceList.length-1; i++){
      var current = distanceList[i];
      var next = distanceList [i+1];
      if(next != null){
        distanceList[i+1] = current + next;
      }
    }
    for(num n in distanceList){
      n = n.round();
    }

    grammesCO2saved = json['grammesCO2saved'];
    calories = json['calories'];
    edition = json['edition'];
    type = json['type'];
    legNumber = json['legNumber'];
    distance = json['distance'];
    if(distance!=null){
      legLength = num.parse(distance).toInt();

    }
    longLeg = legLength != null && legLength > 60 ? true : false;

    flow = json['flow'];
    turn = json['turn'];

    straightOn = turn == "straight on" ?  true : false;
    roundAbout = turn == "join roundabout" ? true : false;
    turn = translations[turn] != null ? translations[turn] : null;

    color = json['color'];
    points = json['points'];

    if(points !=null){
      arr = points.split(" ");
    }
    if(arr!=null){
      arr.forEach((string){
        var arr2;
        if(string!=null){
          arr2 = string.split(",");
        }
        try{
          double test = (double.parse(arr2[1]));
          double test2 = (double.parse(arr2[0]));

          if(test!=null && test2 != null){
            LatLng latLng = LatLng(test,test2);
            pointsList.add(latLng);
          }


          //coordinateList.add(LatLng(test,test2));
        }catch(e){

        }
        //coordinateList.add(LatLng(double.parse(arr2[1]), double.parse(arr2[0])));

      });
    }
    provisionName = json['provisionName'];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['start'] = this.start;
    data['finish'] = this.finish;
    data['startBearing'] = this.startBearing;
    data['startSpeed'] = this.startSpeed;
    data['start_longitude'] = this.startLongitude;
    data['start_latitude'] = this.startLatitude;
    data['finish_longitude'] = this.finishLongitude;
    data['finish_latitude'] = this.finishLatitude;
    data['crow_fly_distance'] = this.crowFlyDistance;
    data['event'] = this.event;
    data['whence'] = this.whence;
    data['speed'] = this.speed;
    data['itinerary'] = this.itinerary;
    data['clientRouteId'] = this.clientRouteId;
    data['plan'] = this.plan;
    data['note'] = this.note;
    data['length'] = this.length;
    data['time'] = this.time;
    data['busynance'] = this.busynance;
    data['quietness'] = this.quietness;
    data['signalledJunctions'] = this.signalledJunctions;
    data['signalledCrossings'] = this.signalledCrossings;
    data['west'] = this.west;
    data['south'] = this.south;
    data['east'] = this.east;
    data['north'] = this.north;
    data['name'] = this.name;
    data['walk'] = this.walk;
    data['leaving'] = this.leaving;
    data['arriving'] = this.arriving;
    data['coordinates'] = this.coordinates;
    data['elevations'] = this.elevations;
    data['distances'] = this.distances;
    data['grammesCO2saved'] = this.grammesCO2saved;
    data['calories'] = this.calories;
    data['edition'] = this.edition;
    data['type'] = this.type;
    data['legNumber'] = this.legNumber;
    data['distance'] = this.distance;
    data['flow'] = this.flow;
    data['turn'] = this.turn;
    data['color'] = this.color;
    data['points'] = this.points;
    data['provisionName'] = this.provisionName;
    return data;
  }

}

class Attributes2 {
  String sequenceId;
  String longitude;
  String latitude;

  Attributes2({this.sequenceId, this.longitude, this.latitude});

  Attributes2.fromJson(Map<String, dynamic> json) {
    sequenceId = json['sequenceId'];
    longitude = json['longitude'];
    latitude = json['latitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sequenceId'] = this.sequenceId;
    data['longitude'] = this.longitude;
    data['latitude'] = this.latitude;
    return data;
  }
}


//https://www.cyclestreets.net/api/journey.json?key=a38b3c3ac682b677&reporterrors=1&itinerarypoints=17.855942,59.418831|17.881348,59.381606&plan=balanced
