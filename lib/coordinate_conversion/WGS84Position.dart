import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'position.dart';


enum WGS84Format { Degrees, DegreesMinutes, DegreesMinutesSeconds }

class WGS84Position extends Position {
  WGS84Position(double latitude, double longitude)
      : super(latitude, longitude, Grid.WGS84) {}

  //Måste göra metod för att hantera strängar? Då kan man ta in hela pos som string.

  void setLatitudeFromString(String value, WGS84Format format) {
    value = value.trim();

    if (format == WGS84Format.DegreesMinutes) {
      this.longitude = parseValueFromDmString(value, "S");
    } else if (format == WGS84Format.DegreesMinutesSeconds) {
      this.latitude = parseValueFromDmsString(value, "S");
    } else if (format == WGS84Format.Degrees) {
      this.latitude = double.parse(value);
    }
  }

  void setLongitudeFromString(String value, WGS84Format format) {
    value = value.trim();

    if (format == WGS84Format.DegreesMinutes) {
      this.longitude = parseValueFromDmString(value, "W");
    } else if (format == WGS84Format.DegreesMinutesSeconds) {
      this.longitude = parseValueFromDmsString(value, "W");
    } else if (format == WGS84Format.Degrees) {
      this.longitude = double.parse(value);
    }
  }

  String latitudeToString(WGS84Format format) {
    if (format == WGS84Format.DegreesMinutes) {
      return convToDmString(this.latitude, "N", "S");
    } else if (format == WGS84Format.DegreesMinutesSeconds) {
      return convToDmsString(this.latitude, "N", "S");
    } else {
      return this.latitude.toStringAsFixed(10);
    }
  }

  String longitudeToString(WGS84Format format) {
    if (format == WGS84Format.DegreesMinutes) {
      return convToDmString(this.longitude, "E", "W");
    } else if (format == WGS84Format.DegreesMinutesSeconds) {
      return convToDmsString(this.longitude, "E", "W");
    } else {
      return this.longitude.toStringAsFixed(10);
    }
  }

  String convToDmString(
      double value, String positiveValue, String negativeValue) {
    var val;

    if (value == double.minPositive) {
      return "";
    }
    double degrees = (value.abs()).floorToDouble();
    double minutes = (value.abs() - degrees) * 60;

    if (value >= 0) {
      val = positiveValue;
    } else {
      val = negativeValue;
    }

    //pos or neg value - degrees 0 decimals - något mer
    return "$val ${degrees.toStringAsFixed(0)}º "
        "${((minutes * 10000) / 10000).floorToDouble()}";
  }

  String convToDmsString(
      double value, String positiveValue, String negativeValue) {
    var val;

    if (value == double.minPositive) {
      return "";
    }
    double degrees = (value.abs()).floorToDouble();
    double minutes = (value.abs() - degrees) * 60;
    double seconds = (value.abs() - degrees - minutes / 60) * 3600;

    if (value >= 0) {
      val = positiveValue;
    } else {
      val = negativeValue;
    }

    //pos or neg value - degrees - minutes - något mer
    return "$val ${degrees.toStringAsFixed(0)}º ${minutes.toStringAsFixed(0)} "
        "${((seconds * 100000) / 100000).roundToDouble()}";
  }

  double parseValueFromDmString(String value, String positiveChar) {
    double retVal = 0;
    if (!(value == null)) {
      if (!value.isEmpty) {
        String direction = value.substring(0, 1);
        value = value.substring(1).trim();

        String degree = value.substring(0, value.indexOf("º"));
        value = value.substring(value.indexOf("º") + 1).trim();

        String minutes = value.substring(0, value.indexOf("'"));

        retVal = double.parse(degree);
        retVal += double.parse(minutes.replaceFirst(",", ".")) / 60;

        if (retVal > 90) {
          retVal = double.minPositive;
        }
        if (direction == positiveChar || direction == "-") {
          retVal *= -1;
        }
      }
    } else {
      retVal = double.minPositive;
    }
    return retVal;
  }

  double parseValueFromDmsString(String value, String positiveChar) {
    double retVal = 0;
    if (!(value == null)) {
      if (!value.isEmpty) {
        String direction = value.substring(0, 1);
        value = value.substring(1).trim();

        String degree = value.substring(0, value.indexOf("º"));
        value = value.substring(value.indexOf("º") + 1).trim();

        String minutes = value.substring(0, value.indexOf("'"));
        value = value.substring(value.indexOf("'") + 1).trim();

        String seconds = value.substring(0, value.indexOf("\n"));

        retVal = double.parse(degree);
        retVal += double.parse(minutes) / 60;

        retVal += double.parse(seconds.replaceFirst(",", ".")) / 3600;

        if (retVal > 90) {
          retVal = double.minPositive;
          return retVal;
        }
        if (direction == positiveChar || direction == "-") {
          retVal *= -1;
        }
      }
    } else {
      retVal = double.minPositive;
    }
    return retVal;
  }
  LatLng toLatLng(){
    return LatLng(getLatitude(), getLongitude());
  }

  //lat och long
  @override
  String toString(){
    return "Latitude: ${latitudeToString(WGS84Format.DegreesMinutesSeconds)} "
        "Longitude: ${longitudeToString(WGS84Format.DegreesMinutesSeconds)}";
  }
}

