import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final AnimationController animationController;
  final String myname;

  const ChatMessage(
      {Key? key,
      required this.text,
      required this.animationController,
      required this.myname})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              child: CircleAvatar(
                child: Text(myname[0].toUpperCase() + myname[1].toUpperCase()),
              ),
              margin: const EdgeInsets.only(right: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myname,
                  style: Theme.of(context).textTheme.headline4,
                ),
                Container(
                  child: Text(text),
                  margin: const EdgeInsets.only(top: 5),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
