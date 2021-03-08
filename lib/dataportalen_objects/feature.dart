

//Högsta klassen, håller listan med alla features (objekt som i det här fallet är cykelpumpar)
import 'package:basic_utils/basic_utils.dart';
import 'package:bikeinsthlm/coordinate_conversion/SWEREF99Position.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Feature {
  String type;
  int totalFeatures;
  List<Features> features;
  Crs crs;
  //Obligatorisk konstruktor
  Feature({this.type, this.totalFeatures, this.features, this.crs});

  //Json konstruktor som tar Map som argument där String motsvarar nyckel och dynamic för att värdet kan vara av olika datatyper.
  Feature.fromJson(Map<String, dynamic> json) {
    //json['key'] extraherar värdet för korresponderande nyckel (variabelnamn i json)
    type = json['type'];
    totalFeatures = json['totalFeatures'];
    //features är i det här fallet en json array.
    if (json['features'] != null) {
      features = new List<Features>();
      json['features'].forEach((v) {
        //Här kallar den på konstruktorn för Features, alltså nivån under Feature
        features.add(new Features.fromJson(v));
      });
    }
    crs = json['crs'] != null ? new Crs.fromJson(json['crs']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['totalFeatures'] = this.totalFeatures;
    if (this.features != null) {
      data['features'] = this.features.map((v) => v.toJson()).toList();
    }
    if (this.crs != null) {
      data['crs'] = this.crs.toJson();
    }
    return data;
  }
}

class Features {
  String type;
  String id;
  Geometry geometry;
  String geometryName;
  PumpProperties properties;

  Features(
      {this.type, this.id, this.geometry, this.geometryName, this.properties});

  Features.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    id = json['id'];
    //geometry är en egen klass innehållande koordinaterna
    geometry = json['geometry'] != null
        ? new Geometry.fromJson(json['geometry'])
        : null;
    geometryName = json['geometry_name'];
    //Properties är egen klass innehållande den mesta informationen om pumpen
    properties = json['properties'] != null
        ? new PumpProperties.fromJson(json['properties'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['id'] = this.id;
    if (this.geometry != null) {
      data['geometry'] = this.geometry.toJson();
    }
    data['geometry_name'] = this.geometryName;
    if (this.properties != null) {
      data['properties'] = this.properties.toJson();
    }
    return data;
  }
}

class Geometry {
  String type;
  List<double> coordinates;
  LatLng position;

  Geometry({this.type, this.coordinates});

  Geometry.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    //Koordinaterna är en array med doubles i JSON och måste därför castas som double men dart fattar att det är en array så man kan tilldela det direkt till en lista
    coordinates = json['coordinates'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    position =  SWEREF99Position(coordinates[1],
        coordinates[0])
        .toWGS84()
        .toLatLng();
    return data;
  }
}

class PumpProperties {
  int oBJECTID;
  int vERSIONID;
  String fEATURETYPENAME;
  int fEATURETYPEOBJECTID;
  int fEATURETYPEVERSIONID;
  String mAINATTRIBUTENAME;
  String mAINATTRIBUTEVALUE;
  String mAINATTRIBUTEDESCRIPTION;
  String adress;
  String index;
  String ventiler;
  String modell;
  String status;
  String kommentar;
  String driftansvar;
  String huvudman;
  String uppdaterad;
  String bilaga;
  String bilventil;
  String cykelventil;
  String racerVentil;
  int vALIDFROM;
  Null vALIDTO;
  int cID;
  int cREATEDATE;
  int cHANGEDATE;
  bool working;

  PumpProperties(
      {this.oBJECTID,
        this.vERSIONID,
        this.fEATURETYPENAME,
        this.fEATURETYPEOBJECTID,
        this.fEATURETYPEVERSIONID,
        this.mAINATTRIBUTENAME,
        this.mAINATTRIBUTEVALUE,
        this.mAINATTRIBUTEDESCRIPTION,
        this.adress,
        this.index,
        this.ventiler,
        this.modell,
        this.status,
        this.kommentar,
        this.driftansvar,
        this.huvudman,
        this.uppdaterad,
        this.bilaga,
        this.bilventil,
        this.cykelventil,
        this.racerVentil,
        this.vALIDFROM,
        this.vALIDTO,
        this.cID,
        this.cREATEDATE,
        this.cHANGEDATE});

