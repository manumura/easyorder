import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class LocationUtils {
  LocationUtils._();

  static Future<String?> getIsoCountryCode() async {
    final Logger logger = getLogger();

    final String? error = await _isLocationEnabled();
    if (error != null) {
      logger.e(error);
      return '';
    }

    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final List<Placemark> address =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    final Placemark placeMark = address.first;
    return placeMark.isoCountryCode;
  }

  static Future<String?> _isLocationEnabled() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future<String>.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future<String>.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future<String>.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return null;
  }
}
