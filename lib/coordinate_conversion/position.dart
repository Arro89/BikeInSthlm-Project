enum Grid { RT90, WGS84, SWEREF99 }

///Position
abstract class Position {
  double latitude;
  double longitude;
  Grid gridFormat;

  Position(
      this.latitude,
      this.longitude,
      this.gridFormat,
      );

  //Eventuellt en andra konstruktor?
  //https://stackoverflow.com/questions/49691163/dart-multiple-constructors

  double getLatitude() {
    return this.latitude;
  }

  double getLongitude() {
    return this.longitude;
  }
}

