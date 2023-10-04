import 'dart:async';
import 'dart:core';

import 'package:bikeinsthlm/artefacts/polyline_snapper.dart';
import 'package:bikeinsthlm/routing/polylineDrawer.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "dataportalen_objects/feature.dart";
import "trafikverket_objects/situation.dart";
import "artefacts/route_plan.dart" as routePlanner;
import 'dart:convert';
import 'package:http/http.dart' as http;

//Klassen för att fetcha datat

class Service {
  final String _dataPortalenApiKey = "apikey";
  final String _trafikverketApiKey = "apikey";
  final String _cycleStreetsApiKey = "apikey";
  final String _pumpsFilePath = "assets/files/backup_pumps.json";
  final String _googleApiKey = "apikey";

  routePlanner.Marker marker;
  String lastRouteSearched;

  Future<String> getAddress(LatLng location) async {
    var addresses = await Geocoder.local.findAddressesFromCoordinates(
        Coordinates(location.latitude, location.longitude));
    var first = addresses.first;
    String str;
    if(first.thoroughfare != null){
      str = first.thoroughfare;
      if(first.subThoroughfare != null)
        str += " ${first.subThoroughfare}";
    }


    return str;
  }



  ///Den här metoden hanterar att ladda in och returnera lokala JSON filer
  ///Fyll ut switch satsen bara
  Future<String> _loadUpdateFile(String backUpType) async {
    String backUpFile;
    switch (backUpType) {
      case "pumps":
        backUpFile = _pumpsFilePath;
        break;
    }
    return await rootBundle.loadString(backUpFile);
  }

