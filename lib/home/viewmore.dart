import 'dart:io';

import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telenant/home/rate.dart';
import 'package:telenant/models/model.dart';

import '../chatmessaging/chatscreen.dart';

class ViewMore extends StatefulWidget {
  final details detail;
  final String? docId;

  const ViewMore({Key? key, required this.detail, this.docId})
      : super(key: key);

  @override
  State<ViewMore> createState() => _ViewMoreState();
}

class _ViewMoreState extends State<ViewMore> {
  User? user = FirebaseAuth.instance.currentUser;
  List<dynamic>? albums = [];
  String? coverPage = '';
  ImagePicker picker = ImagePicker();

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
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: SizedBox(
            height: MediaQuery.of(context).size.height + 200,
            child: Stack(
              children: [
                const Positioned(
                    top: 0,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Details',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    )),
                Positioned(
                    top: 50,
                    //left: 54.9,
                    child: Padding(
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
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 20,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        left: 8.0, right: 8.0, top: 8.0),
                                    child: Text(
                                      'Contacts',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19),
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.black,
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
                            ),
                          ),
                          Text('Reviews',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 210,
                            child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('ratings')
                                    .get(),
                                builder: (context, snapshot) {
                                  List<DocumentSnapshot> ratings = [];
                                  if (snapshot.hasData) {
                                    final List<DocumentSnapshot> listOfRated =
                                        snapshot.data!.docs;
                                    listOfRated.forEach((element) {
                                      if (element['establishment']
                                              .toString()
                                              .toLowerCase() ==
                                          widget.detail.name
                                              .toString()
                                              .toLowerCase()) {
                                        ratings.add(element);
                                      }
                                    });
                                  } else if (snapshot.hasError) {
                                    return const Center(
                                      child: Text('Failed to load'),
                                    );
                                  }
                                  return ListView(
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    children: ratings
                                        .map((doc) => Card(
                                              elevation: 5.0,
                                              shape: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.person_2_rounded,
                                                    size: 55,
                                                  ),
                                                  Text(doc['user']),
                                                  AnimatedRatingStars(
                                                    initialRating:
                                                        doc['rating'],
                                                    minRating: 0.0,
                                                    maxRating: 5.0,
                                                    filledColor: Colors.amber,
                                                    emptyColor: Colors.grey,
                                                    filledIcon: Icons.star,
                                                    halfFilledIcon:
                                                        Icons.star_half,
                                                    emptyIcon:
                                                        Icons.star_border,
                                                    onChanged: (double rating) {
                                                      // Handle the rating change here
                                                      print('Rating: $rating');
                                                    },
                                                    displayRatingValue: true,
                                                    interactiveTooltips: true,
                                                    customFilledIcon:
                                                        Icons.star,
                                                    customHalfFilledIcon:
                                                        Icons.star_half,
                                                    customEmptyIcon:
                                                        Icons.star_border,
                                                    starSize: 20.0,
                                                    animationDuration:
                                                        const Duration(
                                                            milliseconds: 300),
                                                    animationCurve:
                                                        Curves.easeInOut,
                                                    readOnly: true,
                                                  ),
                                                  Text(doc['comment']),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  );
                                }),
                          ),
                        ],
                      ),
                    )),

                Positioned(
                    top: 450,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Cover Page',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Card(
                            elevation: 5.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5.0),
                                      topRight: Radius.circular(5.0)),
                                  child: Image.network(
                                    coverPage!,
                                    width:
                                        MediaQuery.of(context).size.width - 20,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(
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
                                  ),
                                ),
                                widget.detail.managedBy == user!.email
                                    ? TextButton.icon(
                                        icon: const Icon(Icons.find_replace),
                                        label: const Text('Replace'),
                                        onPressed: () async {
                                          XFile? imagecover =
                                              await picker.pickImage(
                                                  source: ImageSource.gallery);
                                          String url = await uploadFile(
                                              File(imagecover!.path));
                                          setState(() {
                                            coverPage = url;
                                          });
                                          await FirebaseFirestore.instance
                                              .collection("transientDetails")
                                              .doc(widget.docId)
                                              .update({"cover_page": url});
                                        },
                                      )
                                    : const SizedBox.shrink()
                              ],
                            ),
                          )
                        ],
                      ),
                    )),

                Positioned(
                    top: 660,
                    child: Column(
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
                                height: widget.detail.managedBy == user!.email
                                    ? 350
                                    : 285,
                                width: MediaQuery.of(context).size.width,
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
                                    //for onTap to redirect to another screen
                                    return Column(
                                      children: [
                                        Container(
                                          height: 230,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.white,
                                              )),
                                          //ClipRRect for image border radius
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.network(
                                              albums![i],
                                              width: 500,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (BuildContext context,
                                                      Widget child,
                                                      ImageChunkEvent?
                                                          loadingProgress) {
                                                if (loadingProgress == null) {
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
                                            ),
                                          ),
                                        ),
                                        widget.detail.managedBy == user!.email
                                            ? Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                      child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: ((context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Replace'),
                                                              content: const Text(
                                                                  'Do you want to proceed in replacing this image?'),
                                                              actions: [
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      List<dynamic>?
                                                                          oldGallery =
                                                                          albums;
                                                                      List<dynamic>
                                                                          updatedGallery =
                                                                          [];
                                                                      String
                                                                          urlToReplace =
                                                                          widget
                                                                              .detail
                                                                              .gallery![i];
                                                                      XFile?
                                                                          imagecover =
                                                                          await picker.pickImage(
                                                                              source: ImageSource.gallery);
                                                                      if (widget
                                                                              .detail
                                                                              .gallery !=
                                                                          null) {
                                                                        for (String url
                                                                            in oldGallery!) {
                                                                          if (url ==
                                                                              urlToReplace) {
                                                                            var finalUrl =
                                                                                await uploadFile(File(imagecover!.path));
                                                                            oldGallery[oldGallery.indexOf(urlToReplace)] =
                                                                                finalUrl;
                                                                            updatedGallery =
                                                                                oldGallery;
                                                                          }
                                                                        }
                                                                      }
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              "transientDetails")
                                                                          .doc(widget
                                                                              .docId)
                                                                          .update({
                                                                        "gallery":
                                                                            updatedGallery
                                                                      });
                                                                      if (!mounted) {
                                                                        return;
                                                                      }
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: const Text(
                                                                        'Yes')),
                                                                OutlinedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: const Text(
                                                                        'Cancel'))
                                                              ],
                                                            );
                                                          }));
                                                    },
                                                    child: Card(
                                                        child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
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
                                                                .green[200],
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          const Text('Replace')
                                                        ],
                                                      ),
                                                    )),
                                                  )),
                                                  Expanded(
                                                      child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: ((context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Delete'),
                                                              content: const Text(
                                                                  'Are you sure you want to delete this image?'),
                                                              actions: [
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      List<dynamic>
                                                                          oldGallery =
                                                                          albums!;
                                                                      List<dynamic>
                                                                          updatedGallery =
                                                                          [];
                                                                      String
                                                                          urlToReplace =
                                                                          widget
                                                                              .detail
                                                                              .gallery![i];
                                                                      oldGallery
                                                                          .remove(
                                                                              urlToReplace);

                                                                      updatedGallery =
                                                                          oldGallery;

                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              "transientDetails")
                                                                          .doc(widget
                                                                              .docId)
                                                                          .update({
                                                                        "gallery":
                                                                            updatedGallery
                                                                      });
                                                                      if (!mounted) {
                                                                        return;
                                                                      }
                                                                      setState(
                                                                          () {
                                                                        albums =
                                                                            updatedGallery;
                                                                      });
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: const Text(
                                                                        'Yes')),
                                                                OutlinedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'No'))
                                                              ],
                                                            );
                                                          }));
                                                    },
                                                    child: const Card(
                                                        child: Padding(
                                                      padding:
                                                          EdgeInsets.all(10.0),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
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
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Container(
                        //     width: MediaQuery.of(context).size.width - 16,
                        //     height: 2,
                        //     color: Colors.black54,
                        //   ),
                        // ),
                        widget.detail.managedBy == user!.email
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: ((context) => ChatScreen(
                                                    transient: widget.detail,
                                                  ))));
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white30,
                                        fixedSize: Size(
                                            MediaQuery.of(context).size.width -
                                                16,
                                            45)),
                                    icon:
                                        const Icon(Icons.room_service_rounded),
                                    label: const Text(
                                      'Book/Reserve Transient',
                                      style: TextStyle(fontSize: 17),
                                    )),
                              ),
                        // widget.detail.managedBy == user!.email
                        //     ? const SizedBox.shrink()
                        //     :
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: ((context) => RateService(
                                          transient:
                                              widget.detail.name.toString(),
                                        ))));
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[300],
                                  fixedSize: Size(
                                      MediaQuery.of(context).size.width - 16,
                                      45)),
                              icon: const Icon(Icons.star_rate),
                              label: Text(
                                widget.detail.managedBy != user!.email
                                    ? 'Rate Service'
                                    : 'Rate As Admin',
                                style: TextStyle(fontSize: 17),
                              )),
                        ),
                      ],
                    )),

                // Positioned(
                //     top: 60,
                //     child: Text(
                //       widget.detail.name.toString(),
                //       style: const TextStyle(
                //           fontSize: 40,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.white),
                //     ))
              ],
            ),
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

  Padding iconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.green,
          ),
          const SizedBox(
            width: 10,
          ),
          GestureDetector(
              onTap: () {},
              child: Text(
                text,
                style: TextStyle(fontSize: 19),
              ))
        ],
      ),
    );
  }
}
