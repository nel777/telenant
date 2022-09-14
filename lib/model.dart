// ignore: camel_case_types
class details {
  String? name;
  String? location;
  String? coverPage;
  int? bedrooms;
  PriceRange? priceRange;
  String? contact;
  String? type;
  String? website;

  details(
      {this.name,
      this.location,
      this.coverPage,
      this.bedrooms,
      this.priceRange,
      this.contact,
      this.type,
      this.website});

  details.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    location = json['location'];
    coverPage = json['cover_page'];
    bedrooms = json['bedrooms'];
    priceRange = (json['price_range'] != null
        ? PriceRange.fromJson(json['price_range'])
        : null)!;
    contact = json['contact'];
    type = json['type'];
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['location'] = location;
    data['cover_page'] = coverPage;
    data['bedrooms'] = bedrooms;
    if (priceRange != null) {
      data['price_range'] = priceRange!.toJson();
    }
    data['contact'] = contact;
    data['type'] = type;
    data['website'] = contact;
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
