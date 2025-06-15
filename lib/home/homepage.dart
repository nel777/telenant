import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as location_service;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/authentication/login.dart';
import 'package:telenant/home/admin/addtransient.dart';
import 'package:telenant/home/components/near_me_widgets.dart';
import 'package:telenant/home/filtered.dart';
import 'package:telenant/home/searchbox.dart';
import 'package:telenant/utils/filter_transients.dart';
import 'package:textfield_search/textfield_search.dart';
import 'dart:async';
import 'dart:io';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedValue = 'Near Town';
  int min = 200;
  int max = 10000;
  int currentPageIndex = 0;
  IconLabel? selectedIcon;
  late Future<List<Map<String, dynamic>>> _nearbyApartments;
  List propertyTypes = [];
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomBedsController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  List<String> listOfPriceValue = [
    '200',
    '300',
    '400',
    '500',
    '1000',
    '2000',
    '3000',
    '5000',
    '10000'
  ];
  late TextEditingController searchController;
  bool fetchingLocation = false;
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  bool _isSearching = false;
  List<String> _filteredLocations = [];

  List<PropertyType> propertyTypeList = [
    PropertyType(
      type: 'Townhouse',
      asset: 'assets/images/townhouse.png',
    ),
    PropertyType(
      type: 'Apartment',
      asset: 'assets/images/apartment.png',
    ),
  ];

  // Cache for location coordinates
  final Map<String, location_service.LocationData> _locationCache = {};
  final location_service.Location _location = location_service.Location();

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.initialIndex;
    searchController = TextEditingController();
    _locationController.text = _selectedValue;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  Future<location_service.LocationData> _getLocationFromAddress(
      String address) async {
    // Check cache first
    if (_locationCache.containsKey(address)) {
      return _locationCache[address]!;
    }

    try {
      // Get coordinates from address
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Could not find coordinates for $address');
      }

      // Convert to LocationData
      final locationData = location_service.LocationData.fromMap({
        'latitude': locations.first.latitude,
        'longitude': locations.first.longitude,
        'accuracy': 0,
        'altitude': 0,
        'speed': 0,
        'speed_accuracy': 0,
        'heading': 0,
        'time': DateTime.now().millisecondsSinceEpoch,
        'is_mock': false,
        'vertical_accuracy': 0,
        'heading_accuracy': 0,
        'elapsed_real_time_nanos': 0,
        'elapsed_real_time_uncertainty_nanos': 0,
      });

      // Cache the result
      _locationCache[address] = locationData;
      return locationData;
    } catch (e) {
      throw Exception(
          'Failed to get coordinates for $address: ${e.toString()}');
    }
  }

  Future<void> _fetchNearbyApartments(
      location_service.LocationData deviceLocation) async {
    const double searchRadiusInKm = 100.0;

    try {
      setState(() {
        fetchingLocation = true;
      });

      // Get search location based on selection
      location_service.LocationData searchLocation;
      if (_selectedValue == 'Near Town') {
        searchLocation = deviceLocation;
      } else {
        try {
          searchLocation = await _getLocationFromAddress(_selectedValue);
        } catch (e) {
          debugPrint('Error getting coordinates for $_selectedValue: $e');
          // Fallback to device location with a warning
          searchLocation = deviceLocation;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Could not find coordinates for $_selectedValue, using current location instead.'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // Convert km to meters for the search radius
      final nearbyApartments = await findNearbyApartments(
        searchLocation,
        searchRadiusInKm * 1000,
      );

      if (!mounted) return;

      // Get human-readable address for device location if using "Near Town"
      String displayLocation = _selectedValue;
      if (_selectedValue == 'Near Town') {
        try {
          final placemarks = await placemarkFromCoordinates(
            deviceLocation.latitude!,
            deviceLocation.longitude!,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            displayLocation =
                '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
                    .trim();
            if (displayLocation.isEmpty) {
              displayLocation = 'Current Location';
            }
          }
        } catch (e) {
          debugPrint('Error getting address from coordinates: $e');
          displayLocation = 'Current Location';
        }
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NearMeWidget(
            data: nearbyApartments,
            searchLocation: displayLocation,
            distanceInKm: searchRadiusInKm,
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getErrorMessage(e)),
              if (e is Exception) ...[
                const SizedBox(height: 8),
                Text(
                  'Please try again or contact support if the problem persists.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => _retryFetchNearbyApartments(deviceLocation),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

      debugPrint('Error fetching nearby apartments: $e\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          fetchingLocation = false;
        });
      }
    }
  }

  // Update error messages to include geocoding errors
  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet connection.';
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is LocationServiceDisabledException) {
      return 'Location services are disabled. Please enable location services.';
    } else if (error is LocationPermissionDeniedException) {
      return 'Location permission denied. Please enable location permissions in settings.';
    } else if (error.toString().contains('Could not find coordinates')) {
      return 'Could not find the selected location. Please try a different location.';
    } else {
      return 'An unexpected error occurred while fetching nearby apartments.';
    }
  }

  Future<void> _retryFetchNearbyApartments(
      location_service.LocationData location) async {
    Navigator.of(context).pop(); // Close error dialog
    await _fetchNearbyApartments(location);
  }

  // Location handling methods
  Future<location_service.LocationData?> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw LocationServiceDisabledException();
        }
      }

      // Check location permission
      var permissionGranted = await _location.hasPermission();
      if (permissionGranted == location_service.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != location_service.PermissionStatus.granted) {
          throw LocationPermissionDeniedException();
        }
      }

      // Get location
      return await _location.getLocation();
    } catch (e) {
      if (e is LocationServiceDisabledException) {
        throw LocationServiceDisabledException();
      } else if (e is LocationPermissionDeniedException) {
        throw LocationPermissionDeniedException();
      } else {
        throw Exception('Failed to get location: ${e.toString()}');
      }
    }
  }

  Future<void> _handleNearbySearch() async {
    if (mounted) {
      setState(() {
        fetchingLocation = true;
      });
    }

    try {
      final locationData = await _getCurrentLocation();
      if (locationData == null) {
        throw Exception('Could not retrieve location data');
      }

      if (!mounted) return;

      await _fetchNearbyApartments(locationData);
    } catch (e) {
      if (!mounted) return;

      String message;
      if (e is LocationServiceDisabledException) {
        message = 'Please enable location services to use this feature.';
      } else if (e is LocationPermissionDeniedException) {
        message = 'Location permission is required to use this feature.';
      } else {
        message = 'An error occurred while getting your location.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _handleNearbySearch,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          fetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: ((context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Logout',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                );
              }),
            );
          },
          icon: Icon(Icons.logout_rounded, color: colorScheme.primary),
        ),
        title: Text(
          'Telenant',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (index == 1) {
              _selectedValue = 'Near Town';
            }
          });
          if (index == 0) {
            searchController = TextEditingController();
          }
        },
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.home_rounded, color: colorScheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded,
                color: colorScheme.onSurface),
            selectedIcon:
                Icon(Icons.person_rounded, color: colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
      body: currentPageIndex == 0 ? homeWidget() : profileWidget(),
    );
  }

  //a column of profile page that displays id number and email, reading from the function readUserDetails
  Padding profileWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestoreService.instance
                .getUserDetails(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              // Assuming this code is inside a Builder or StreamBuilder/FutureBuilder's builder method
// and `snapshot` is the AsyncSnapshot<DocumentSnapshot> (or similar type).

// You also need access to colorScheme and textTheme, assuming they are defined elsewhere in your widget
// For example:
// final ColorScheme colorScheme = Theme.of(context).colorScheme;
// final TextTheme textTheme = Theme.of(context).textTheme;


if (snapshot.hasData) {
  // Check if snapshot.data is null (which it shouldn't be if hasData is true,
  // but defensive programming is good) AND if its .data() method returns a Map.
  // snapshot.data itself is a DocumentSnapshot or similar.
  // We need to check the result of snapshot.data!.data()
  final dynamic rawData = snapshot.data!.data(); // Get the raw data from the DocumentSnapshot

  // Ensure rawData is not null AND is actually a Map<String, dynamic>
  if (rawData != null && rawData is Map<String, dynamic>) {
    Map<String, dynamic> data = rawData; // Safely assign after checking its type

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'ID Number',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    // Use null-aware operator for map access as well
                    // This prevents errors if 'idNumber' key is missing
                    data['idNumber']?.toString() ?? 'Not specified',
                    style: textTheme.titleMedium,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'Email',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    // Use null-aware operator for map access as well
                    // This prevents errors if 'email' key is missing
                    data['email']?.toString() ?? 'Not specified',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } else {
    // This block handles cases where snapshot.hasData is true,
    // but the actual data payload (from .data()) is null or not a Map.
    print('Warning: Document data is null or not in expected Map format.');
    return Center(child: Text('Document data not found or is empty.'));
    // You can return a different widget here, e.g., a message indicating no data
  }
} else if (snapshot.hasError) {
  // Handle error state
  return Center(child: Text('Error: ${snapshot.error}'));
} else {
  // Handle loading state (no data yet)
  return const Center(child: CircularProgressIndicator());
}
            },
          ),
          const SizedBox(height: 32),
          Text(
            'My Bookings',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transientDetails')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading bookings',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userBookings = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final unavailableDates = data['unavailableDates'] as List?;
                  if (unavailableDates == null) return false;

                  return unavailableDates.any((date) =>
                      date is Map &&
                      date['bookedBy'] ==
                          FirebaseAuth.instance.currentUser?.email);
                }).toList();

                if (userBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings yet',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your booked properties will appear here',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userBookings.length,
                  itemBuilder: (context, index) {
                    final doc = userBookings[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final unavailableDates = data['unavailableDates'] as List;
                    final bookingDates = unavailableDates
                        .where((date) =>
                            date is Map &&
                            date['bookedBy'] ==
                                FirebaseAuth.instance.currentUser?.email)
                        .toList();

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown Property',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['location'] ?? 'Unknown Location',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['type']?.toString().toUpperCase() ??
                                        'N/A',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Booked Dates:',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...bookingDates.map((booking) {
                              final start =
                                  (booking['start'] as Timestamp).toDate();
                              final end =
                                  (booking['end'] as Timestamp).toDate();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SingleChildScrollView homeWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestoreService.instance.readItems(),
          builder: ((context, snapshot) {
            List<String> listOfValue = ['Near Town'];
            List<String> listOfTransient = [];

            if (snapshot.hasData) {
              for (final detail in snapshot.data!.docs) {
                if (!listOfValue.contains(detail['location'])) {
                  listOfValue.add(detail['location']);
                }
                listOfTransient.add(detail['name']);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => Material(
                                child: SearchDemo(data: listOfTransient),
                              )),
                        ),
                      );
                    },
                    child: TextFieldSearch(
                      label: 'Search',
                      controller: searchController,
                      initialList: listOfTransient,
                      decoration: InputDecoration(
                        enabled: false,
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'Search for accommodations...',
                        hintStyle: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                      ),
                    ),
                  ),
                ),

                // Location Selector
                Text(
                  'Location',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchableLocationDropdown(
                    listOfValue, colorScheme, textTheme),
                const SizedBox(height: 24),

                // Near Me Button
                _buildNearMeButton(),
                const SizedBox(height: 32),

                // Property Types Section
                Text(
                  'Property Types',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: propertyTypeList.length,
                    itemBuilder: (context, index) {
                      final type = propertyTypeList[index];
                      final isSelected = propertyTypes.contains(type.type);

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                propertyTypes.remove(type.type);
                              } else {
                                propertyTypes.add(type.type);
                              }
                            });
                          },
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest
                                      .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    type.asset,
                                    height: 100,
                                    width: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  type.type,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Room Details Section
                Text(
                  'Room Details',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownMenu<IconLabel>(
                              controller: _roomTypeController,
                              enableFilter: false,
                              leadingIcon: selectedIcon == null
                                  ? null
                                  : Icon(
                                      selectedIcon!.icon,
                                      color: colorScheme.primary,
                                    ),
                              label: const Text('Room Type'),
                              onSelected: (IconLabel? icon) {
                                setState(() {
                                  selectedIcon = icon;
                                });
                              },
                              dropdownMenuEntries: IconLabel.entries,
                              width: MediaQuery.of(context).size.width * 0.55,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (IconLabel.allValues.indexOf(
                                  selectedIcon ?? IconLabel.allValues.first) >
                              2)
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _roomBedsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  labelText: '# of Beds',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.bed_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: '# of Rooms',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.meeting_room_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Price Range Section
                Text(
                  'Price Range Per Head',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField(
                                value: min.toString(),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '₱',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                items: listOfPriceValue.map((String val) {
                                  return DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    min = int.parse(value.toString());
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '-',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField(
                                value: max.toString(),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '₱',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                items: listOfPriceValue.map((String val) {
                                  return DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    max = int.parse(value.toString());
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        Map<String, int> pricerange = {
                          'min': min,
                          'max': max,
                        };
                        Map<String, dynamic> filtered = {
                          'type': propertyTypes,
                          'location': _selectedValue,
                          'price': pricerange,
                          'numberofbeds': _roomBedsController.text,
                          'numberofrooms': _roomNumberController.text,
                          'roomType':
                              selectedIcon!.label.toString().toLowerCase(),
                        };
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: ((context) => ShowFiltered(
                                  filtered: filtered,
                                )),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please fill in all fields'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Card cardPropertyType(BuildContext context, String type, String asset) {
    return Card(
      shape: OutlineInputBorder(
          borderSide: BorderSide(
              width: 3.0,
              style: propertyTypes.contains(type)
                  ? BorderStyle.solid
                  : BorderStyle.none,
              color: Theme.of(context).colorScheme.primary)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              // width: 100,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
              ),
            ),
            const Divider(),
            Text(
              type,
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
      ),
    );
  }

  Padding propertyType(IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (type == 'Apartment') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Townhouse') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Hotel') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                }
              }
            },
            child: Card(
              elevation: 5.0,
              shape: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 3.0,
                      style: propertyTypes.contains(type)
                          ? BorderStyle.solid
                          : BorderStyle.none,
                      color: Colors.blue)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          Text(type)
        ],
      ),
    );
  }

  // Update the Near Me button text based on selected location
  Widget _buildNearMeButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: fetchingLocation
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedValue == 'Near Town'
                      ? 'Fetching Current Location'
                      : 'Finding Properties Near $_selectedValue',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: _handleNearbySearch,
              icon: Icon(_selectedValue == 'Near Town'
                  ? Icons.my_location_rounded
                  : Icons.location_on_rounded),
              label: Text(
                _selectedValue == 'Near Town'
                    ? 'Find Near Me'
                    : 'Find Near $_selectedValue',
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.of(context).size.width * 0.8, 50),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }

  // Add this new widget for searchable location dropdown
  Widget _buildSearchableLocationDropdown(
      List<String> locations, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            onTap: () {
              setState(() {
                _isSearching = true;
                _filteredLocations = locations;
              });
            },
            onChanged: (value) {
              setState(() {
                _filteredLocations = locations
                    .where((location) =>
                        location.toLowerCase().contains(value.toLowerCase()))
                    .toList();
              });
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _locationController.text = _selectedValue;
                          _locationFocusNode.unfocus();
                        });
                      },
                    )
                  : Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.primary,
                    ),
              hintText: 'Search location...',
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                return ListTile(
                  title: Text(
                    location,
                    style: textTheme.bodyLarge,
                  ),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: location == _selectedValue
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  selected: location == _selectedValue,
                  selectedTileColor:
                      colorScheme.primaryContainer.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedValue = location;
                      _locationController.text = location;
                      _isSearching = false;
                      _locationFocusNode.unfocus();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class PropertyType {
  final String type;
  final String asset;

  PropertyType({required this.type, required this.asset});
}

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}
