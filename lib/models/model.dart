// ignore: camel_case_types
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Details {
  String? name;
  String? location;
  String? coverPage;
  PriceRange? priceRange;
  LocationLatLng? locationLatLng;
  List<dynamic>? gallery;
  String? contact;
  String? type;
  String? website;
  String? managedBy;
  String? docId;
  String? roomType;
  String? numberofbeds;
  String? numberofrooms;
  List<String>? houseRules;
  List<String>? amenities;
  List<DateTimeRange>? unavailableDates;

  Details({
    this.name,
    this.location,
    this.coverPage,
    this.priceRange,
    this.locationLatLng,
    this.gallery,
    this.contact,
    this.type,
    this.managedBy,
    this.website,
    this.docId,
    this.roomType,
    this.numberofbeds,
    this.numberofrooms,
    this.houseRules,
    this.amenities,
    this.unavailableDates,
  });

  Details.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    location = json['location'];
    coverPage = json['coverPage'] ?? json['cover_page'];
    priceRange = json['priceRange'] != null
        ? PriceRange.fromJson(json['priceRange'])
        : (json['price_range'] != null
            ? PriceRange.fromJson(json['price_range'])
            : null);
    locationLatLng = json['locationLatLng'] != null
        ? LocationLatLng.fromJson(json['locationLatLng'])
        : (json['location_latlng'] != null
            ? LocationLatLng.fromJson(json['location_latlng'])
            : null);
    gallery = json['gallery'] ?? [];
    contact = json['contact'];
    type = json['type'];
    website = json['website'];
    managedBy = json['managedBy'];
    docId = json['docId'];
    roomType = json['roomType'] ?? json['roomtype'];
    numberofbeds = json['numberofbeds'];
    numberofrooms = json['numberofrooms'];
    houseRules = json['houseRules'] != null
        ? List<String>.from(json['houseRules'])
        : (json['house_rules'] != null
            ? List<String>.from(json['house_rules'])
            : []);
    amenities =
        json['amenities'] != null ? List<String>.from(json['amenities']) : [];
    try {
      unavailableDates = json['unavailableDates'] != null
          ? (json['unavailableDates'] as List)
              .map((date) {
                if (date is Map) {
                  return DateTimeRange(
                    start: (date['start'] as Timestamp).toDate(),
                    end: (date['end'] as Timestamp).toDate(),
                  );
                }
                return null;
              })
              .whereType<DateTimeRange>()
              .toList()
          : [];
    } catch (e) {
      print('Error parsing unavailableDates: $e');
      unavailableDates = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['location'] = location;
    data['coverPage'] = coverPage;
    if (priceRange != null) {
      data['priceRange'] = priceRange!.toJson();
    }
    if (locationLatLng != null) {
      data['locationLatLng'] = locationLatLng!.toJson();
    }
    data['gallery'] = gallery ?? [];
    data['contact'] = contact;
    data['type'] = type;
    data['managedBy'] = managedBy;
    data['website'] = website;
    data['roomType'] = roomType;
    data['numberofbeds'] = numberofbeds;
    data['numberofrooms'] = numberofrooms;
    data['docId'] = docId;
    data['houseRules'] = houseRules ?? [];
    data['amenities'] = amenities ?? [];
    if (unavailableDates != null && unavailableDates!.isNotEmpty) {
      data['unavailableDates'] = unavailableDates!
          .map((date) => {
                'start': Timestamp.fromDate(date.start),
                'end': Timestamp.fromDate(date.end),
              })
          .toList();
    } else {
      data['unavailableDates'] = [];
    }
    return data;
  }
}

class PriceRange {
  int? min;
  int? max;

  PriceRange({this.min, this.max});

  PriceRange.fromJson(Map<String, dynamic> json) {
    min = json['min'];
    max = json['max'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min'] = min;
    data['max'] = max;
    return data;
  }
}

class LocationLatLng {
  double? latitude;
  double? longitude;

  LocationLatLng({this.latitude, this.longitude});

  LocationLatLng.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}
