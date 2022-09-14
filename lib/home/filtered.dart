import 'package:flutter/material.dart';
import 'package:telenant/home/viewmore.dart';
import 'package:telenant/model.dart';

class ShowFiltered extends StatefulWidget {
  const ShowFiltered({Key? key}) : super(key: key);

  @override
  State<ShowFiltered> createState() => _ShowFilteredState();
}

class _ShowFilteredState extends State<ShowFiltered> {
  var test = [
    details(
      name: 'Pamela',
      contact: '09085272866',
      website: 'https://www.facebook.com/lenwilbaguio',
      coverPage:
          'https://axtgsckh4xo4.compat.objectstorage.ap-singapore-1.oraclecloud.com/baguio-visita/QuX1l5I632omTzYYFIpNVyiCYYCch1HWQKyFfeDq.jpg',
      bedrooms: 1,
      location: '23 Villain Street Engrs Hill',
      priceRange: PriceRange(
        min: 200,
        max: 300,
      ),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Telenants'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '1 Found Properties',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              InkWell(
                splashColor: Colors.blueAccent,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: ((context) => ViewMore(
                            detail: test[0],
                          ))));
                },
                child: Card(
                  elevation: 3.0,
                  shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(style: BorderStyle.none)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: SizedBox(
                          height: 200,
                          width: double.maxFinite,
                          child: Image.network(
                            test[0].coverPage.toString(),
                            fit: BoxFit.fill,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              test[0].name.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text('${test[0].bedrooms.toString()} Bed'),
                            // Padding(
                            //   padding: EdgeInsets.only(left: 5.0, right: 5.0),
                            //   child: Text('|'),
                            // ),
                            // Text('1 Restroom'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_rounded,
                              color: Colors.grey,
                            ),
                            Text(test[0].location.toString()),
                            const Spacer(),
                            const Text(
                              'View More',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                      const Divider(
                        color: Colors.blue,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
