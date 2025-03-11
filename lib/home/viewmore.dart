import 'dart:io';
import 'dart:async';

import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/components/table_calendar.dart';
import 'package:telenant/models/chatmodel.dart';
// import 'package:telenant/home/rate.dart';
import 'package:telenant/models/model.dart';
import 'package:telenant/home/homepage.dart';

import '../chatmessaging/chatscreen.dart';

class ViewMore extends StatefulWidget {
  final Details detail;
  final String? docId;

  const ViewMore({super.key, required this.detail, this.docId});

  @override
  State<ViewMore> createState() => _ViewMoreState();
}

class _ViewMoreState extends State<ViewMore> {
  User? user = FirebaseAuth.instance.currentUser;
  List<dynamic>? albums = [];
  String? coverPage;
  ImagePicker picker = ImagePicker();
  bool hasReviews = false;
  DateTimeRange? selectedDates;
  bool isLoading = false;
  int _currentImageIndex = 0;
  late PageController _pageController;
  Timer? _autoPlayTimer;

  Future<String> uploadFile(File image) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${user!.email.toString()}/${image.path.split('/').last}');
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask;
    return await storageReference.getDownloadURL();
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    setState(() {
      // Handle cover page
      coverPage = widget.detail.coverPage;
      if (coverPage == "") {
        coverPage = null;
      }

      // Handle gallery images
      albums = [];
      if (widget.detail.gallery != null && widget.detail.gallery!.isNotEmpty) {
        albums = widget.detail.gallery!
            .where((url) => url != null && url.toString().isNotEmpty)
            .map((url) => url.toString())
            .where((url) {
          try {
            final uri = Uri.parse(url);
            return uri.hasScheme &&
                (uri.scheme == 'http' || uri.scheme == 'https');
          } catch (e) {
            debugPrint('Invalid gallery URL: $url - ${e.toString()}');
            return false;
          }
        }).toList();
      }
    });
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final validImages = _getValidImages();
        if (validImages.isEmpty) return;

        final nextPage = (_currentImageIndex + 1) % validImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<String> _getValidImages() {
    bool isValidUrl(String? url) {
      if (url == null || url.isEmpty) return false;
      try {
        final uri = Uri.parse(url);
        return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
      } catch (e) {
        debugPrint('Invalid URL in _getValidImages: $url - ${e.toString()}');
        return false;
      }
    }

    final List<String> validImages = [];

    // First check if we have valid gallery images
    if (albums != null && albums!.isNotEmpty) {
      for (var imageUrl in albums!) {
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final urlString = imageUrl.toString();
          if (isValidUrl(urlString)) {
            validImages.add(urlString);
          }
        }
      }
    }

    // If no valid gallery images, try to use cover page as fallback
    if (validImages.isEmpty && coverPage != null && coverPage!.isNotEmpty) {
      if (isValidUrl(coverPage)) {
        validImages.add(coverPage!);
      }
    }

