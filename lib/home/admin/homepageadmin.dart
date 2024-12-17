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

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: ((context) => const AddTransient())));
        },
        label: Text(
          'Add Transient',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      appBar: AppBar(
        title: const Text('Homepage'),
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
              icon: const Icon(Icons.logout)),
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: ((context) => const ManageAccount())));
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestoreService.instance.readItems(),
          builder: ((context, snapshot) {
            List<Details> listOfTransients = [];
            if (snapshot.hasData) {
              for (final detail in snapshot.data!.docs) {
                //print(detail['gallery'].toString());
                if (user!.email == detail['managedBy']) {
                  listOfTransients.add(Details(
                    name: detail['name'].toString(),
                    location: detail['location'].toString(),
                    contact: detail['contact'].toString(),
                    website: detail['website'].toString(),
                    type: detail['type'].toString(),
                    managedBy: detail['managedBy'],
                    priceRange: PriceRange(
                        min: detail['price_range']['min'],
                        max: detail['price_range']['max']),
                    coverPage: detail['cover_page'].toString(),
                    gallery: detail['gallery'],
                    roomType: detail['roomType'].toString(),
                    numberofbeds: detail['numberofbeds'].toString(),
                    numberofrooms: detail['numberofrooms'].toString(),
                    unavailableDates: (detail.data() as Map<String, dynamic>)
                                .containsKey('unavailableDates') &&
                            detail['unavailableDates'] != null
                        ? (detail['unavailableDates'] as List<dynamic>)
                            .map((e) => DateTimeRange(
                                  start: (e['start'] as Timestamp).toDate(),
                                  end: (e['end'] as Timestamp).toDate(),
                                ))
                            .toList()
                        : [],
                    houseRules:
                        (detail['house_rules'] as List<dynamic>).cast<String>(),
                    amenities:
                        (detail['amenities'] as List<dynamic>).cast<String>(),
                    docId: detail.id,
                  ));
                }
              }
            }
            return ListView.builder(
                itemCount: listOfTransients.length,
                shrinkWrap: true,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              width: 0.5, color: Colors.black)),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) => ViewMore(
                                      docId: listOfTransients[index].docId,
                                      detail: listOfTransients[index]))));
                            },
                            child: SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20.0),
                                    topLeft: Radius.circular(20.0)),
                                child: Image.network(
                                  listOfTransients[index].coverPage.toString(),
                                  width: double.infinity,
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
                            ),
                          ),
                          ListTile(
                            title: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: ((context) => ViewMore(
                                        docId: listOfTransients[index].docId,
                                        detail: listOfTransients[index]))));
                              },
                              child: Text(
                                listOfTransients[index].name.toString(),
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                            ),
                            subtitle: Text(
                                listOfTransients[index].location.toString()),
                            trailing: TextButton(
                                onPressed: () {
                                  // print(listOfTransients[index].amenities);
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: ((context) => ViewMore(
                                          docId: listOfTransients[index].docId,
                                          detail: listOfTransients[index]))));
                                },
                                child: const Text(
                                  'View',
                                  style: TextStyle(fontSize: 18),
                                )),
                          )
                        ],
                      ),
                    ),
                  );
                }));
          })),
    );
  }
}
