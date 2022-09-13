import 'package:flutter/material.dart';
import 'package:telenant/home/filtered.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _selectedValue = 'Near Town';
  List<String> listOfValue = ['Near Town', '2', '3', '4', '5'];
  List<String> listOfPriceValue = ['300', '400', '500', '600', '1000'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87)),
        title: const Text(
          'Filter',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, color: Colors.black87),
              label: const Text(
                'Reset',
                style: TextStyle(color: Colors.black87),
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DropdownButtonFormField(
                decoration: InputDecoration(
                    // enabledBorder: const OutlineInputBorder(
                    //     borderSide: BorderSide(color: Colors.black38)),
                    //fillColor: Colors.black12,
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black38)),
                    contentPadding: const EdgeInsets.all(10.0),
                    labelText: 'Select Location',
                    labelStyle: const TextStyle(color: Colors.black87),
                    prefixIcon: const Icon(
                      Icons.pin_drop_rounded,
                      color: Colors.black38,
                    ),
                    border: OutlineInputBorder(
                        borderSide:
                            const BorderSide(width: 1.5, color: Colors.black38),
                        borderRadius: BorderRadius.circular(10.0))),
                value: _selectedValue,
                isExpanded: true,
                items: listOfValue.map((String val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Row(
                      children: [
                        Text(
                          val,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {}),
            const SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property Types',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      propertyType(Icons.apartment, 'Apartment'),
                      propertyType(Icons.house, 'Townhouse'),
                      propertyType(Icons.hotel, 'Hotel'),
                    ],
                  ),
                )
              ],
            ),
            const Divider(
              color: Colors.black,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.money_rounded),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Price Range',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: DropdownButtonFormField(
                            decoration: InputDecoration(
                                // enabledBorder: const OutlineInputBorder(
                                //     borderSide: BorderSide(color: Colors.black38)),
                                //fillColor: Colors.black12,
                                focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black38)),
                                contentPadding: const EdgeInsets.all(10.0),
                                labelText: 'From',
                                labelStyle:
                                    const TextStyle(color: Colors.black87),
                                prefixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Php',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        width: 1.5, color: Colors.black38),
                                    borderRadius: BorderRadius.circular(10.0))),
                            value: '300',
                            isExpanded: true,
                            items: listOfPriceValue.map((String val) {
                              return DropdownMenuItem(
                                value: val,
                                child: Row(
                                  children: [
                                    Text(
                                      val,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {}),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Text(
                          '-',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: Colors.black26),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: DropdownButtonFormField(
                            decoration: InputDecoration(
                                // enabledBorder: const OutlineInputBorder(
                                //     borderSide: BorderSide(color: Colors.black38)),
                                //fillColor: Colors.black12,
                                focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.black38)),
                                contentPadding: const EdgeInsets.all(10.0),
                                labelText: 'To',
                                labelStyle:
                                    const TextStyle(color: Colors.black87),
                                prefixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Php',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        width: 1.5, color: Colors.black38),
                                    borderRadius: BorderRadius.circular(10.0))),
                            value: '300',
                            isExpanded: true,
                            items: listOfPriceValue.map((String val) {
                              return DropdownMenuItem(
                                value: val,
                                child: Row(
                                  children: [
                                    Text(
                                      val,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {}),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Divider(
              color: Colors.black,
            ),
            const Spacer(),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    fixedSize: const Size(double.maxFinite, 40)),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: ((context) => const ShowFiltered())));
                },
                child: const Text('Search'))
          ],
        ),
      ),
    );
  }

  Padding propertyType(IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {},
            child: Card(
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                ),
              ),
            ),
          ),
          Text(type)
        ],
      ),
    );
  }
}
