import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chatmessage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final List<ChatMessage> messages = [];
  bool isComposing = false;
  User? user = FirebaseAuth.instance.currentUser;

  void _onSubmitted(String text) {
    _textController.clear();

    var message = ChatMessage(
        text: text,
        myname: user!.displayName.toString(),
        animationController: AnimationController(
            duration: const Duration(milliseconds: 500), vsync: this));
    setState(() {
      messages.insert(messages.length, message);
      isComposing = false;
    });
    message.animationController.forward();
  }

  @override
  void dispose() {
    for (var message in messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  Widget _layoutTextField() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Here"),
      ),
      body: Column(
        children: [
          Flexible(
              child: ListView.builder(
            itemBuilder: (_, index) {
              return messages[index];
            },
            itemCount: messages.length,
            padding: const EdgeInsets.all(8),
          )),
          const Divider(
            height: 7,
          ),
          _buildTextField()
        ],
      ),
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
                onFieldSubmitted: (text) {
                  if (isComposing) {
                    _onSubmitted(text);
                  }
                },
                onChanged: (text) {
                  setState(() {
                    if (text.isNotEmpty) {
                      isComposing = true;
                    } else {
                      isComposing = false;
                    }
                  });
                },
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: !isComposing
                  ? null
                  : () {
                      _onSubmitted(_textController.text);
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
