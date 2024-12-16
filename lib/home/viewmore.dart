import 'dart:io';

import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telenant/home/components/table_calendar.dart';
// import 'package:telenant/home/rate.dart';
import 'package:telenant/models/model.dart';

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
  String? coverPage = '';
  ImagePicker picker = ImagePicker();
  bool hasReviews = false;
  DateTimeRange? selectedDates;

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
    setState(() {
      coverPage = widget.detail.coverPage;
      albums = widget.detail.gallery!;
      // selectedDates = [
      //   DateTimeRange(
      //     start: DateTime(2024, 12, 20),
      //     end: DateTime(2024, 12, 25),
      //   ),
      //   DateTimeRange(
      //     start: DateTime(2024, 12, 30),
      //     end: DateTime(2024, 12, 31),
      //   ),
      // ];
    });
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
            bool isLoading = false;
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
                      ? const CircularProgressIndicator()
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          //backgroundColor: Colors.transparent,
          //elevation: 0,
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                //color: Colors.black,
              )),
          title: Text(
            widget.detail.name.toString(),
            //style: const TextStyle(fontSize: 28),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(25.0)),
                        child: Image.network(
                          coverPage!,
                          width: MediaQuery.of(context).size.width - 20,
                          height: MediaQuery.of(context).size.height * 0.3,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: widget.detail.managedBy == user!.email
                            ? IconButton.filledTonal(
                                icon: Icon(
                                  Icons.switch_access_shortcut_outlined,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () async {
                                  XFile? imagecover = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (imagecover != null) {
                                    String url =
                                        await uploadFile(File(imagecover.path));
                                    setState(() {
                                      coverPage = url;
                                    });
                                    await FirebaseFirestore.instance
                                        .collection("transientDetails")
                                        .doc(widget.docId)
                                        .update({"cover_page": url});
                                  }
                                },
                              )
                            : const SizedBox.shrink(),
                      )
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 5.0,
                      shape: OutlineInputBorder(
                          borderSide: const BorderSide(
                              style: BorderStyle.none, width: 0.5),
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.detail.name.toString(),
                                    style: textTheme.titleLarge!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.detail.location.toString(),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.apartment),
                                        Text(
                                          widget.detail.type.toString(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Text(
                                  'Schedules',
                                  style: textTheme.titleLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton.filledTonal(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (calendarContext) {
                                            return CalendarWithUnavailableDates(
                                                unavailableDates: widget
                                                    .detail.unavailableDates!);
                                          });
                                    },
                                    icon: const Icon(Icons.calendar_month)),
                                const Spacer(),
                                widget.detail.managedBy == user!.email
                                    ? TextButton(
                                        onPressed: () async {
                                          final closeThisDate =
                                              await showDateRangePicker(
                                                  context: context,
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(2100));
                                          if (closeThisDate != null) {
                                            setState(() {
                                              selectedDates = closeThisDate;
                                            });
                                            print(
                                                'the selected dates are: $selectedDates');
                                            displayWarningAlert();
                                          }
                                        },
                                        child:
                                            const Text('Book/Reserve Schedule'))
                                    : SizedBox.shrink()
                              ],
                            ),
                            Card(
                              elevation: 3.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: const BorderSide(width: 0.5),
                              ),
                              child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: widget.detail.amenities == null
                                      ? 0
                                      : widget.detail.amenities!.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          childAspectRatio: 1.5,
                                          crossAxisCount: 3),
                                  itemBuilder: (context, index) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(getAmenityIcon(widget
                                            .detail.amenities![index]
                                            .toString()
                                            .toLowerCase())),
                                        Text(
                                          widget.detail.amenities![index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    );
                                  }),
                            ),
                            const Divider(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'About',
                                      style: textTheme.titleLarge!.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    widget.detail.managedBy == user!.email
                                        ? TextButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (editAboutContext) {
                                                    return StatefulBuilder(
                                                        builder:
                                                            (editableContext,
                                                                setAboutState) {
                                                      bool isLoading = false;
                                                      TextEditingController
                                                          _transientName =
                                                          TextEditingController(
                                                              text: widget
                                                                  .detail.name);
                                                      TextEditingController
                                                          _contactNumber =
                                                          TextEditingController(
                                                              text: widget
                                                                  .detail
                                                                  .contact
                                                                  .toString());
                                                      TextEditingController
                                                          _location =
                                                          TextEditingController(
                                                              text: widget
                                                                  .detail
                                                                  .location
                                                                  .toString());
                                                      TextEditingController
                                                          _website =
                                                          TextEditingController(
                                                              text: widget
                                                                  .detail
                                                                  .website
                                                                  .toString());
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Edit Details'),
                                                        actions: [
                                                          OutlinedButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: Text(
                                                                  'Cancel')),
                                                          ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              setAboutState(() {
                                                                isLoading =
                                                                    true;
                                                              });
                                                              String
                                                                  updatedName =
                                                                  _transientName
                                                                      .text;
                                                              String
                                                                  updatedContact =
                                                                  _contactNumber
                                                                      .text;
                                                              String
                                                                  updatedLocation =
                                                                  _location
                                                                      .text;
                                                              String
                                                                  updatedWebsite =
                                                                  _website.text;

                                                              try {
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "transientDetails")
                                                                    .doc(widget
                                                                        .docId)
                                                                    .update({
                                                                  "name":
                                                                      updatedName,
                                                                  "contact":
                                                                      updatedContact,
                                                                  "location":
                                                                      updatedLocation,
                                                                  "website":
                                                                      updatedWebsite,
                                                                });

                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content: Text(
                                                                          'Details updated successfully!')),
                                                                );
                                                                setAboutState(
                                                                    () {
                                                                  isLoading =
                                                                      false;
                                                                });
                                                                Navigator.of(
                                                                        editableContext)
                                                                    .pop();
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content: Text(
                                                                          'Failed to update details: $e')),
                                                                );
                                                              }
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    colorScheme
                                                                        .primaryContainer),
                                                            child: Text(
                                                              'Save',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: colorScheme
                                                                      .primary),
                                                            ),
                                                          ),
                                                        ],
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              controller:
                                                                  _transientName,
                                                              decoration:
                                                                  const InputDecoration(
                                                                label: Text(
                                                                    'Transient Name'),
                                                                hintText:
                                                                    'Enter Transient Name',
                                                              ),
                                                            ),
                                                            Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0)),
                                                            TextField(
                                                              controller:
                                                                  _contactNumber,
                                                              decoration:
                                                                  const InputDecoration(
                                                                label: Text(
                                                                    'Contact Number'),
                                                                hintText:
                                                                    'Enter Contact Number',
                                                              ),
                                                            ),
                                                            Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0)),
                                                            TextField(
                                                              controller:
                                                                  _location,
                                                              decoration:
                                                                  const InputDecoration(
                                                                label: Text(
                                                                    'Location'),
                                                                hintText:
                                                                    'Enter Location',
                                                              ),
                                                            ),
                                                            Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0)),
                                                            TextField(
                                                              controller:
                                                                  _website,
                                                              decoration:
                                                                  const InputDecoration(
                                                                label: Text(
                                                                    'Website'),
                                                                hintText:
                                                                    'Enter Website',
                                                              ),
                                                            ),
                                                            Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0)),
                                                            isLoading
                                                                ? LinearProgressIndicator()
                                                                : SizedBox
                                                                    .shrink()
                                                          ],
                                                        ),
                                                      );
                                                    });
                                                  });
                                            },
                                            label: const Text('Edit'))
                                        : SizedBox.shrink()
                                  ],
                                ),
                                Wrap(spacing: 5.0, children: [
                                  widget.detail.roomType!.isEmpty
                                      ? SizedBox.shrink()
                                      : Chip(
                                          elevation: 3.0,
                                          color: WidgetStatePropertyAll(
                                              colorScheme.primaryContainer),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.0)),
                                          label: Text(widget.detail.roomType!
                                              .toUpperCase())),
                                  widget.detail.numberofbeds!.isEmpty
                                      ? SizedBox.shrink()
                                      : Chip(
                                          elevation: 3.0,
                                          color: WidgetStatePropertyAll(
                                              colorScheme.primaryContainer),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.0)),
                                          label: Text(
                                              '${widget.detail.numberofbeds!} Beds')),
                                  Chip(
                                      elevation: 3.0,
                                      color: WidgetStatePropertyAll(
                                          colorScheme.primaryContainer),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.0)),
                                      label: Text(
                                          '${widget.detail.priceRange!.min} - ${widget.detail.priceRange!.max} Php')),
                                ]),
                                const SizedBox(
                                  height: 10,
                                ),
                                iconText(Icons.call,
                                    widget.detail.contact.toString()),
                                const SizedBox(
                                  height: 10,
                                ),
                                iconText(Icons.streetview,
                                    widget.detail.location.toString()),
                                const SizedBox(
                                  height: 10,
                                ),
                                InkWell(
                                    splashColor: Colors.blue,
                                    onTap: () {},
                                    child:
                                        iconText(Icons.web, 'Visit Website')),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Gallery',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                albums!.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('No Images to Show'),
                                        ),
                                      )
                                    : Container(
                                        height: widget.detail.managedBy ==
                                                user!.email
                                            ? 285
                                            : 285,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.all(15),
                                        child: CarouselSlider.builder(
                                          itemCount: albums!.length,
                                          options: CarouselOptions(
                                            enlargeCenterPage: true,
                                            height: 350,
                                            autoPlay: true,
                                            autoPlayInterval:
                                                const Duration(seconds: 3),
                                            reverse: false,
                                            aspectRatio: 5.0,
                                          ),
                                          itemBuilder: (context, i, id) {
                                            return Column(
                                              children: [
                                                Container(
                                                  height: 230,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                      )),
                                                  //ClipRRect for image border radius
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    child: Image.network(
                                                      albums![i],
                                                      width: 500,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (BuildContext
                                                              context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                              loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Placeholder();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                widget.detail.managedBy ==
                                                        user!.email
                                                    ? Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                              child: InkWell(
                                                            onTap: () {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      ((context) {
                                                                    return AlertDialog(
                                                                      title: const Text(
                                                                          'Replace'),
                                                                      content:
                                                                          const Text(
                                                                              'Do you want to proceed in replacing this image?'),
                                                                      actions: [
                                                                        ElevatedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              List<dynamic>? oldGallery = albums;
                                                                              List<dynamic> updatedGallery = [];
                                                                              String urlToReplace = widget.detail.gallery![i];
                                                                              XFile? imagecover = await picker.pickImage(source: ImageSource.gallery);
                                                                              if (widget.detail.gallery != null) {
                                                                                for (String url in oldGallery!) {
                                                                                  if (url == urlToReplace) {
                                                                                    var finalUrl = await uploadFile(File(imagecover!.path));
                                                                                    oldGallery[oldGallery.indexOf(urlToReplace)] = finalUrl;
                                                                                    updatedGallery = oldGallery;
                                                                                  }
                                                                                }
                                                                              }
                                                                              await FirebaseFirestore.instance.collection("transientDetails").doc(widget.docId).update({
                                                                                "gallery": updatedGallery
                                                                              });
                                                                              if (!mounted) {
                                                                                return;
                                                                              }
                                                                              Navigator.of(
                                                                                  // ignore: use_build_context_synchronously
                                                                                  context).pop();
                                                                            },
                                                                            child:
                                                                                const Text('Yes')),
                                                                        OutlinedButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                            child:
                                                                                const Text('Cancel'))
                                                                      ],
                                                                    );
                                                                  }));
                                                            },
                                                            child: Card(
                                                                child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      10.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons.edit,
                                                                    color: Colors
                                                                            .green[
                                                                        200],
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  const Text(
                                                                      'Replace')
                                                                ],
                                                              ),
                                                            )),
                                                          )),
                                                          Expanded(
                                                              child: InkWell(
                                                            onTap: () {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      ((context) {
                                                                    return AlertDialog(
                                                                      title: const Text(
                                                                          'Delete'),
                                                                      content:
                                                                          const Text(
                                                                              'Are you sure you want to delete this image?'),
                                                                      actions: [
                                                                        ElevatedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              List<dynamic> oldGallery = albums!;
                                                                              List<dynamic> updatedGallery = [];
                                                                              String urlToReplace = widget.detail.gallery![i];
                                                                              oldGallery.remove(urlToReplace);

                                                                              updatedGallery = oldGallery;

                                                                              await FirebaseFirestore.instance.collection("transientDetails").doc(widget.docId).update({
                                                                                "gallery": updatedGallery
                                                                              });
                                                                              if (!mounted) {
                                                                                return;
                                                                              }
                                                                              setState(() {
                                                                                albums = updatedGallery;
                                                                              });
                                                                              Navigator.of(
                                                                                  // ignore: use_build_context_synchronously
                                                                                  context).pop();
                                                                            },
                                                                            child:
                                                                                const Text('Yes')),
                                                                        OutlinedButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                            child:
                                                                                const Text('No'))
                                                                      ],
                                                                    );
                                                                  }));
                                                            },
                                                            child: const Card(
                                                                child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          10.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  Text('Remove')
                                                                ],
                                                              ),
                                                            )),
                                                          )),
                                                        ],
                                                      )
                                                    : const SizedBox.shrink()
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                widget.detail.managedBy == user!.email
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, right: 8.0),
                                        child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: ((context) =>
                                                          ChatScreen(
                                                            transient:
                                                                widget.detail,
                                                          ))));
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colorScheme.primary,
                                                fixedSize: Size(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        16,
                                                    45)),
                                            icon: Icon(
                                                Icons.room_service_rounded,
                                                color: colorScheme.onPrimary),
                                            label: Text(
                                              'Book/Reserve Transient',
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  color: colorScheme.onPrimary),
                                            )),
                                      ),
                                // widget.detail.managedBy == user!.email
                                //     ? const SizedBox.shrink()
                                //     :
                                FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('ratings')
                                        .where('establishment',
                                            isEqualTo: widget.detail.name)
                                        .get(),
                                    builder: (context, snapshot) {
                                      List<DocumentSnapshot> ratings = [];
                                      if (snapshot.hasData) {
                                        final List<DocumentSnapshot>
                                            listOfRated = snapshot.data!.docs;
                                        if (listOfRated.isNotEmpty) {
                                          for (var element in listOfRated) {
                                            if (element['establishment']
                                                    .toString()
                                                    .toLowerCase() ==
                                                widget.detail.name
                                                    .toString()
                                                    .toLowerCase()) {
                                              ratings.add(element);
                                            }
                                          }
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            snapshot.error.toString(),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .inverseSurface),
                                          ),
                                        );
                                      } else if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                        // final List<DocumentSnapshot> listOfRated =
                                        //     snapshot.data!.docs;
                                        // if (listOfRated.isEmpty) {

                                        // }
                                      }
                                      return Column(
                                        children: [
                                          const Text('Reviews',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(
                                            height: 210,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              shrinkWrap: true,
                                              children: ratings
                                                  .map((doc) => Card(
                                                        elevation: 5.0,
                                                        shape:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .person_2_rounded,
                                                              size: 55,
                                                            ),
                                                            Text(doc['user']),
                                                            AnimatedRatingStars(
                                                              initialRating:
                                                                  doc['rating'],
                                                              minRating: 0.0,
                                                              maxRating: 5.0,
                                                              filledColor:
                                                                  Colors.amber,
                                                              emptyColor:
                                                                  Colors.grey,
                                                              filledIcon:
                                                                  Icons.star,
                                                              halfFilledIcon:
                                                                  Icons
                                                                      .star_half,
                                                              emptyIcon: Icons
                                                                  .star_border,
                                                              onChanged: (double
                                                                  rating) {},
                                                              displayRatingValue:
                                                                  true,
                                                              interactiveTooltips:
                                                                  true,
                                                              customFilledIcon:
                                                                  Icons.star,
                                                              customHalfFilledIcon:
                                                                  Icons
                                                                      .star_half,
                                                              customEmptyIcon:
                                                                  Icons
                                                                      .star_border,
                                                              starSize: 20.0,
                                                              animationDuration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                              animationCurve:
                                                                  Curves
                                                                      .easeInOut,
                                                              readOnly: true,
                                                            ),
                                                            Text(
                                                                doc['comment']),
                                                          ],
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Image imageNetwork(String url) {
    return Image.network(
      url,
      fit: BoxFit.fill,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
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
}
