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
                  List<details> filteredList = [];
                  if (snapshot.hasData) {
                    for (final detail in snapshot.data!.docs) {
                      print(detail['gallery']);
                      print(widget.filtered['price']['max']);
                      print(widget.filtered['price']['min'] <=
                          detail['price_range']['max']);

                      if (detail['location'].toString().toLowerCase() ==
                              widget.filtered['location']
                                  .toString()
                                  .toLowerCase() ||
                          detail['type'].toString().toLowerCase() ==
                              widget.filtered['type']
                                  .toString()
                                  .toLowerCase() ||
                          (((widget.filtered['price']['min'] <=
                                      detail['price_range']['max']) &&
                                  (widget.filtered['price']['min'] >=
                                      detail['price_range']['min'])) ||
                              ((widget.filtered['price']['max'] >=
                                      detail['price_range']['min']) ||
                                  ((widget.filtered['price']['max'] ==
                                          detail['price_range']['max']) ||
                                      (widget.filtered['price']['max'] >
                                          detail['price_range']['max']))))) {
                        filteredList.add(details(
                          name: detail['name'],
                          gallery: detail['gallery'] as List<dynamic>,
                          bedrooms: detail['bedrooms'],
                          location: detail['location'],
                          contact: detail['contact'],
                          type: detail['type'],
                          website: detail['website'],
                          coverPage: detail['cover_page'],
                        ));
                      }
                    }
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${filteredList.length.toString()} Found Properties',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                      child:
                                          const Text('Change Filter or Search'))
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
                                                  detail: filteredList[index],
                                                ))));
                                  },
                                  child: Card(
                                    elevation: 3.0,
                                    shape: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
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
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                filteredList[index]
                                                    .name
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(
                                                  '${filteredList[index].bedrooms.toString()} Bed'),
                                              // Padding(
                                              //   padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                              //   child: Text('|'),
                                              // ),
                                              // Text('1 Restroom'),
                                            ],
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
                  );
                }))),
      ),
    );
  }
}
