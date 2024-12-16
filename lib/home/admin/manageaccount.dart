import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/admin/viewmessages.dart';

class ManageAccount extends StatefulWidget {
  const ManageAccount({super.key});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}

class _ManageAccountState extends State<ManageAccount> {
  final TextEditingController _changePassword = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20,
              ),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Account Details',
                  labelStyle: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _changePassword,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        label: const Text('Change Password'),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              final FirebaseAuth firebaseAuth =
                                  FirebaseAuth.instance;
                              User? currentUser = firebaseAuth.currentUser;
                              currentUser!
                                  .updatePassword(_changePassword.text)
                                  .then((value) {
                                showDialog(
                                    context: context,
                                    builder: ((context) {
                                      return AlertDialog(
                                        title: const Text('Success'),
                                        content: const Text(
                                            'Password has been changed successfully.'),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Okay'))
                                        ],
                                      );
                                    }));
                              }).catchError((err) {
                                showDialog(
                                    context: context,
                                    builder: ((context) {
                                      return AlertDialog(
                                        title: const Text('Error'),
                                        content: Text(err.toString()),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Okay'))
                                        ],
                                      );
                                    }));
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                fixedSize: const Size(250, 40)),
                            child: const Text('Update'))
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Registered Transients',
                    labelStyle: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestoreService.instance.readItems(),
                      builder: ((context, snapshot) {
                        List<QueryDocumentSnapshot> myTransient = [];
                        if (snapshot.hasData) {
                          for (final transient in snapshot.data!.docs) {
                            if (transient['managedBy'] ==
                                FirebaseAuth.instance.currentUser!.email) {
                              myTransient.add(transient);
                            }
                          }
                        }
                        return ListView.builder(
                            itemCount: myTransient.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: ((context, index) {
                              return Card(
                                elevation: 5.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        subtitle: Text(
                                            myTransient[index]['location']),
                                        leading: SizedBox(
                                          height: 150,
                                          width: 100,
                                          child:
                                              imageNetwork(myTransient, index),
                                        ),
                                        title: Text(myTransient[index]['name']),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // TextButton.icon(
                                          //     onPressed: () {},
                                          //     icon: Icon(
                                          //       Icons.delete,
                                          //       color: Colors.red[300],
                                          //     ),
                                          //     label: Text(
                                          //       'Delete',
                                          //       style: TextStyle(
                                          //         color: Colors.red[300],
                                          //       ),
                                          //     )),
                                          TextButton.icon(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: ((context) =>
                                                            ViewMessages(
                                                              transient:
                                                                  myTransient[
                                                                          index]
                                                                      ['name'],
                                                            ))));
                                              },
                                              icon: Icon(
                                                Icons.message,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              label: Text(
                                                'View Chat Messages',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              )),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }));
                      }))),
              // const SizedBox(
              //   height: 30,
              // ),
              // const Divider(
              //   height: 30,
              //   thickness: 1.5,
              // ),
              // InputDecorator(
              //     decoration: InputDecoration(
              //       labelText: 'Feedbacks',
              //       labelStyle: const TextStyle(
              //           fontSize: 23, fontWeight: FontWeight.bold),
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(10.0),
              //       ),
              //     ),
              //     child: StreamBuilder<QuerySnapshot>(
              //         stream: FirebaseFirestoreService.instance.readFeedbacks(),
              //         builder: ((context, snapshot) {
              //           List<QueryDocumentSnapshot> feedbacks = [];
              //           if (snapshot.hasData) {
              //             for (final transient in snapshot.data!.docs) {
              //               if (transient['managedBy'] ==
              //                   FirebaseAuth.instance.currentUser!.email) {
              //                 feedbacks.add(transient);
              //               }
              //             }
              //           }
              //           return ListView.builder(
              //               itemCount: feedbacks.length,
              //               physics: const NeverScrollableScrollPhysics(),
              //               shrinkWrap: true,
              //               itemBuilder: ((context, index) {
              //                 return Card(
              //                   elevation: 5.0,
              //                   child: Padding(
              //                     padding: const EdgeInsets.all(8.0),
              //                     child: Column(
              //                       children: [
              //                         ListTile(
              //                           leading: const Icon(
              //                             Icons.star,
              //                             color: Colors.yellow,
              //                           ),
              //                           title:
              //                               Text(feedbacks[index]['managedBy']),
              //                           subtitle:
              //                               Text(feedbacks[index]['feedback']),
              //                         ),
              //                         const SizedBox(
              //                           height: 5,
              //                         ),
              //                         Row(
              //                           mainAxisAlignment:
              //                               MainAxisAlignment.end,
              //                           children: [
              //                             const Icon(
              //                               Icons.verified_user_outlined,
              //                               color: Colors.green,
              //                             ),
              //                             Text(feedbacks[index]['by']),
              //                           ],
              //                         ),
              //                       ],
              //                     ),
              //                   ),
              //                 );
              //               }));
              //         }))),
            ],
          ),
        ),
      ),
    );
  }

  Image imageNetwork(
      List<QueryDocumentSnapshot<Object?>> myTransient, int index) {
    return Image.network(
      myTransient[index]['cover_page'],
      width: 500,
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
}
