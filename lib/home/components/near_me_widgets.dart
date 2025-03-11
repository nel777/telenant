//create a stateless widget that accepts list of Map<String,dynamic> as data, and display data with gridview with button
import 'package:flutter/material.dart';
import 'package:telenant/home/viewmore.dart';
import 'package:telenant/models/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearMeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String searchLocation;
  final double distanceInKm;

  const NearMeWidget({
    super.key,
    required this.data,
    required this.searchLocation,
    required this.distanceInKm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Properties',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Within ${distanceInKm.toInt()}km of $searchLocation',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: data.isEmpty
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Properties Found Nearby',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try expanding your search radius\nor try a different location',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (BuildContext ctx, index) {
                final item = data[index]['data'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final String? docId = item['docId'] ?? data[index]['id'];
                      print("Debug - Document ID: $docId");
                      print("Debug - Full item data: $item");

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => ViewMore(
                                detail: Details(
                                  docId: docId,
                                  name: item['name'],
                                  gallery: item['gallery'] ?? [],
                                  location: item['location'],
                                  contact: item['contact'],
                                  type: item['type'],
                                  website: item['website'],
                                  managedBy: item['managedBy'],
                                  coverPage:
                                      item['coverPage'] ?? item['cover_page'],
                                  roomType:
                                      item['roomType'] ?? item['roomtype'],
                                  numberofbeds: item['numberofbeds'],
                                  numberofrooms: item['numberofrooms'],
                                  houseRules: item['houseRules'] != null
                                      ? List<String>.from(item['houseRules'])
                                      : (item['house_rules'] != null
                                          ? List<String>.from(
                                              item['house_rules'])
                                          : []),
                                  amenities: item['amenities'] != null
                                      ? List<String>.from(item['amenities'])
                                      : [],
                                  unavailableDates: item['unavailableDates'] !=
                                          null
                                      ? (item['unavailableDates'] as List)
                                          .map((date) {
                                            if (date is Map) {
                                              return DateTimeRange(
                                                start:
                                                    (date['start'] as Timestamp)
                                                        .toDate(),
                                                end: (date['end'] as Timestamp)
                                                    .toDate(),
                                              );
                                            }
                                            return null;
                                          })
                                          .whereType<DateTimeRange>()
                                          .toList()
                                      : [],
                                  priceRange: item['priceRange'] != null
                                      ? PriceRange.fromJson(item['priceRange'])
                                      : (item['price_range'] != null
                                          ? PriceRange.fromJson(
                                              item['price_range'])
                                          : null),
                                  locationLatLng: item['locationLatLng'] != null
                                      ? LocationLatLng.fromJson(
                                          item['locationLatLng'])
                                      : (item['location_latlng'] != null
                                          ? LocationLatLng.fromJson(
                                              item['location_latlng'])
                                          : null),
                                ),
                              )),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Image with Error Handling
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              item['cover_page'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 32,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Property Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'].toString(),
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['type'].toString(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['location'].toString(),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['contact'].toString(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
