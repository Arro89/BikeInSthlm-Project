class SavedRoute {
  String creator;
  String name;
  String routeID;
  //EVENTUELLT FÖR NAMNGIVNA RUTTER?
  String to;
  String from;
  String routeURL;
  //Data om rutten
  String totalUp,
      totalDown,
      time,
      distance,
      savedC02,
      quietness,
      trafficLights,
      crosswalks,
      walking,
      uphill;
  List<dynamic> elevation;
  List<dynamic> distances;
  List<dynamic> coordinates;



  //Denna kanske ska vara i user klass ist och att user har ett routeobjekt som jobbrutt, vet inte
  bool workRoute;

  SavedRoute(
      { this.creator, this.from, this.to,
        this.routeURL, this.workRoute, this.name,
        this.totalDown, this.totalUp, this.time,
        this.distance, this.savedC02, this.quietness,
        this.trafficLights, this.crosswalks, this.walking, this.elevation,
        this.uphill, this.distances, this.routeID, this.coordinates});

  Map<String, dynamic> toMap() {
    return {
      "ruttnamn": name,
      "skapare": creator,
      "från": from,
      "till": to,
      "ruttensURL": routeURL,
      "jobbrutt": workRoute,
      "totalt nedför": totalDown,
      "totalt uppför": totalUp,
      "tid": time,
      "distans": distance,
      "sparad C02": savedC02,
      "ljudnivå": quietness,
      "trafikljus": trafficLights,
      "övergångsställen": crosswalks,
      "gående": walking,
      "höjdskillnader" : elevation,
      "uppförsbackar" : uphill,
      "distanser" : distances,
      "routeID": routeID,
      "koordinater" : coordinates,
    };
  }

  static SavedRoute fromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    return SavedRoute(
      name: map["ruttnamn"],
      creator: map["skapare"],
      from: map["från"],
      to: map["till"],
      routeURL: map["ruttensURL"],
      workRoute: map["jobbrutt"],
      totalDown: map["totalt nedför"],
      totalUp: map["totalt uppför"],
      time: map["tid"],
      distance: map["distans"],
      savedC02: map["sparad C02"],
      quietness: map["ljudnivå"],
      trafficLights: map["trafikljus"],
      crosswalks: map["övergångsställen"],
      walking: map["gående"],
      elevation: map["höjdskillnader"],
      uphill: map["uppförsbackar"],
      distances: map["distanser"],
      routeID: map["routeID"],
      coordinates: map["koordinater"]
    );
  }

//  SavedRoute.fromSnapshot(DataSnapshot snapshot)
//      : creator = snapshot.value["Skapare"],
//        to = snapshot.value["Från"],
//        from = snapshot.value["Till"],
//        routeURL = snapshot.value["Ruttens URL"],
//        workRoute = snapshot.value["Jobbrutt"];
//
//  toJson() {
//    return {
//      "Skapad av": creator,
//      "Ruttnamn": name,
//      "Till": to,
//      "Från": from,
//      "Ruttens URL": routeURL,
//      "Jobbrutt": workRoute,
//    };
//  }
}
