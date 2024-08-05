import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:telenant/FirebaseServices/services.dart';

Future<List<Map<String, dynamic>>> findNearbyApartments(
    LocationData userPosition, double maxDistanceInMeters) async {
  List<DocumentSnapshot> apartments =
      await FirebaseFirestoreService.instance.getApartmentsFromFirestore();
  List<Map<String, dynamic>> nearbyApartments = [];
  print(userPosition.latitude);
  print(userPosition.longitude);
  for (var doc in apartments) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> apartmentLocation =
        data['location_latlng'] ?? {'latitude': 0.0, 'longitude': 0.0};
    double distance = Geolocator.distanceBetween(
      userPosition.latitude!,
      userPosition.longitude!,
      apartmentLocation['latitude'],
      apartmentLocation['longitude'],
    );

    print('Distance: $distance');

    if (distance <= maxDistanceInMeters) {
      nearbyApartments.add({
        'id': doc.id,
        'data': data,
        'distance': distance,
      });
    }
  }

  return nearbyApartments;
}
