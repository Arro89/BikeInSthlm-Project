import 'dart:convert';
import 'package:http/http.dart' as http;

class Response {
  RESPONSE rESPONSE;

  Response({this.rESPONSE});

  Response.fromJson(Map<String, dynamic> json) {
    rESPONSE = json['RESPONSE'] != null
        ? new RESPONSE.fromJson(json['RESPONSE'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.rESPONSE != null) {
      data['RESPONSE'] = this.rESPONSE.toJson();
    }
    return data;
  }
}

class RESPONSE {
  List<RESULT> rESULT;

  RESPONSE({this.rESULT});

  RESPONSE.fromJson(Map<String, dynamic> json) {
    if (json['RESULT'] != null) {
      rESULT = new List<RESULT>();
      json['RESULT'].forEach((v) {
        rESULT.add(new RESULT.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.rESULT != null) {
      data['RESULT'] = this.rESULT.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RESULT {
  List<Situation> situation;

  RESULT({this.situation});

  RESULT.fromJson(Map<String, dynamic> json) {
    if (json['Situation'] != null) {
      situation = new List<Situation>();
      json['Situation'].forEach((v) {
        situation.add(new Situation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.situation != null) {
      data['Situation'] = this.situation.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Situation {
  List<Deviation> deviation;
  String id;

  Situation({this.deviation, this.id});

  Situation.fromJson(Map<String, dynamic> json) {
    if (json['Deviation'] != null) {
      deviation = new List<Deviation>();
      json['Deviation'].forEach((v) {
        deviation.add(new Deviation.fromJson(v));
      });
    }
    id = json['Id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.deviation != null) {
      data['Deviation'] = this.deviation.map((v) => v.toJson()).toList();
    }
    data['Id'] = this.id;
    return data;
  }
}

class Deviation {
  List<int> countyNo;
  String endTime;
  Geometry geometry;
  String iconId;
  String message;
  String actualMessage;
  String messageCode;
  String messageType;
  String startTime;

  Deviation(
      {this.countyNo,
        this.endTime,
        this.geometry,
        this.iconId,
        this.message,
        this.messageCode,
        this.messageType,
        this.startTime});

  Deviation.fromJson(Map<String, dynamic> json) {
    countyNo = json['CountyNo'].cast<int>();
    endTime = json['EndTime'];
    geometry = json['Geometry'] != null
        ? new Geometry.fromJson(json['Geometry'])
        : null;
    iconId = json['IconId'];
    message = json['Message'];

    if(message!=null){
      var arr = message.split(".");
      var builder = "";
      for(int i = 0; i < arr.length; i++) {
        if (arr[i].contains("Cykel-") || arr[i].contains("cyklister") ||
            arr[i].contains("cykelväg")) {
          builder = builder + arr[i];
        }
      }
      actualMessage = builder;
    }
    messageCode = json['MessageCode'];
    messageType = json['MessageType'];
    startTime = json['StartTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['CountyNo'] = this.countyNo;
    data['EndTime'] = this.endTime;
    if (this.geometry != null) {
      data['Geometry'] = this.geometry.toJson();
    }
    data['IconId'] = this.iconId;
    data['Message'] = this.message;
    data['MessageCode'] = this.messageCode;
    data['MessageType'] = this.messageType;
    data['StartTime'] = this.startTime;
    return data;
  }
}

class Geometry {
  String sWEREF99TM;
  String wGS84;
  var coordinates;

  Geometry({this.sWEREF99TM, this.wGS84});

  Geometry.fromJson(Map<String, dynamic> json) {
    sWEREF99TM = json['SWEREF99TM'];
    wGS84 = json['WGS84'];
    var arr = wGS84.split("(");
    var arr2 = arr[1].split(" ");

    coordinates = [double.parse(arr2[1].substring(0,arr2[1].length -1)), double.parse(arr2[0]) ];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SWEREF99TM'] = this.sWEREF99TM;
    data['WGS84'] = this.wGS84;
    return data;
  }
}


