import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:telenant/models/model.dart';

import '../chatmessaging/chatscreen.dart';

class ViewMore extends StatefulWidget {
  final details detail;
  const ViewMore({Key? key, required this.detail}) : super(key: key);

  @override
  State<ViewMore> createState() => _ViewMoreState();
}

class _ViewMoreState extends State<ViewMore> {
  // final List<String> imageList = [
  //   'https://visita-storage-staging.s3.ap-southeast-1.amazonaws.com/31/IMG_20220324_212353.jpg',
  //   'https://visita-storage-staging.s3.ap-southeast-1.amazonaws.com/30/IMG_20220324_212329.jpg',
  //   'https://visita-storage-staging.s3.ap-southeast-1.amazonaws.com/32/IMG_20220324_212508.jpg',
  //   'https://visita-storage-staging.s3.ap-southeast-1.amazonaws.com/33/IMG_20220324_212535.jpg'
  // ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          //backgroundColor: Colors.transparent,
          //elevation: 0,
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                //color: Colors.black,
              )),
          title: Text(
            widget.detail.name.toString(),
            //style: const TextStyle(fontSize: 28),
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 70,
            child: Stack(
              children: [
                const Positioned(
                    top: 0,
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
                    top: 50,
                    //left: 54.9,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 5.0,
                            shape: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    style: BorderStyle.solid, width: 0.5),
                                borderRadius: BorderRadius.circular(2)),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 20,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        left: 8.0, right: 8.0, top: 8.0),
                                    child: Text(
                                      'Contacts',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19),
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.black,
                                  ),
                                  iconText(Icons.call,
                                      widget.detail.contact.toString()),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  iconText(Icons.streetview,
                                      widget.detail.location.toString()),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  iconText(Icons.web, 'Visit Website'),
                                  const Divider()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                Positioned(
                    top: 230,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Gallery',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          height: 280,
                          width: 300,
                          margin: const EdgeInsets.all(15),
                          child: CarouselSlider.builder(
                            itemCount: widget.detail.gallery!.length,
                            options: CarouselOptions(
                              enlargeCenterPage: true,
                              height: 350,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              reverse: false,
                              aspectRatio: 5.0,
                            ),
                            itemBuilder: (context, i, id) {
                              //for onTap to redirect to another screen
                              return GestureDetector(
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white,
                                      )),
                                  //ClipRRect for image border radius
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      widget.detail.gallery![i],
                                      width: 500,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  var url = widget.detail.gallery![i];
                                  print(url.toString());
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 16,
                            height: 2,
                            color: Colors.black54,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: ((context) => ChatScreen(
                                          transient: widget.detail,
                                        ))));
                              },
                              style: ElevatedButton.styleFrom(
                                  // /backgroundColor: Colors.,
                                  fixedSize: Size(
                                      MediaQuery.of(context).size.width - 16,
                                      45)),
                              icon: const Icon(Icons.room_service_rounded),
                              label: const Text('Book/Reserve Transient')),
                        ),
                      ],
                    )),

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
            ),
          ),
        ));
  }

  Image imageNetwork(String url) {
    return Image.network(
      url,
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
