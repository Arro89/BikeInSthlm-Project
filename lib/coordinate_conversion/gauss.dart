import "dart:math";

class GaussKreuger {
  final double pi = 3.1415926535897932;
  double axis;
  double flattening;
  double central_meridian;
  double scale;
  double false_northing;
  double false_easting;

  void swedish_params(String projection) {
    if (projection == "sweref_99_1800") {
      sweref99_params();
      central_meridian = 18.00;
    }
  }

  void sweref99_params() {
    axis = 6378137.0; // GRS 80.
    flattening = 1.0 / 298.257222101; // GRS 80.
    central_meridian = double.minPositive;
    scale = 1.0;
    false_northing = 0.0;
    false_easting = 150000.0;
  }

  List geodetic_to_grid(double latitude, double longitude) {
    //List x_y = [0, 1]; - skapar lista som nedan istället
    var x_y = new List(2);

    //Prepare ellipsoid-based stuff.
    double e2 = flattening * (2.0 - flattening);
    double n = flattening / (2.0 - flattening);
    double a_roof =
        axis / (1.0 + n) * (1.0 + n * n / 4.0 + n * n * n * n / 64.0);
    double A = e2;
    double B = (5.0 * e2 * e2 - e2 * e2 * e2) / 6.0;
    double C = (104.0 * e2 * e2 * e2 - 45.0 * e2 * e2 * e2 * e2) / 120.0;
    double D = (1237.0 * e2 * e2 * e2 * e2) / 1260.0;
    double beta1 = n / 2.0 -
        2.0 * n * n / 3.0 +
        5.0 * n * n * n / 16.0 +
        41.0 * n * n * n * n / 180.0;
    double beta2 = 13.0 * n * n / 48.0 -
        3.0 * n * n * n / 5.0 +
        557.0 * n * n * n * n / 1440.0;
    double beta3 = 61.0 * n * n * n / 240.0 - 103.0 * n * n * n * n / 140.0;
    double beta4 = 49561.0 * n * n * n * n / 161280.0;

    //Convert
    double deg_to_rad = pi / 180.0;
    double phi = latitude * deg_to_rad;
    double lambda = longitude * deg_to_rad;
    double lambda_zero = central_meridian * deg_to_rad;

    double phi_star = phi -
        sin(phi) *
            cos(phi) *
            (A +
                B * pow(sin(phi), 2) +
                C * pow(sin(phi), 4) +
                D * pow(sin(phi), 6));

    double delta_lambda = lambda - lambda_zero;
    double xi_prim = atan(tan(phi_star) / cos(delta_lambda));
    double eta_prim = math_atanh(cos(phi_star) * sin(delta_lambda));

    double x = scale *
        a_roof *
        (xi_prim +
            beta1 * sin(2.0 * xi_prim) * math_cosh(2.0 * eta_prim) +
            beta2 * sin(4.0 * xi_prim) * math_cosh(4.0 * eta_prim) +
            beta3 * sin(6.0 * xi_prim) * math_cosh(6.0 * eta_prim) +
            beta4 * sin(8.0 * xi_prim) * math_cosh(8.0 * eta_prim)) +
        false_northing;

    double y = scale *
        a_roof *
        (eta_prim +
            beta1 * cos(2.0 * xi_prim) * math_sinh(2.0 * eta_prim) +
            beta2 * cos(4.0 * xi_prim) * math_sinh(4.0 * eta_prim) +
            beta3 * cos(6.0 * xi_prim) * math_sinh(6.0 * eta_prim) +
            beta4 * cos(8.0 * xi_prim) * math_sinh(8.0 * eta_prim)) +
        false_easting;

    x_y[0] = ((x * 1000.0) / 1000.0).round();
    x_y[1] = ((y * 1000.0) / 1000.0).round();
    //x_y.add((((x * 1000.0) / 1000.0).round()));

    return x_y;
  }

  List grid_to_geodetic(double x, double y) {
    var lat_lon = new List(2);
    if (central_meridian == double.minPositive) {
      return lat_lon;
      print("PRINT $lat_lon");
    }

    //Prepare ellipsoid-based stuff
    double e2 = flattening * (2.0 - flattening);
    double n = flattening / (2.0 - flattening);
    double a_roof =
        axis / (1.0 + n) * (1.0 + n * n / 4.0 + n * n * n * n / 64.0);
    double delta1 = n / 2.0 -
        2.0 * n * n / 3.0 +
        37.0 * n * n * n / 96.0 -
        n * n * n * n / 360.0;
    double delta2 =
        n * n / 48.0 + n * n * n / 15.0 - 437.0 * n * n * n * n / 1440.0;
    double delta3 = 17.0 * n * n * n / 480.0 - 37 * n * n * n * n / 840.0;
    double delta4 = 4397.0 * n * n * n * n / 161280.0;

    double Astar = e2 + e2 * e2 + e2 * e2 * e2 + e2 * e2 * e2 * e2;
    double Bstar =
        -(7.0 * e2 * e2 + 17.0 * e2 * e2 * e2 + 30.0 * e2 * e2 * e2 * e2) / 6.0;
    double Cstar = (224.0 * e2 * e2 * e2 + 889.0 * e2 * e2 * e2 * e2) / 120.0;
    double Dstar = -(4279.0 * e2 * e2 * e2 * e2) / 1260.0;

    //Convert
    double deg_to_rad = pi / 180;
    double lambda_zero = central_meridian * deg_to_rad;
    double xi = (x - false_northing) / (scale * a_roof);
    double eta = (y - false_easting) / (scale * a_roof);
    double xi_prim = xi -
        delta1 * sin(2.0 * xi) * math_cosh(2.0 * eta) -
        delta2 * sin(4.0 * xi) * math_cosh(4.0 * eta) -
        delta3 * sin(6.0 * xi) * math_cosh(6.0 * eta) -
        delta4 * sin(8.0 * xi) * math_cosh(8.0 * eta);

    double eta_prim = eta -
        delta1 * cos(2.0 * xi) * math_sinh(2.0 * eta) -
        delta2 * cos(4.0 * xi) * math_sinh(4.0 * eta) -
        delta3 * cos(6.0 * xi) * math_sinh(6.0 * eta) -
        delta4 * cos(8.0 * xi) * math_sinh(8.0 * eta);

    double phi_star = asin(sin(xi_prim) / math_cosh(eta_prim));
    double delta_lambda = atan(math_sinh(eta_prim) / cos(xi_prim));
    double lon_radian = lambda_zero + delta_lambda;
    double lat_radian = phi_star + sin(phi_star) * cos(phi_star) *
        (Astar +
            Bstar * pow(sin(phi_star), 2) +
            Cstar * pow(sin(phi_star), 4) +
            Dstar * pow(sin(phi_star), 6));
    lat_lon[0] = lat_radian * 180.0 / pi;
    lat_lon[1] = lon_radian * 180.0 / pi;

    return lat_lon;
  }

  double math_sinh(double value) {
    return 0.5 * (exp(value) - exp(-value));
  }

  double math_cosh(double value) {
    return 0.5 * (exp(value) + exp(-value));
  }

  double math_atanh(double value) {
    return 0.5 * log((1.0 + value) / (1.0 - value));
  }
}

main() {
  var gauss = new GaussKreuger();
  gauss.swedish_params("sweref_99_1800");
  gauss.geodetic_to_grid(10, 10);
  gauss.grid_to_geodetic(10, 10);
}
