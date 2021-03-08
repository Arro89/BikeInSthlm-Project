import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';
// ignore: camel_case_types
class DistanceCalculator{
  double getDistanceBetween(LatLng point1, LatLng point2, {int method = 1}) {
  var gcd = new GreatCircleDistance(latitude1: point1.latitude, longitude1: point1.longitude, latitude2: point2.latitude, longitude2: point2.longitude);
  //print('Distance from location 1 to 2 using the Haversine formula is: ${gcd.haversineDistance()}');
  //print('Distance from location 1 to 2 using the Spherical Law of Cosines is: ${gcd.sphericalLawOfCosinesDistance()}');
  //print('Distance from location 1 to 2 using the Vicenty`s formula is: ${gcd.vincentyDistance()}');

  return gcd.distance();

    /*if (method == 1){
    print(gcd.haversineDistance());
    return gcd.haversineDistance();
  }
  else if (method == 2){
    print(gcd.sphericalLawOfCosinesDistance());
    return gcd.sphericalLawOfCosinesDistance();
  }
  print(gcd.sphericalLawOfCosinesDistance());
  return gcd.sphericalLawOfCosinesDistance();

   */

  }
}

class GreatCircleDistance {
  final double R = 6371000;  // radius of Earth, in meters
  double latitude1, longitude1;
  double latitude2, longitude2;

  GreatCircleDistance({this.latitude1, this.latitude2, this.longitude1, this.longitude2});

  double distance() {
    double phi1 = this.latitude1 * pi / 180;  // φ1
    double phi2 = this.latitude2 * pi / 180;  // φ2
    var deltaPhi = (this.latitude2 - this.latitude1) * pi / 180;  // Δφ
    var deltaLambda = (this.longitude2 - this.longitude1) * pi / 180;  // Δλ

    var a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}



/*Future<GeoPoint> getCurrentGeoPoint() async {
  Geolocator _geolocator = new Geolocator();
  geoposition.Position position;
  GeoPoint geoPoint;
  try {
    position = await _geolocator.getPosition(LocationAccuracy.high);
    geoPoint = new GeoPoint(position.latitude, position.longitude);
  } on PlatformException {
    print("Couldn't get position");
    geoPoint = new GeoPoint(0.0, 0.0);
  }
  return geoPoint;
}

 */