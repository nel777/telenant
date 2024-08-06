import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/authentication/login.dart';

class TransientsListUnauthenticated extends StatefulWidget {
  const TransientsListUnauthenticated({super.key});

  @override
  State<TransientsListUnauthenticated> createState() =>
      _TransientsListUnauthenticatedState();
}

class _TransientsListUnauthenticatedState
    extends State<TransientsListUnauthenticated> {
  late List<DocumentSnapshot> transients;

  @override
  void initState() {
    super.initState();
    fetchApartments();
  }

  fetchApartments() async {
    transients =
        await FirebaseFirestoreService.instance.getApartmentsFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Telenants'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }));
              },
              child: Text('Login'),
            )
          ],
        ),
        body: FutureBuilder(
          future:
              FirebaseFirestoreService.instance.getApartmentsFromFirestore(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error'));
            }
            if (snapshot.hasData) {
              List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
                  snapshot.data
                      as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: documents.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 0.77,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = documents[index].data();
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10))),
                          child: Center(
                            child: Text(
                              data['name'].toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer),
                            ),
                          ),
                        ),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image:
                                  NetworkImage(data['cover_page'].toString()),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          // height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10)),
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),

                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) {
                                    return LoginPage(); // Replace with your desired page
                                  }),
                                );
                              },
                              child: Text(
                                'Book Now',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }

            return Center(
              child: Text('No data'),
            );
          },
        ));
  }
}
