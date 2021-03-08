import 'gauss.dart';
import 'position.dart';
import 'WGS84Position.dart';

enum SWEREFProjection { sweref_99_18_00 }

///SWEREF99Position
class SWEREF99Position extends Position {
  SWEREFProjection projection;

  //Main constructor?
  SWEREF99Position(double n, double e) : super(n, e, Grid.SWEREF99) {
    this.projection = SWEREFProjection.sweref_99_18_00;
  }

  WGS84Position toWGS84(){
    GaussKreuger gkProjection = new GaussKreuger();
    gkProjection.swedish_params(getProjectionString2(this.projection));
    List lat_lon = gkProjection.grid_to_geodetic(this.latitude, this.longitude);

    var newPos = new WGS84Position(lat_lon[0], lat_lon[1]);

    return newPos;
  }


  String getProjectionString(){
    return getProjectionString2(this.projection);
  }

  String getProjectionString2(SWEREFProjection projection){
    String retVal;
    switch (projection){
      case SWEREFProjection.sweref_99_18_00:
        retVal = "sweref_99_1800";
        break;
      default:
        retVal = "sweref_99_1800";
        break;
    }
    return retVal;
  }

  //Lat - long - getProjectionString
  @override
  String toString(){
    return "N: ${latitude.toStringAsFixed(1)} E: ${longitude.toStringAsFixed(1)} "
        "Projection: ${getProjectionString()}";
  }
}