import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Telenants'),
        //   actions: [
        //     TextButton(
        //       onPressed: () {
        //         Navigator.of(context)
        //             .push(MaterialPageRoute(builder: (context) {
        //           return const LoginPage();
        //         }));
        //       },
        //       child: const Text('Login'),
        //     )
        //   ],
        // ),
        body: FutureBuilder(
      future: FirebaseFirestoreService.instance.getApartmentsFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        }
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot<Map<String, dynamic>>> documents = snapshot
              .data as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
          return Builder(
            builder: (context) {
              final double height = MediaQuery.of(context).size.height;
              return CarouselSlider(
                options: CarouselOptions(
                  height: height,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  // autoPlay: false,
                ),
                items: documents
                    .map((item) => Stack(
                          children: [
                            Center(
                                child: Image.network(
                              item['cover_page'].toString(),
                              fit: BoxFit.cover,
                              height: height,
                            )),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.35,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                      Colors.black,
                                      Colors.black,
                                      Colors.black,
                                      Colors.black,
                                      Colors.black,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                                bottom: 0,
                                left: 10,
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  height:
                                      MediaQuery.of(context).size.height * 0.25,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      item['name'].toString().isEmpty
                                          ? 'Transient Has No Name'
                                          : 'Relax and Unwind at ${item['name'].toString()}',
                                      style: textTheme.displayMedium!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                )),
                            Positioned(
                                bottom: 20,
                                right: 20,
                                child: IconButton.filledTonal(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                          return const LoginPage();
                                        }),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 50,
                                    ))),
                          ],
                        ))
                    .toList(),
              );
            },
          );
        }

        return const Center(
          child: Text('No data'),
        );
      },
    ));
  }
}