    return validImages;
  }

  IconData getAmenityIcon(String amenity) {
    const Map<String, IconData> amenityIcons = {
      'cleaning products': Icons.cleaning_services_rounded,
      'clothing storage (closet)': Icons.checkroom_rounded,
      'ethernet connection': Icons.cable_rounded,
      'tv': Icons.tv_rounded,
      'wifi': Icons.wifi,
      'hot water': Icons.hot_tub_rounded,
      'extra towel': Icons.dry_cleaning_rounded,
      'extra pillow and blanket': Icons.bed_rounded,
    };
    return amenityIcons[amenity] ?? Icons.help_outline;
  }

  displayWarningAlert() {
    return showDialog(
        context: context,
        builder: (confirmDialog) {
          return StatefulBuilder(builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Make this Unavailable?'),
              content: const Text(
                  'Are you sure you want to make this dates unavailable?'),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    setDialogState(() {
                      isLoading = true;
                    });
                    Map<String, dynamic> convertedDate = {
                      "start": Timestamp.fromDate(selectedDates!.start),
                      "end": Timestamp.fromDate(selectedDates!.end),
                    };

                    try {
                      await FirebaseFirestore.instance
                          .collection("transientDetails")
                          .doc(widget.docId)
                          .update({
                        "unavailableDates":
                            FieldValue.arrayUnion([convertedDate])
                      });
                    } catch (e) {
                      print(e.toString());
                    }
                    setDialogState(() {
                      isLoading = false;
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  label: isLoading
                      ? const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator())
                      : const Text(
                          'Yes',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          });
        });
  }

  alreadyScheduledAlert() {
    return showDialog(
        context: context,
        builder: (scheduledAlert) {
          return AlertDialog(
            icon: const Icon(
              Icons.warning_rounded,
              size: 60,
            ),
            title: const Text('Not Available'),
            content: const Text(
              'Please select another date. This date is already scheduled.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ok'))
            ],
          );
        });
  }

  bookScheduleAlert() {
    showDialog(
        context: context,
        builder: (bookScheduleContext) {
          return StatefulBuilder(builder: (context, setDialogState) {
            final message =
                'Yes, I would like to book this place on ${selectedDates!.start.month}/${selectedDates!.start.day}/${selectedDates!.start.year} to ${selectedDates!.end.month}/${selectedDates!.end.day}/${selectedDates!.end.year}';
            return AlertDialog(
              title: const Text('Date Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Are you sure you want to book this date?',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(message),
                  const SizedBox(height: 10),
                  Text(
                    'Note: This will send a message to the host.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close the alert dialog
                    // _showBookingDialog(
                    //     context); // Show the final booking dialog
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.detail.managedBy == user?.email)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
              ),
              onPressed: () => _showEditDialog(context),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Image Section
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: Builder(
                    builder: (context) {
                      final validImages = _getValidImages();

                      if (validImages.isEmpty) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          height: 300,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_rounded,
                                color: colorScheme.primary,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No images available',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (widget.detail.managedBy == user?.email)
                                Text(
                                  'Tap the camera icon below to add images',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: validImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            height: 300,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                validImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      'Image error for URL ${validImages[index]}: $error');
                                  return Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          color: colorScheme.error,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Image not available',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.w500,
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
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Loading image...',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                cacheWidth: 800,
                                frameBuilder: (context, child, frame,
                                    wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Image counter indicator
                if (_getValidImages().isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_getValidImages().length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                // Edit cover image button for admin
                if (widget.detail.managedBy == user?.email)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: IconButton.filledTonal(
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => _updateCoverImage(),
                    ),
                  ),
              ],
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Title and Type
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.detail.name.toString(),
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                                widget.detail.type.toString().toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Location
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
                                widget.detail.location.toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price Range Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price per night',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (widget.detail.priceRange?.min != null &&
                                      widget.detail.priceRange?.max != null)
                                    Text(
                                      '₱${widget.detail.priceRange?.min} - ₱${widget.detail.priceRange?.max}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Price not specified',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Calendar Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Availability Calendar',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (calendarContext) {
                                        return CalendarWithUnavailableDates(
                                          unavailableDates:
                                              widget.detail.unavailableDates ??
                                                  [],
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.calendar_month),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_available,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Check available dates',
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selectedDates != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 20,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Selected: ${selectedDates!.start.month}/${selectedDates!.start.day}/${selectedDates!.start.year} - ${selectedDates!.end.month}/${selectedDates!.end.day}/${selectedDates!.end.year}',
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: widget.detail.managedBy ==
                                                user?.email
                                            ? () async {
                                                final closeThisDate =
                                                    await showDateRangePicker(
                                                  context: context,
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (closeThisDate != null) {
                                                  setState(() {
                                                    selectedDates =
                                                        closeThisDate;
                                                  });
                                                  displayWarningAlert();
                                                }
                                              }
                                            : () async {
                                                final closeThisDate =
                                                    await showDateRangePicker(
                                                  context: context,
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (closeThisDate != null) {
                                                  setState(() {
                                                    selectedDates =
                                                        closeThisDate;
                                                  });
                                                  bool isAlreadyScheduled =
                                                      widget.detail
                                                          .unavailableDates!
                                                          .any(
                                                              (unavailableDate) {
                                                    return !(selectedDates!.end
                                                            .isBefore(
                                                                unavailableDate
                                                                    .start) ||
                                                        selectedDates!.start
                                                            .isAfter(
                                                                unavailableDate
                                                                    .end));
                                                  });

                                                  if (isAlreadyScheduled) {
                                                    alreadyScheduledAlert();
                                                  } else {
                                                    bookScheduleAlert();
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.calendar_month_outlined),
                                        label: Text(
                                          widget.detail.managedBy == user?.email
                                              ? 'Close Schedule As Admin'
                                              : 'Book this transient now!',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Property Details Section
                        Text(
                          'Property Details',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (widget.detail.roomType != null)
                                  ListTile(
                                    leading: Icon(
                                      Icons.hotel_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(
                                      'Room Type',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    subtitle: Text(
                                      widget.detail.roomType ?? 'Not specified',
                                      style: textTheme.titleMedium,
                                    ),
                                    dense: true,
                                  ),
                                if (widget.detail.numberofbeds != null)
                                  ListTile(
                                    leading: Icon(
                                      Icons.bed_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(
                                      'Number of Beds',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    subtitle: Text(
                                      widget.detail.numberofbeds ??
                                          'Not specified',
                                      style: textTheme.titleMedium,
                                    ),
                                    dense: true,
                                  ),
                                if (widget.detail.numberofrooms != null)
                                  ListTile(
                                    leading: Icon(
                                      Icons.meeting_room_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(
                                      'Number of Rooms',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    subtitle: Text(
                                      widget.detail.numberofrooms ??
                                          'Not specified',
                                      style: textTheme.titleMedium,
                                    ),
                                    dense: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amenities Section with improved empty state
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amenities',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.detail.amenities == null ||
                            widget.detail.amenities!.isEmpty)
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No amenities listed for this property',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: widget.detail.amenities?.length ?? 0,
                            itemBuilder: (context, index) {
                              final amenity = widget.detail.amenities![index];
                              if (amenity.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Card(
                                elevation: 0,
                                color: colorScheme.surfaceContainerHighest
                                    .withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        getAmenityIcon(amenity.toLowerCase()),
                                        color: colorScheme.primary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        amenity,
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // House Rules Section
                        const SizedBox(height: 32),
                        Text(
                          'House Rules',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.detail.houseRules == null ||
                            widget.detail.houseRules!.isEmpty)
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No house rules specified for this property',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.detail.houseRules?.length ?? 0,
                              separatorBuilder: (context, index) => Divider(
                                color: colorScheme.outline.withOpacity(0.2),
                                height: 16,
                              ),
                              itemBuilder: (context, index) {
                                final rule = widget.detail.houseRules![index];
                                if (rule.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Reviews Section
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.detail.managedBy != user?.email
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Book Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          transient: widget.detail,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.message_outlined),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Row iconText(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(
          width: 10,
        ),
        GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19),
              ),
            ))
      ],
    );
  }

  Widget _buildReviewsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ratings')
          .where('establishment', isEqualTo: widget.detail.name)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final ratings = snapshot.data!.docs
            .where((doc) =>
                doc['establishment'].toString().toLowerCase() ==
                widget.detail.name.toString().toLowerCase())
            .toList();

        if (ratings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Guest Reviews',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ratings.length}',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: ratings.length,
                itemBuilder: (context, index) {
                  final review = ratings[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      elevation: 0,
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
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['user'],
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedRatingStars(
                                        initialRating: review['rating'],
                                        minRating: 0.0,
                                        maxRating: 5.0,
                                        filledColor: Colors.amber,
                                        emptyColor: Colors.grey,
                                        filledIcon: Icons.star_rounded,
                                        halfFilledIcon: Icons.star_half_rounded,
                                        emptyIcon: Icons.star_border_rounded,
                                        customFilledIcon: Icons.star_rounded,
                                        customHalfFilledIcon:
                                            Icons.star_half_rounded,
                                        customEmptyIcon:
                                            Icons.star_border_rounded,
                                        onChanged: (_) {},
                                        displayRatingValue: true,
                                        interactiveTooltips: true,
                                        starSize: 16.0,
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                review['comment'],
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
          ],
        );
      },
    );
  }

  void _showBookingDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if dates are already selected
    if (selectedDates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select your dates first'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Select',
            textColor: Colors.white,
            onPressed: () {
              // Scroll to calendar section
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      );
      return;
    }

    // Check if dates are available
    bool isAlreadyScheduled =
        widget.detail.unavailableDates!.any((unavailableDate) {
      return !(selectedDates!.end.isBefore(unavailableDate.start) ||
          selectedDates!.start.isAfter(unavailableDate.end));
    });

    if (isAlreadyScheduled) {
      _showUnavailableDatesDialog();
    } else {
      _showBookingConfirmationDialog();
    }
  }

  void _showUnavailableDatesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 32,
        ),
        title: const Text('Dates Unavailable'),
        content: const Text(
          'Sorry, these dates are already booked. Please select different dates.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmationDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Dates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedDates!.start.month}/${selectedDates!.start.day}/${selectedDates!.start.year} - '
                          '${selectedDates!.end.month}/${selectedDates!.end.day}/${selectedDates!.end.year}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A message will be sent to the host to confirm your booking.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isLoading ? null : () => _processBooking(context),
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(isLoading ? 'Processing...' : 'Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processBooking(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // First check if the document exists
      final docRef = FirebaseFirestore.instance
          .collection("transientDetails")
          .doc(widget.detail.docId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Property listing no longer exists');
      }

      final message = 'I would like to book this place on '
          '${selectedDates!.start.month}/${selectedDates!.start.day}/${selectedDates!.start.year} to '
          '${selectedDates!.end.month}/${selectedDates!.end.day}/${selectedDates!.end.year}';

      Map<String, dynamic> convertedDate = {
        "start": Timestamp.fromDate(selectedDates!.start),
        "end": Timestamp.fromDate(selectedDates!.end),
        "bookedBy": user!.email,
      };

      // Update unavailable dates
      await docRef.update({
        "unavailableDates": FieldValue.arrayUnion([convertedDate])
      });

      // Send message to host
      await FirebaseFirestoreService.instance.sendChatMessages(
        widget.detail.name.toString(),
        MessageModel(
          to: widget.detail.managedBy,
          from: user!.email.toString(),
          message: message,
          timepressed: Timestamp.now(),
          transientname: widget.detail.name,
        ),
      );

      if (!mounted) return;

      // Close the dialog first
      Navigator.of(context).pop();

      // Show success message with navigation action
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Booking request sent successfully!'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close dialog and show error message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showEditDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (editAboutContext) {
        return StatefulBuilder(builder: (editableContext, setAboutState) {
          bool isLoading = false;
          TextEditingController transientName =
              TextEditingController(text: widget.detail.name);
          TextEditingController contactNumber =
              TextEditingController(text: widget.detail.contact.toString());
          TextEditingController location =
              TextEditingController(text: widget.detail.location.toString());
          TextEditingController website =
              TextEditingController(text: widget.detail.website.toString());
          return AlertDialog(
            title: const Text('Edit Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: transientName,
                  decoration: const InputDecoration(
                    labelText: 'Transient Name',
                    hintText: 'Enter Transient Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactNumber,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: 'Enter Contact Number',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter Location',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: website,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    hintText: 'Enter Website',
                  ),
                ),
                if (isLoading) const LinearProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setAboutState(() {
                          isLoading = true;
                        });
                        try {
                          await FirebaseFirestore.instance
                              .collection("transientDetails")
                              .doc(widget.docId)
                              .update({
                            "name": transientName.text,
                            "contact": contactNumber.text,
                            "location": location.text,
                            "website": website.text,
                          });

                          if (mounted) {
                            Navigator.pop(editableContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Details updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update details: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setAboutState(() {
                            isLoading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _updateCoverImage() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isLoading = true;
      });

      final File imageFile = File(image.path);
      final String imageUrl = await uploadFile(imageFile);

      await FirebaseFirestore.instance
          .collection('transientDetails')
          .doc(widget.docId)
          .update({'coverPage': imageUrl});

      setState(() {
        coverPage = imageUrl;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating cover image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
