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
            .retrieveChatMessages(widget.transient),
        builder: ((context, snapshot) {
          List<QueryDocumentSnapshot> messages = [];
          if (snapshot.hasData) {
            for (final message in snapshot.data!.docs) {
              messages.add(message);
            }
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
                  itemCount: messages.length,
                  itemBuilder: ((context, index) {
                    return user!.email != messages[index]['from']
                        ? InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) => ChatScreen(
                                        transient: details(
                                          name: messages[index]['to'],
                                        ),
                                      ))));
                            },
                            child: Card(
                              elevation: 5.0,
                              child: ListTile(
                                title: Text(messages[index]['from']),
                                trailing: const Icon(Icons.arrow_forward_ios),
                              ),
                            ))
                        : const SizedBox.shrink();
                  }));
        }),
      ),
    );
  }
}
