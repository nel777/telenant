import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/viewmore.dart';

import '../authentication/login.dart';
import '../models/model.dart';

class ShowFiltered extends StatefulWidget {
  final Map<String, dynamic> filtered;
  const ShowFiltered({super.key, required this.filtered});

  @override
  State<ShowFiltered> createState() => _ShowFilteredState();
}

class _ShowFilteredState extends State<ShowFiltered>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _sortBy = 'price_asc'; // Default sorting
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];

    if (widget.filtered['location'] != null) {
      chips.add(_buildFilterChip('Location: ${widget.filtered['location']}'));
    }

    if (widget.filtered['type'] != null) {
      chips.add(_buildFilterChip(
          'Type: ${(widget.filtered['type'] as List).join(", ")}'));
    }

    if (widget.filtered['price'] != null) {
      chips.add(_buildFilterChip(
          'Price: ₱${widget.filtered['price']['min']} - ₱${widget.filtered['price']['max']}'));
    }

    if (widget.filtered['roomType'] != null) {
      chips.add(_buildFilterChip('Room: ${widget.filtered['roomType']}'));
    }

    return chips;
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: 12,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          'Search Results',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.logout, color: colorScheme.error),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        logout();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Applied Filters Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applied Filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildFilterChips()),
                ),
              ],
            ),
          ),

          // Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: [
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text('Price: Low to High',
                          style: TextStyle(color: colorScheme.onSurface)),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Price: High to Low',
                          style: TextStyle(color: colorScheme.onSurface)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestoreService.instance.readItems(),
              builder: ((context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                List<Details> filteredList = [];
                List<Details> similarList = [];

                for (final detail in snapshot.data!.docs) {
                  final data = detail.data() as Map<String, dynamic>;

                  final typeList = data['type'] is String
                      ? [data['type'].toString().toLowerCase()]
                      : (data['type'] as List<dynamic>?)
                              ?.map((e) => e.toString().toLowerCase())
                              .toList() ??
                          [];

                  final filteredTypeList =
                      (widget.filtered['type'] as List<dynamic>?)
                              ?.map((e) => e.toString().toLowerCase())
                              .toList() ??
                          [];
                  final matchesType =
                      typeList.any((type) => filteredTypeList.contains(type));

                  final matchesLocation =
                      data['location']?.toString().toLowerCase() ==
                          widget.filtered['location']?.toString().toLowerCase();
                  final matchesPrice = widget.filtered['price'] != null &&
                      data['price_range'] != null &&
                      data['price_range']['min'] != null &&
                      data['price_range']['max'] != null &&
                      ((widget.filtered['price']['min'] <=
                                  data['price_range']['max'] &&
                              widget.filtered['price']['min'] >=
                                  data['price_range']['min']) ||
                          (widget.filtered['price']['max'] >=
                              data['price_range']['min']));

                  final matchesRoomType =
                      data['roomType']?.toString().trim().toLowerCase() ==
                          widget.filtered['roomType']
                              ?.toString()
                              .trim()
                              .toLowerCase();
                  final matchesBeds = data['numberofbeds']?.toString() ==
                      widget.filtered['numberofbeds']?.toString();
                  final matchesRooms = data['numberofrooms']?.toString() ==
                      widget.filtered['numberofrooms']?.toString();

                  Details propertyDetails = Details(
                    docId: detail.id,
                    name: data['name'],
                    gallery: List<String>.from(data['gallery'] ?? []),
                    location: data['location'],
                    contact: data['contact'],
                    type: data['type'],
                    website: data['website'],
                    managedBy: data['managedBy'],
                    coverPage: data['coverPage'] ?? data['cover_page'],
                    priceRange: data['price_range'] != null
                        ? PriceRange(
                            min: data['price_range']['min'],
                            max: data['price_range']['max'])
                        : (data['priceRange'] != null
                            ? PriceRange(
                                min: data['priceRange']['min'],
                                max: data['priceRange']['max'])
                            : null),
                    roomType: data['roomType']?.toString() ??
                        data['room_type']?.toString() ??
                        '',
                    numberofbeds: data['numberofbeds']?.toString() ??
                        data['number_of_beds']?.toString() ??
                        '',
                    numberofrooms: data['numberofrooms']?.toString() ??
                        data['number_of_rooms']?.toString() ??
                        '',
                    unavailableDates: data['unavailableDates'] != null
                        ? (data['unavailableDates'] as List)
                            .map((date) {
                              if (date is Map) {
                                try {
                                  return DateTimeRange(
                                    start:
                                        (date['start'] as Timestamp).toDate(),
                                    end: (date['end'] as Timestamp).toDate(),
                                  );
                                } catch (e) {
                                  print('Error parsing date range: $e');
                                  return null;
                                }
                              }
                              return null;
                            })
                            .whereType<DateTimeRange>()
                            .toList()
                        : [],
                    houseRules: data['houseRules'] != null
                        ? List<String>.from(data['houseRules'])
                        : (data['house_rules'] != null
                            ? List<String>.from(data['house_rules'])
                            : []),
                    amenities: data['amenities'] != null
                        ? List<String>.from(data['amenities'])
                        : [],
                    locationLatLng: data['locationLatLng'] != null
                        ? LocationLatLng.fromJson(data['locationLatLng'])
                        : (data['location_latlng'] != null
                            ? LocationLatLng.fromJson(data['location_latlng'])
                            : null),
                  );

                  if (matchesLocation &&
                      matchesType &&
                      matchesPrice &&
                      matchesRoomType &&
                      matchesBeds &&
                      matchesRooms) {
                    filteredList.add(propertyDetails);
                  } else if (matchesRooms ||
                      matchesBeds ||
                      matchesRoomType ||
                      matchesPrice ||
                      matchesType ||
                      matchesLocation) {
                    similarList.add(propertyDetails);
                  }
                }

                // Sort the lists based on selected sorting option
                _sortLists(filteredList, similarList);

                return _buildResults(filteredList, similarList, colorScheme);
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _sortLists(List<Details> filteredList, List<Details> similarList) {
    sortFunction(Details a, Details b) {
      if (_sortBy == 'price_asc') {
        return (a.priceRange?.min ?? 0).compareTo(b.priceRange?.min ?? 0);
      } else {
        return (b.priceRange?.max ?? 0).compareTo(a.priceRange?.max ?? 0);
      }
    }

    filteredList.sort(sortFunction);
    similarList.sort(sortFunction);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Finding the perfect properties for you...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters to find more properties',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Details> filteredList, List<Details> similarList,
      ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exact Matches Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${filteredList.length} Exact ${filteredList.length == 1 ? 'Match' : 'Matches'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (filteredList.isEmpty)
              _buildNoResultsMessage()
            else
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredList.length,
                itemBuilder: (context, index) => _buildPropertyCard(
                  filteredList[index],
                  colorScheme,
                  isExactMatch: true,
                ),
              ),

            // Similar Properties Section
            if (similarList.isNotEmpty) ...[
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.recommend,
                        color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${similarList.length} Similar Properties',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                shrinkWrap: true,
                itemCount: similarList.length,
                itemBuilder: (context, index) => _buildPropertyCard(
                  similarList[index],
                  colorScheme,
                  isExactMatch: false,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'No exact matches found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your filters or check out similar properties below',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Details property, ColorScheme colorScheme,
      {required bool isExactMatch}) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 2,
            margin: EdgeInsets.all(isExactMatch ? 8 : 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewMore(
                      detail: property,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        Image.network(
                          property.coverPage.toString(),
                          height: isExactMatch ? 200 : 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: isExactMatch ? 200 : 140,
                              width: double.infinity,
                              color: colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: isExactMatch ? 200 : 140,
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        if (isExactMatch)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Perfect Match',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Property Details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isExactMatch) ...[
                          Text(
                            property.name ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.location ?? 'Unknown location',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isExactMatch) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.hotel,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${property.roomType} · ${property.numberofbeds} beds',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${property.priceRange?.min} - ₱${property.priceRange?.max}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: isExactMatch ? 16 : 14,
                              ),
                            ),
                            if (isExactMatch)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ViewMore(
                                        detail: property,
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 30),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ],
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
          ),
        );
      },
    );
  }
}
