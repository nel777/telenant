import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';

import '../models/chatmodel.dart';
import '../models/model.dart';
import 'chatmessage.dart';

class ChatScreen extends StatefulWidget {
  final details transient;
  final String? sendto;
  final String? from;
  const ChatScreen({Key? key, required this.transient, this.sendto, this.from})
      : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();

  bool isComposing = false;
  User? user = FirebaseAuth.instance.currentUser;

  // void _onSubmitted(String text) {
  //   _textController.clear();

  //   var message = ChatMessage(
  //       text: text,
  //       myname: user!.email.toString(),
  //       animationController: AnimationController(
  //           duration: const Duration(milliseconds: 500), vsync: this));
  //   setState(() {
  //     messages.insert(messages.length, message);
  //     isComposing = false;
  //   });
  //   message.animationController.forward();
  // }

  @override
  void dispose() {
    //message.animationController.dispose();
    super.dispose();
  }

  Widget _layoutTextField() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Owner"),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestoreService.instance
              .testretrieveChatMessages(widget.transient.name.toString()),
          builder: ((context, snapshot) {
            final List<ChatMessage> messages = [];
            if (snapshot.hasData) {
              for (final thismessage in snapshot.data!.docs) {
                if (widget.from == null) {
                  if (thismessage['from'] == user!.email ||
                      thismessage['to'] == user!.email) {
                    var message = ChatMessage(
                        email: user!.email.toString(),
                        text: thismessage['message'],
                        myname: thismessage['from'],
                        animationController: AnimationController(
                            duration: const Duration(milliseconds: 500),
                            vsync: this));
                    messages.insert(messages.length, message);
                    message.animationController.forward();
                  }
                } else {
                  print(widget.from);
                  if ((thismessage['from'] == widget.from &&
                          thismessage['to'] == user!.email) ||
                      (thismessage['to'] == widget.from &&
                          thismessage['from'] == user!.email)) {
                    var message = ChatMessage(
                        email: user!.email.toString(),
                        text: thismessage['message'],
                        myname: thismessage['from'],
                        animationController: AnimationController(
                            duration: const Duration(milliseconds: 500),
                            vsync: this));
                    messages.insert(messages.length, message);
                    message.animationController.forward();
                  }
                }
              }
            }
            return Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    //shrinkWrap: true,
                    itemBuilder: (_, index) {
                      return messages[index];
                    },
                    itemCount: messages.length,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                //const Spacer(),
                const Divider(
                  height: 7,
                ),
                _buildTextField()
              ],
            );
          })),
    );
  }

  Widget _buildTextField() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Flexible(
              child: TextFormField(
                controller: _textController,
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_textController.text.isEmpty) {
                } else {
                  try {
                    FirebaseFirestoreService.instance.sendChatMessages(
                        widget.transient.name.toString(),
                        MessageModel(
                          to: user!.email!.contains('telenant.admin.com')
                              ? widget.sendto
                              : widget.transient.managedBy,
                          from: user!.email.toString(),
                          message: _textController.text,
                          timepressed: Timestamp.now(),
                          transientname: widget.transient.name,
                        ));
                    _textController.clear();
                  } on FirebaseException catch (ex) {
                    throw ex.message.toString();
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _layoutTextField();
  }
}