  Future<routePlanner.Marker> fetchRoute(
      {LatLng start, LatLng destination, List<
          LatLng> waypoints, String routeType, String speed}) async {
    String points = "${start.longitude},${start.latitude}|";
    if (waypoints != null) {
      for (LatLng latlng in waypoints) {
        points += "${latlng.longitude},${latlng.latitude}";
      }
    }
    points += "${destination.longitude},${destination.latitude}";

    lastRouteSearched = "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType";
    http.Response response = await http.get(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType"
    );
    print(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType");

    print(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType");

    print(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType");
    print(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType");
    print(
        "https://www.cyclestreets.net/api/journey.json?key=$_cycleStreetsApiKey&reporterrors=1&itinerarypoints=$points&plan=$routeType");


    if (response.statusCode == 200) {
      var markerObjJson;
      try {
        markerObjJson = jsonDecode(response.body);
        marker = routePlanner.Marker.fromJson(markerObjJson);
        return marker;
      } catch (e) {
        print("===========================>$e");
        throw Exception("Failed to load from server");
      }
    }
  }

  Future<routePlanner.Marker> fetchSavedRoute(String url) async{
    http.Response response = await http.get(
      url
    );
    if (response.statusCode == 200) {
      var markerObjJson;
      try {
        markerObjJson = jsonDecode(response.body);
        marker = routePlanner.Marker.fromJson(markerObjJson);
        return marker;
      } catch (e) {
        print("===========================>$e");
        throw Exception("Failed to load from server");
      }
    }

  }


  String getRouteURL() {
    return lastRouteSearched;
  }

  ///Lägg in en dynamics Map som innehåller nyckel String som säger vad för
  ///objekt som ska hämtas, t ex cykelpumpar eller så, och Value innehåller
  ///lista med objekten

  ///Method to return features objects, i.e. bicycle pumps, from Dataportalens
  ///API
  Feature pumps;
  Response rep;


  //Hämtning av data använder async vilket innebär att den exekveras i en annan ordning än resten av koden (för att den är beroende av att servern besvarar http requesten)
  //Det betyder också att den returnerar Future som är som ett "löfte" vilket inte kan tilldelas till en instansvariabel
  Future<List<dynamic>> fetchPumps() async {
    http.Response response = await http.get(
        "http://openstreetgs.stockholm.se/geoservice/api/$_dataPortalenApiKey/wfs/?version=1.0.0&request=GetFeature&typeName=od_gis:Cykelpump_Punkt&outputFormat=JSON");

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON
      // Json decodear svaret till en variabel som kan castas som sträng eller Map.
      ///Ändrat till en try-catch för att fånga upp errors vid 404
      ///Servern ger inte 404 trots att den borde göra det... ger 200 ändå.
      var featuresObjJson;
      try {
        featuresObjJson = jsonDecode(response.body);
        //Kalla på json-konstruktor för Feature som är högsta klassen i hierarkin och spara till en pump
        pumps = Feature.fromJson(featuresObjJson);
        return pumps.features;
      } catch (e) {
        print("------> Could not parse JSON file due to unknown error");
        //ladda in backup-fil om första inte går
        String backup = await _loadUpdateFile("pumps");
        featuresObjJson = jsonDecode(backup);
        pumps = Feature.fromJson(featuresObjJson);
        return pumps.features;

      }
    } else {
      throw Exception("Failed to load from server");
    }
  }

//returnerar listan med features (pumpar)
  List<dynamic> parsePumps() {
    try {
      return pumps.features;
    } catch (e) {
      print("------> Could not fetch any pumps due to unknown error");
    }
  }

  ///---------------------------------------------------------------------------

  ///Method to return list of situations (deviations) in Stockholms Stad from
  ///Trafikverkets API

  http.Client client = new http.Client();

  Future<List<Situation>> fetchWork() async {
    var request = http.Request(
      'POST',
      Uri.parse('https://api.trafikinfo.trafikverket.se/v1.2/data.json'),
    );
    request.headers.addAll({'Content-Type': 'text/xml'});
    var xml = '''
    <REQUEST>
      <LOGIN authenticationkey="$_trafikverketApiKey" />
      <QUERY objecttype="Situation" schemaversion="1.2">
            <FILTER>
                <OR>
                    <EQ name="Deviation.CountyNo" value="1" />
                    <EQ name="Deviation.CountyNo" value="2" />
                </OR>
                <AND>
                    <LIKE name="Deviation.Message" value="/.cykel/" />
                </AND>
            </FILTER>
            <INCLUDE>Id</INCLUDE>
            <INCLUDE>Deviation.StartTime</INCLUDE>
            <INCLUDE>Deviation.EndTime</INCLUDE>
            <INCLUDE>Deviation.Geometry.WGS84</INCLUDE>
            <INCLUDE>Deviation.Geometry.SWEREF99TM</INCLUDE>
            <INCLUDE>Deviation.CountyNo</INCLUDE>
            <INCLUDE>Deviation.Header</INCLUDE>
            <INCLUDE>Deviation.IconId</INCLUDE>
            <INCLUDE>Deviation.Message</INCLUDE>
            <INCLUDE>Deviation.MessageCode</INCLUDE>
            <INCLUDE>Deviation.MessageType</INCLUDE>
      </QUERY>
    </REQUEST> ''';
    request.body = xml;
    var streamedResponse = await client.send(request);
    var responseBody =
    await streamedResponse.stream.transform(utf8.decoder).join();
    if(responseBody.startsWith("<"))
      return null;
    var situationObjJson = jsonDecode(responseBody);

    rep = Response.fromJson(situationObjJson);
    List<Situation> situation = rep.rESPONSE.rESULT[0].situation;
    for (int i = 0; i < situation.length; i++) {
      Situation sit = situation[i];
      for (int j = 0; j < sit.deviation.length; j++) {
        if (sit.deviation[j].actualMessage == "" ||
            sit.deviation[j].actualMessage == null) {
          sit.deviation.removeAt(j);
        }
      }
    }
    return situation;
  }

  List<dynamic> parseRoadWork() {
    List<Situation> situation = rep.rESPONSE.rESULT[0].situation;
    for (int i = 0; i < situation.length; i++) {
      Situation sit = situation[i];
      for (int j = 0; j < sit.deviation.length; j++) {
        if (sit.deviation[j].actualMessage == "" ||
            sit.deviation[j].actualMessage == null) {
          sit.deviation.removeAt(j);
        }
      }
    }
    return situation;
  }

  Future<SnappedLine> getSnappedLine(List<LatLng> points) async{
    String path = "";
    for (LatLng point in points){
      path +="${point.latitude}, ${point.longitude}|";
    }
    path = path.substring(0, path.length -2);
    http.Response response = await http.get(
        "https://roads.googleapis.com/v1/snapToRoads?path=$path&interpolate=true&key=$_googleApiKey"
    );
    var snappedLineJsonObj = json.decode(response.body);
    SnappedLine sl = SnappedLine.fromJson(snappedLineJsonObj);
    return sl;
  }
}
