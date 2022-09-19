import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/admin/manageaccount.dart';
import 'package:telenant/models/model.dart';

class ViewTransient extends StatefulWidget {
  const ViewTransient({super.key});

  @override
  State<ViewTransient> createState() => _ViewTransientState();
}

class _ViewTransientState extends State<ViewTransient> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
        actions: [
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
            List<details> listOfTransients = [];
            if (snapshot.hasData) {
              for (final detail in snapshot.data!.docs) {
                //print(detail['gallery'].toString());
                if (user!.email == detail['managedBy']) {
                  listOfTransients.add(details(
                    name: detail['name'].toString(),
                    location: detail['location'].toString(),
                    contact: detail['contact'].toString(),
                    website: detail['website'].toString(),
                    type: detail['type'].toString(),
                    priceRange: PriceRange(
                        min: detail['price_range']['min'],
                        max: detail['price_range']['max']),
                    coverPage: detail['cover_page'].toString(),
                    gallery: detail['gallery'],
                  ));
                }
              }
              //print(listOfTransients[0].contact);
            }
            return ListView.builder(
                itemCount: listOfTransients.length,
                shrinkWrap: true,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: const OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 1.5, color: Colors.black)),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Image.network(
                              listOfTransients[index].coverPage.toString(),
                              width: 500,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.approval_outlined,
                              color: Colors.green,
                              size: 40,
                            ),
                            title: Text(
                              listOfTransients[index].name.toString(),
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                listOfTransients[index].location.toString()),
                            trailing: TextButton(
                                onPressed: () {
                                  // Navigator.of(context).push(MaterialPageRoute(
                                  //     builder: ((context) => ViewMore(
                                  //         detail: listOfTransients[index]))));
                                },
                                child: const Text('View')),
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
