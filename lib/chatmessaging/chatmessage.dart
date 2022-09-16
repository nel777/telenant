import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final String email;
  final AnimationController animationController;
  final String myname;

  const ChatMessage(
      {Key? key,
      required this.text,
      required this.animationController,
      required this.myname,
      required this.email})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment:
              email == myname ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            email == myname
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      child: Text(
                          myname[0].toUpperCase() + myname[1].toUpperCase()),
                    ),
                  ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email == myname ? 'You' : myname,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: Text(
                      text,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
