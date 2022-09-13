import 'package:flutter/material.dart';
import 'package:telenant/model.dart';

class ViewMore extends StatefulWidget {
  final details detail;
  const ViewMore({Key? key, required this.detail}) : super(key: key);

  @override
  State<ViewMore> createState() => _ViewMoreState();
}

class _ViewMoreState extends State<ViewMore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.black,
              )),
          title: Text(
            widget.detail.name.toString(),
            style: const TextStyle(color: Colors.black, fontSize: 28),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: Image.network(
                    widget.detail.coverPage.toString(),
                    fit: BoxFit.fill,
                  )),
            ),
            // Positioned(
            //   top: 0,
            //   child: Container(
            //     height: 200,
            //     width: MediaQuery.of(context).size.width,
            //     decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
            //     //borderRadius: BorderRadius.circular(10.0)),
            //   ),
            // ),
            const Positioned(
                top: 200,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Details',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                )),
            Positioned(
                top: 250,
                left: 54.9,
                child: Center(
                  child: Card(
                    elevation: 5.0,
                    shape: OutlineInputBorder(
                        borderSide: const BorderSide(style: BorderStyle.none),
                        borderRadius: BorderRadius.circular(5)),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                left: 8.0, right: 8.0, top: 8.0),
                            child: Text(
                              'Contacts',
                            ),
                          ),
                          const Divider(
                            color: Colors.black,
                          ),
                          iconText(
                              Icons.call, widget.detail.contact.toString()),
                          const SizedBox(
                            height: 10,
                          ),
                          iconText(Icons.streetview,
                              widget.detail.location.toString()),
                          const SizedBox(
                            height: 10,
                          ),
                          iconText(Icons.web, 'Visit Website'),
                        ],
                      ),
                    ),
                  ),
                ))
            // Positioned(
            //     top: 60,
            //     child: Text(
            //       widget.detail.name.toString(),
            //       style: const TextStyle(
            //           fontSize: 40,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white),
            //     ))
          ],
        ));
  }

  Padding iconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.green,
          ),
          const SizedBox(
            width: 10,
          ),
          GestureDetector(onTap: () {}, child: Text(text))
        ],
      ),
    );
  }
}