  PumpProperties.fromJson(Map<String, dynamic> json) {
    oBJECTID = json['OBJECT_ID'];
    vERSIONID = json['VERSION_ID'];
    fEATURETYPENAME = json['FEATURE_TYPE_NAME'];
    fEATURETYPEOBJECTID = json['FEATURE_TYPE_OBJECT_ID'];
    fEATURETYPEVERSIONID = json['FEATURE_TYPE_VERSION_ID'];
    mAINATTRIBUTENAME = json['MAIN_ATTRIBUTE_NAME'];
    mAINATTRIBUTEVALUE = json['MAIN_ATTRIBUTE_VALUE'];
    mAINATTRIBUTEDESCRIPTION = json['MAIN_ATTRIBUTE_DESCRIPTION'];
    adress = json['Adress'];
    index = json['Index'];
    ventiler = json['Ventiler'];
    modell = json['Modell'];
    status = json['Status'];
    working = (status == "Driftsatt");



    kommentar = json['Kommentar'];
    driftansvar = json['Driftansvar'];
    huvudman = json['Huvudman'];
    uppdaterad = json['Uppdaterad'];
    bilaga = json['Bilaga'];
    bilventil = json['Bilventil'];
    cykelventil = json['Cykelventil'];
    racerVentil = json['Racer_ventil'];
    vALIDFROM = json['VALID_FROM'];
    vALIDTO = json['VALID_TO'];
    cID = json['CID'];
    cREATEDATE = json['CREATE_DATE'];
    cHANGEDATE = json['CHANGE_DATE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['OBJECT_ID'] = this.oBJECTID;
    data['VERSION_ID'] = this.vERSIONID;
    data['FEATURE_TYPE_NAME'] = this.fEATURETYPENAME;
    data['FEATURE_TYPE_OBJECT_ID'] = this.fEATURETYPEOBJECTID;
    data['FEATURE_TYPE_VERSION_ID'] = this.fEATURETYPEVERSIONID;
    data['MAIN_ATTRIBUTE_NAME'] = this.mAINATTRIBUTENAME;
    data['MAIN_ATTRIBUTE_VALUE'] = this.mAINATTRIBUTEVALUE;
    data['MAIN_ATTRIBUTE_DESCRIPTION'] = this.mAINATTRIBUTEDESCRIPTION;
    data['Adress'] = this.adress;
    data['Index'] = this.index;
    data['Ventiler'] = this.ventiler;
    data['Modell'] = this.modell;
    data['Status'] = this.status;
    data['Kommentar'] = this.kommentar;
    data['Driftansvar'] = this.driftansvar;
    data['Huvudman'] = this.huvudman;
    data['Uppdaterad'] = this.uppdaterad;
    uppdaterad = StringUtils.addCharAtPosition(uppdaterad, "-", 3);
    uppdaterad = StringUtils.addCharAtPosition(uppdaterad, "-", 6);
    uppdaterad = StringUtils.addCharAtPosition(uppdaterad, "-", 10);
    data['Bilaga'] = this.bilaga;
    data['Bilventil'] = this.bilventil;
    data['Cykelventil'] = this.cykelventil;
    data['Racer_ventil'] = this.racerVentil;
    data['VALID_FROM'] = this.vALIDFROM;
    data['VALID_TO'] = this.vALIDTO;
    data['CID'] = this.cID;
    data['CREATE_DATE'] = this.cREATEDATE;
    data['CHANGE_DATE'] = this.cHANGEDATE;
    return data;
  }
}

class Crs {
  String type;
  PumpProperties properties;

  Crs({this.type, this.properties});

  Crs.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    properties = json['properties'] != null
        ? new PumpProperties.fromJson(json['properties'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.properties != null) {
      data['properties'] = this.properties.toJson();
    }
    return data;
  }
}





