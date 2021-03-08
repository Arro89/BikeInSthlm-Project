class SnappedLine {
  List<SnappedPoints> snappedPoints;

  SnappedLine({this.snappedPoints});

  SnappedLine.fromJson(Map<String, dynamic> json) {
    if (json['snappedPoints'] != null) {
      snappedPoints = new List<SnappedPoints>();
      json['snappedPoints'].forEach((v) {
        snappedPoints.add(new SnappedPoints.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.snappedPoints != null) {
      data['snappedPoints'] =
          this.snappedPoints.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SnappedPoints {
  Location location;
  int originalIndex;
  String placeId;

  SnappedPoints({this.location, this.originalIndex, this.placeId});

  SnappedPoints.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    originalIndex = json['originalIndex'];
    placeId = json['placeId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location.toJson();
    }
    data['originalIndex'] = this.originalIndex;
    data['placeId'] = this.placeId;
    return data;
  }
}

class Location {
  double latitude;
  double longitude;

  Location({this.latitude, this.longitude});

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    return data;
  }
}
