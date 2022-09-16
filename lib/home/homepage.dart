import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/authentication/login.dart';
import 'package:telenant/home/filtered.dart';
import 'package:telenant/home/searchbox.dart';
import 'package:textfield_search/textfield_search.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedValue = 'Near Town';
  int min = 200;
  int max = 10000;
  List propertyTypes = [];
  List<String> listOfPriceValue = [
    '200',
    '300',
    '400',
    '500',
    '1000',
    '2000',
    '3000',
    '5000',
    '10000'
  ];
  //List dummyList = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];
  TextEditingController searchController = TextEditingController();
  //final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  //barrierDismissible: false,
                  builder: ((context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              logout();
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          const LoginPage())));
                            },
                            child: const Text('Yes'))
                      ],
                    );
                  }));
            },
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
      body: SingleChildScrollView(
          //controller: _scrollController,
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestoreService.instance.readItems(),
                builder: ((context, snapshot) {
                  List<String> listOfValue = ['Near Town'];
                  List<String> listOfTransient = [];
                  if (snapshot.hasData) {
                    for (final detail in snapshot.data!.docs) {
                      listOfValue.add(detail['location']);
                      listOfTransient.add(detail['name']);
                    }
                  }
                  return SizedBox(
                    height: MediaQuery.of(context).size.height,
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
                                    borderSide:
                                        BorderSide(color: Colors.black38)),
                                contentPadding: const EdgeInsets.all(10.0),
                                labelText: 'Select Location',
                                labelStyle:
                                    const TextStyle(color: Colors.black87),
                                prefixIcon: const Icon(
                                  Icons.pin_drop_rounded,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        width: 1.5, color: Colors.black38),
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
                            onChanged: (value) {
                              print(value);
                              setState(() {
                                _selectedValue = value.toString();
                              });
                            }),

                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Property Types',
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  propertyType(Icons.apartment, 'Apartment'),
                                  propertyType(Icons.house, 'Townhouse'),
                                  propertyType(Icons.hotel, 'Hotel'),
                                  // propertyType(
                                  //     Icons.view_timeline_rounded, 'Any'),
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
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: DropdownButtonFormField(
                                        decoration: InputDecoration(
                                            // enabledBorder: const OutlineInputBorder(
                                            //     borderSide: BorderSide(color: Colors.black38)),
                                            //fillColor: Colors.black12,
                                            focusedBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.black38)),
                                            contentPadding:
                                                const EdgeInsets.all(10.0),
                                            labelText: 'From',
                                            labelStyle: const TextStyle(
                                                color: Colors.black87),
                                            prefixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                    width: 1.5,
                                                    color: Colors.black38),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.0))),
                                        value: '300',
                                        isExpanded: true,
                                        items:
                                            listOfPriceValue.map((String val) {
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
                                        onChanged: (value) {
                                          setState(() {
                                            min = int.parse(value.toString());
                                          });
                                        }),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, right: 8.0),
                                    child: Text(
                                      '-',
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black26),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: DropdownButtonFormField(
                                        decoration: InputDecoration(
                                            // enabledBorder: const OutlineInputBorder(
                                            //     borderSide: BorderSide(color: Colors.black38)),
                                            //fillColor: Colors.black12,
                                            focusedBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.black38)),
                                            contentPadding:
                                                const EdgeInsets.all(10.0),
                                            labelText: 'To',
                                            labelStyle: const TextStyle(
                                                color: Colors.black87),
                                            prefixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                    width: 1.5,
                                                    color: Colors.black38),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.0))),
                                        value: '300',
                                        isExpanded: true,
                                        items:
                                            listOfPriceValue.map((String val) {
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
                                        onChanged: (value) {
                                          setState(() {
                                            max = int.parse(value.toString());
                                          });
                                        }),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Divider(
                          color: Colors.black,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                                child: Text(
                              'OR',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                            )),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: const [
                                Icon(Icons.search),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Search by Name',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => Material(
                                      child: SearchDemo(
                                        data: listOfTransient,
                                      ),
                                    ))));
                          },
                          child: TextFieldSearch(
                            label: 'Search',

                            // minStringLength: -1,
                            controller: searchController,
                            initialList: listOfTransient,
                            decoration: const InputDecoration(
                                enabled: false,
                                contentPadding: EdgeInsets.all(15),
                                hintText: 'type in the transient name',
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                ),
                                border: OutlineInputBorder()),
                          ),
                        ),
                        // TextField(
                        //   controller: searchController,
                        //   decoration: const InputDecoration(
                        //       contentPadding: EdgeInsets.all(15),
                        //       hintText: 'type in the transient name',
                        //       hintStyle: TextStyle(
                        //         color: Colors.black,
                        //         fontSize: 18,
                        //         fontStyle: FontStyle.italic,
                        //       ),
                        //       border: OutlineInputBorder()),
                        // ),
                        const SizedBox(
                          height: 50,
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                fixedSize: const Size(double.maxFinite, 40)),
                            onPressed: () {
                              Map<String, int> pricerange = {
                                'min': min,
                                'max': max,
                              };
                              Map<String, dynamic> filtered = {
                                'type': propertyTypes,
                                'location': _selectedValue,
                                'price': pricerange
                              };
                              //print(filtered['price']['min']);
                              //filtered.add(propertyTypes);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) => ShowFiltered(
                                        filtered: filtered,
                                      ))));
                              // print(propertyTypes);
                              // print(_selectedValue);
                              // print(min);
                              // print(max);
                            },
                            child: const Text('Proceed')),
                      ],
                    ),
                  );
                }),
              ))),
    );
  }

  Padding propertyType(IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (type == 'Apartment') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Townhouse') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else if (type == 'Hotel') {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                } else {
                  setState(() {
                    propertyTypes.add(type);
                  });
                }
              } else {
                if (propertyTypes.contains(type)) {
                  setState(() {
                    propertyTypes.remove(type);
                  });
                }
              }
            },
            child: Card(
              elevation: 5.0,
              shape: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 3.0,
                      style: propertyTypes.contains(type)
                          ? BorderStyle.solid
                          : BorderStyle.none,
                      color: Colors.blue)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.blue[800],
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
