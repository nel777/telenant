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
  const ShowFiltered({Key? key, required this.filtered}) : super(key: key);

  @override
  State<ShowFiltered> createState() => _ShowFilteredState();
}

class _ShowFilteredState extends State<ShowFiltered> {
  // var test = [
  //   details(
  //     name: 'Pamela',
  //     contact: '09085272866',
  //     website: 'https://www.facebook.com/lenwilbaguio',
  //     coverPage:
  //         'https://axtgsckh4xo4.compat.objectstorage.ap-singapore-1.oraclecloud.com/baguio-visita/QuX1l5I632omTzYYFIpNVyiCYYCch1HWQKyFfeDq.jpg',
  //     bedrooms: 1,
  //     location: '23 Villain Street Engrs Hill',
  //     priceRange: PriceRange(
  //       min: 200,
  //       max: 300,
  //     ),
  //   ),
  // ];
  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Telenants'),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    //barrierDismissible: false,
                    builder: ((context) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                logout();
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: ((context) =>
                                            const LoginPage())));
                              },
                              child: const Text('Yes'))
                        ],
                      );
                    }));
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestoreService.instance.readItems(),
                builder: ((context, snapshot) {
                  List<Details> filteredList = [];
                  List<Details> similarList = [];
                  if (snapshot.hasData) {
                    for (final detail in snapshot.data!.docs) {
                      final data = detail.data() as Map<String, dynamic>;

                      final typeList = data['type'] is String
                          ? [
                              data['type'].toString().toLowerCase()
                            ] // Convert single string to list
                          : (data['type'] as List<dynamic>?)
                                  ?.map((e) => e.toString().toLowerCase())
                                  .toList() ??
                              [];
                      final filteredTypeList =
                          (widget.filtered['type'] as List<dynamic>?)
                                  ?.map((e) => e.toString().toLowerCase())
                                  .toList() ??
                              [];
                      final matchesType = typeList
                          .any((type) => filteredTypeList.contains(type));

                      final matchesLocation = data['location']
                              ?.toString()
                              .toLowerCase() ==
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
                      if (matchesLocation &&
                          matchesType &&
                          matchesPrice &&
                          matchesRoomType &&
                          matchesBeds &&
                          matchesRooms) {
                        filteredList.add(Details(
                            docId: detail.id,
                            name: detail['name'],
                            gallery: detail['gallery'] as List<dynamic>,
                            location: detail['location'],
                            contact: detail['contact'],
                            type: detail['type'],
                            website: detail['website'],
                            managedBy: detail['managedBy'],
                            coverPage: detail['cover_page'],
                            priceRange: PriceRange(
                                min: detail['price_range']['min'],
                                max: detail['price_range']['max']),
                            roomType: (detail.data() as Map<String, dynamic>).containsKey('roomType') && detail['roomType'] != null
                                ? detail['roomType'].toString()
                                : '',
                            numberofbeds: (detail.data() as Map<String, dynamic>)
                                        .containsKey('numberofbeds') &&
                                    detail['numberofbeds'] != null
                                ? detail['numberofbeds'].toString()
                                : '',
                            numberofrooms:
                                (detail.data() as Map<String, dynamic>).containsKey('numberofrooms') &&
                                        detail['numberofrooms'] != null
                                    ? detail['numberofrooms'].toString()
                                    : '',
                            unavailableDates: (detail.data() as Map<String, dynamic>)
                                        .containsKey('unavailableDates') &&
                                    detail['unavailableDates'] != null
                                ? (detail['unavailableDates'] as List<dynamic>)
                                    .map((e) => DateTimeRange(
                                          start: (e['start'] as Timestamp)
                                              .toDate(),
                                          end: (e['end'] as Timestamp).toDate(),
                                        ))
                                    .toList()
                                : [],
                            houseRules: (detail.data() as Map<String, dynamic>).containsKey('house_rules') && detail['house_rules'] != null
                                ? (detail['house_rules'] as List<dynamic>).cast<String>()
                                : [],
                            amenities: (detail.data() as Map<String, dynamic>).containsKey('amenities') && detail['amenities'] != null ? (detail['amenities'] as List<dynamic>).cast<String>() : []));
                      } else {
                        if (matchesRooms ||
                            matchesBeds ||
                            matchesRoomType ||
                            matchesPrice ||
                            matchesType ||
                            matchesLocation) {
                          similarList.add(Details(
                              docId: detail.id,
                              name: detail['name'],
                              gallery: detail['gallery'] as List<dynamic>,
                              location: detail['location'],
                              contact: detail['contact'],
                              type: detail['type'],
                              website: detail['website'],
                              managedBy: detail['managedBy'],
                              coverPage: detail['cover_page'],
                              priceRange: PriceRange(
                                  min: detail['price_range']['min'],
                                  max: detail['price_range']['max']),
                              roomType:
                                  (detail.data() as Map<String, dynamic>).containsKey('roomType') &&
                                          detail['roomType'] != null
                                      ? detail['roomType'].toString()
                                      : '',
                              numberofbeds: (detail.data() as Map<String, dynamic>)
                                          .containsKey('numberofbeds') &&
                                      detail['numberofbeds'] != null
                                  ? detail['numberofbeds'].toString()
                                  : '',
                              numberofrooms: (detail.data() as Map<String, dynamic>)
                                          .containsKey('numberofrooms') &&
                                      detail['numberofrooms'] != null
                                  ? detail['numberofrooms'].toString()
                                  : '',
                              unavailableDates: (detail.data() as Map<String, dynamic>)
                                          .containsKey('unavailableDates') &&
                                      detail['unavailableDates'] != null
                                  ? (detail['unavailableDates'] as List<dynamic>)
                                      .map((e) => DateTimeRange(
                                            start: (e['start'] as Timestamp)
                                                .toDate(),
                                            end: (e['end'] as Timestamp)
                                                .toDate(),
                                          ))
                                      .toList()
                                  : [],
                              houseRules: (detail.data() as Map<String, dynamic>).containsKey('house_rules') && detail['house_rules'] != null ? (detail['house_rules'] as List<dynamic>).cast<String>() : [],
                              amenities: (detail.data() as Map<String, dynamic>).containsKey('amenities') && detail['amenities'] != null ? (detail['amenities'] as List<dynamic>).cast<String>() : []));
                        }
                      }
                    }
                  }
                  return Column(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              child: Text(
                                '${filteredList.length.toString()} Found ${filteredList.length == 1 ? 'Property' : 'Properties'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          filteredList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Sorry, no available properties with your options.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontStyle: FontStyle.italic),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                              'Change Filter or Search'))
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: filteredList.length,
                                  itemBuilder: ((context, index) {
                                    return InkWell(
                                      splashColor: Colors.blueAccent,
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                                builder: ((context) => ViewMore(
                                                      detail:
                                                          filteredList[index],
                                                      docId: filteredList[index]
                                                          .docId,
                                                    ))));
                                      },
                                      child: Card(
                                        elevation: 3.0,
                                        shape: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            borderSide: const BorderSide(
                                                style: BorderStyle.none)),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: SizedBox(
                                                height: 200,
                                                width: double.maxFinite,
                                                child: Image.network(
                                                  filteredList[index]
                                                      .coverPage
                                                      .toString(),
                                                  fit: BoxFit.fill,
                                                  loadingBuilder:
                                                      (BuildContext context,
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
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0, right: 8.0),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.pin_drop_rounded,
                                                    color: Colors.grey,
                                                  ),
                                                  Text(filteredList[index]
                                                      .location
                                                      .toString()),
                                                  const Spacer(),
                                                  const Text(
                                                    'View More',
                                                    style: TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                            ),
                                            const Divider(
                                              color: Colors.blue,
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }))
                        ],
                      ),
                      Divider(
                        height: 5,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${similarList.length.toString()} Similar Properties',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          similarList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Sorry, no available properties with your options.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontStyle: FontStyle.italic),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                              'Change Filter or Search'))
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2),
                                  shrinkWrap: true,
                                  itemCount: similarList.length,
                                  itemBuilder: ((context, index) {
                                    return InkWell(
                                      splashColor: Colors.blueAccent,
                                      onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: ((context) => ViewMore(
                                                    detail: similarList[index],
                                                    docId: similarList[index]
                                                        .docId))));
                                      },
                                      child: Card(
                                        elevation: 3.0,
                                        shape: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            borderSide: const BorderSide(
                                                style: BorderStyle.none)),
                                        child: Stack(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: Image.network(
                                                height: double.maxFinite,
                                                width: double.maxFinite,
                                                similarList[index]
                                                    .coverPage
                                                    .toString(),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Placeholder();
                                                },
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
                                            Positioned(
                                                left: 0,
                                                bottom: 0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                        .withOpacity(0.8),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(5),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      similarList[index]
                                                              .name
                                                              .toString()
                                                              .isEmpty
                                                          ? 'Unknown'
                                                          : similarList[index]
                                                              .name
                                                              .toString(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: true,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                                ))
                                          ],
                                        ),
                                      ),
                                    );
                                  }))
                        ],
                      )
                    ],
                  );
                }))),
      ),
    );
  }
}
