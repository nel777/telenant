// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/admin/manageaccount.dart';
import 'package:telenant/models/model.dart';

import '../../authentication/login.dart';
import '../viewmore.dart';
import 'addtransient.dart';

class ViewTransient extends StatefulWidget {
  const ViewTransient({super.key});

  @override
  State<ViewTransient> createState() => _ViewTransientState();
}

class _ViewTransientState extends State<ViewTransient> {
  User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;

  Future<void> logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    // This is just to trigger the StreamBuilder to rebuild
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          'My Properties',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Account Settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ManageAccount()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _isLoading
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    logout();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestoreService.instance.readItems(),
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Handle error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading data',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Process data
            List<Details> listOfTransients = [];
            if (snapshot.hasData) {
              print('Current user email: ${user?.email}');
              for (final detail in snapshot.data!.docs) {
                final userEmail = user?.email?.trim().toLowerCase();
                final managedByEmail =
                    detail['managedBy']?.toString().trim().toLowerCase();

                if (userEmail != null && userEmail == managedByEmail) {
                  try {
                    // Safely get values with defaults
                    Map<String, dynamic> data =
                        detail.data() as Map<String, dynamic>;
                    print(
                        'Document ID: ${detail.id}, Fields: ${data.keys.toList()}');

                    // Safely access price_range
                    Map<String, dynamic> priceRange = {'min': 0, 'max': 0};
                    if (data.containsKey('price_range') &&
                        data['price_range'] != null) {
                      try {
                        priceRange =
                            data['price_range'] as Map<String, dynamic>;
                      } catch (e) {
                        print(
                            'Error processing price_range for ${data['name']}: $e');
                      }
                    }

                    // Safely handle lists
                    List<String> houseRules = [];
                    if (data.containsKey('house_rules') &&
                        data['house_rules'] != null) {
                      try {
                        houseRules = (data['house_rules'] as List<dynamic>)
                            .map((e) => e.toString())
                            .toList();
                      } catch (e) {
                        print(
                            'Error processing house_rules for ${data['name']}: $e');
                      }
                    }

                    List<String> amenities = [];
                    if (data.containsKey('amenities') &&
                        data['amenities'] != null) {
                      try {
                        amenities = (data['amenities'] as List<dynamic>)
                            .map((e) => e.toString())
                            .toList();
                      } catch (e) {
                        print(
                            'Error processing amenities for ${data['name']}: $e');
                      }
                    }

                    // Handle gallery safely
                    List<dynamic> gallery = [];
                    if (data.containsKey('gallery') &&
                        data['gallery'] != null) {
                      try {
                        gallery = data['gallery'] as List<dynamic>;
                      } catch (e) {
                        print(
                            'Error processing gallery for ${data['name']}: $e');
                      }
                    }

                    // Handle unavailable dates safely
                    List<DateTimeRange> unavailableDates = [];
                    if (data.containsKey('unavailableDates') &&
                        data['unavailableDates'] != null) {
                      try {
                        unavailableDates =
                            (data['unavailableDates'] as List<dynamic>)
                                .map((e) => DateTimeRange(
                                      start: (e['start'] as Timestamp).toDate(),
                                      end: (e['end'] as Timestamp).toDate(),
                                    ))
                                .toList();
                      } catch (e) {
                        print(
                            'Error processing unavailable dates for ${data['name']}: $e');
                      }
                    }

                    // For cover_page, if it doesn't exist, try to use the first gallery image
                    String coverPage = '';
                    if (data.containsKey('cover_page') &&
                        data['cover_page'] != null) {
                      coverPage = data['cover_page'].toString();
                    } else if (gallery.isNotEmpty) {
                      coverPage = gallery[0].toString();
                      print(
                          'Using first gallery image as cover for ${data['name']}');
                    } else {
                      print('No cover page available for ${data['name']}');
                    }

                    listOfTransients.add(Details(
                      name: data.containsKey('name')
                          ? data['name']?.toString() ?? 'Unnamed Property'
                          : 'Unnamed Property',
                      location: data.containsKey('location')
                          ? data['location']?.toString() ?? 'No Location'
                          : 'No Location',
                      contact: data.containsKey('contact')
                          ? data['contact']?.toString() ?? 'No Contact'
                          : 'No Contact',
                      website: data.containsKey('website')
                          ? data['website']?.toString() ?? ''
                          : '',
                      type: data.containsKey('type')
                          ? data['type']?.toString() ?? 'Unknown Type'
                          : 'Unknown Type',
                      managedBy: data.containsKey('managedBy')
                          ? data['managedBy']?.toString() ?? ''
                          : '',
                      priceRange: PriceRange(
                        min: priceRange['min'] ?? 0,
                        max: priceRange['max'] ?? 0,
                      ),
                      coverPage: coverPage,
                      gallery: gallery,
                      roomType: data.containsKey('roomType')
                          ? data['roomType']?.toString() ?? ''
                          : '',
                      numberofbeds: data.containsKey('numberofbeds')
                          ? data['numberofbeds']?.toString() ?? '0'
                          : '0',
                      numberofrooms: data.containsKey('numberofrooms')
                          ? data['numberofrooms']?.toString() ?? '0'
                          : '0',
                      unavailableDates: unavailableDates,
                      houseRules: houseRules,
                      amenities: amenities,
                      docId: detail.id,
                    ));
                    print(
                        'Successfully processed property: ${data.containsKey('name') ? data['name'] : 'Unnamed'} (ID: ${detail.id})');
                  } catch (e, stackTrace) {
                    print('Error processing document: $e');
                    print('Stack trace: $stackTrace');
                  }
                }
              }
              print('Total properties in list: ${listOfTransients.length}');
            }

            // Empty state
            if (listOfTransients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 80,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No properties yet',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first property by tapping the button below',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const AddTransient()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Property'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Display list of properties
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listOfTransients.length,
              itemBuilder: (context, index) {
                final property = listOfTransients[index];
                return _buildPropertyCard(context, property);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddTransient()));
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        tooltip: 'Add new property',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, Details property) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ViewMore(
                docId: property.docId,
                detail: property,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                // Property image
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Hero(
                    tag: 'property_${property.docId ?? "unknown"}',
                    child: Image.network(
                      property.coverPage.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Property type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.type.toString(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Room type badge
                if (property.roomType != null && property.roomType!.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        property.roomType
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Delete button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDeleteConfirmation(context, property),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: colorScheme.onError,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Property details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property name
                  Text(
                    property.name.toString(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location.toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price range and details
                  Row(
                    children: [
                      // Price range
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: property.priceRange != null
                                    ? '₱${property.priceRange!.min} - ₱${property.priceRange!.max}'
                                    : 'Price not set',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: property.priceRange != null
                                    ? ' / night'
                                    : '',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // View details button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ViewMore(
                                docId: property.docId,
                                detail: property,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
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
  }

  void _showDeleteConfirmation(BuildContext context, Details property) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this property?'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (property.docId != null) {
                FirebaseFirestoreService.instance
                    .deleteDocument(docId: property.docId!)
                    .then((value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value['message']),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                });
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}
