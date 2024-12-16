//create a stateless widget that accepts list of Map<String,dynamic> as data, and display data with gridview with button
import 'package:flutter/material.dart';
import 'package:telenant/home/viewmore.dart';
import 'package:telenant/models/model.dart';

class NearMeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const NearMeWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Transients (100km radius)'),
      ),
      body: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          //     maxCrossAxisExtent: 200,
          //     childAspectRatio: 0.7,
          //     crossAxisSpacing: 10,
          //     mainAxisSpacing: 10),
          itemCount: data.length,
          itemBuilder: (BuildContext ctx, index) {
            return InkWell(
                splashColor: Colors.blueAccent,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: ((context) => ViewMore(
                            detail: Details(
                              name: data[index]['data']['name'],
                              gallery: data[index]['data']['gallery']
                                  as List<dynamic>,
                              location: data[index]['data']['location'],
                              contact: data[index]['data']['contact'],
                              type: data[index]['data']['type'],
                              website: data[index]['data']['website'],
                              managedBy: data[index]['data']['managedBy'],
                              coverPage: data[index]['data']['cover_page'],
                            ),
                          ))));
                },
                child: Card(
                    elevation: 5.0,
                    shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(style: BorderStyle.none)),
                    child:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                              height: 100,
                              width: 100,
                              child: Image.network(
                                data[index]['data']['cover_page'].toString(),
                                fit: BoxFit.cover,
                              ))),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data[index]['data']['name'].toString(),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              data[index]['data']['location'].toString(),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            Divider(),
                            Text(
                              data[index]['data']['type'].toString(),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    ])));
          }),
    );
  }
}
