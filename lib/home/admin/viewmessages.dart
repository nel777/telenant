import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/chatmessaging/chatscreen.dart';
import 'package:telenant/models/model.dart';

class ViewMessages extends StatefulWidget {
  final String transient;
  const ViewMessages({super.key, required this.transient});

  @override
  State<ViewMessages> createState() => _ViewMessagesState();
}

class _ViewMessagesState extends State<ViewMessages> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('View Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestoreService.instance
            .testretrieveChatMessages(widget.transient),
        builder: ((context, snapshot) {
          List<QueryDocumentSnapshot> messages = [];
          List<Map<String, dynamic>> emails = [];
          List<dynamic> result = [];
          if (snapshot.hasData) {
            for (final message in snapshot.data!.docs) {
              messages.add(message);
              // for (var element in messages) {
              //   if (element['from'] == message['from']) {
              //     messages.remove(element);
              //   }
              // }
            }

            for (var element in messages) {
              // print(emails.contains(element['from']));
              if (!element['from'].toString().contains('telenant.admin.com')) {
                emails.add({
                  'email': element['from'],
                  'transient_name': element['transient_name'],
                });
              }
            }
            final jsonList = emails.map((e) => jsonEncode(e)).toList();
            final uniqueEmails = jsonList.toSet().toList();
            result = uniqueEmails.map((e) => jsonDecode(e)).toList();
          }
          return messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 250,
                        child: Container(
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.contain,
                                  image:
                                      AssetImage('assets/images/inbox.jpg'))),
                        ),
                      ),
                      const Text(
                        'No Messages to Show',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: result.length,
                  itemBuilder: ((context, index) {
                    return InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: ((context) => ChatScreen(
                                    from: result[index]['email'],
                                    sendto: result[index]['email'],
                                    transient: Details(
                                      name: result[index]['transient_name'],
                                    ),
                                  ))));
                        },
                        child: Card(
                          elevation: 5.0,
                          child: ListTile(
                            title: Text(result[index]['email']),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        ));
                  }));
        }),
      ),
    );
  }
}
