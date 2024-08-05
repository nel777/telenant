import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/authentication/login.dart';
import 'package:telenant/home/components/near_me_widgets.dart';
import 'package:telenant/home/filtered.dart';
import 'package:telenant/home/searchbox.dart';
import 'package:telenant/utils/filter_transients.dart';
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
  int currentPageIndex = 0;
  late Future<List<Map<String, dynamic>>> _nearbyApartments;
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
  late TextEditingController searchController;
  bool fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  // @override
  // void dispose() {
  //   searchController.dispose();
  //   super.dispose();
  // }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
  }

  Future<void> _fetchNearbyApartments(LocationData location) async {
    try {
      _nearbyApartments = findNearbyApartments(location,
          100000); //km-m; 1000m = 1km; therefore here it is set to 100km radius
      _nearbyApartments.then((value) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return NearMeWidget(
            data: value,
          );
        }));
        setState(() {
          fetchingLocation = false;
        });
      }).onError((error, stackTrace) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Error'),
                content: Text(error.toString()),
              );
            });
        setState(() {
          fetchingLocation = false;
        });
      });
      //display a alertdialog for error
    } catch (e) {
      print('Error getting location or apartments: $e');
    }
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
            icon: const Icon(Icons.logout, color: Colors.black87)),
        title: const Text(
          'Filter',
          style: TextStyle(color: Colors.black87),
        ),
        actions: const [
          // TextButton.icon(
          //     onPressed: () {},
          //     icon: const Icon(Icons.refresh, color: Colors.black87),
          //     label: const Text(
          //       'Reset',
          //       style: TextStyle(color: Colors.black87),
          //     ))
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
          if (index == 0) {
            searchController = TextEditingController();
          }
        },
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
          //controller: _scrollController,
          child: currentPageIndex == 0 ? homeWidget() : profileWidget()),
    );
  }

  //a column of profile page that displays id number and email, reading from the function readUserDetails
  Padding profileWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 20,
          ),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestoreService.instance
                .getUserDetails(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    profileCard('ID Number: ${data['idNumber']}'),
                    profileCard('Email: ${data['email']}'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }

  Card profileCard(String data) {
    return Card(
      child: ListTile(
        title: Text(
          data,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Padding homeWidget() {
    return Padding(
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
                  const Row(
                    children: [
                      Icon(Icons.location_searching_rounded),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Available Locations',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black38)),
                          labelText: 'Select Location',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 1.5, color: Colors.black38),
                              borderRadius: BorderRadius.circular(10.0))),
                      value: _selectedValue,
                      isExpanded: true,
                      isDense: true,
                      items: listOfValue.map((String val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Text(
                                  val,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value.toString();
                        });
                      }),
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'OR',
                      style: TextStyle(fontSize: 18),
                    ),
                  )),
                  Center(
                    child: fetchingLocation
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Fetching Current Location'),
                              LinearProgressIndicator(),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              setState(() {
                                fetchingLocation = true;
                              });
                              Location location = Location();
                              bool serviceEnabled;
                              PermissionStatus permissionGranted;
                              LocationData locationData;
                              serviceEnabled = await location.serviceEnabled();
                              if (!serviceEnabled) {
                                serviceEnabled =
                                    await location.requestService();
                                if (!serviceEnabled) {
                                  return;
                                }
                              }

                              permissionGranted =
                                  await location.hasPermission();
                              if (permissionGranted ==
                                  PermissionStatus.denied) {
                                permissionGranted =
                                    await location.requestPermission();
                                if (permissionGranted !=
                                    PermissionStatus.granted) {
                                  return;
                                }
                              }

                              locationData = await location.getLocation();
                              await _fetchNearbyApartments(locationData);
                            },
                            label: const Text('Near Me'),
                            style: ElevatedButton.styleFrom(
                                elevation: 3.0,
                                fixedSize: const Size(double.maxFinite, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.location_on),
                          ),
                  ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            propertyType(Icons.apartment, 'Apartment'),
                            propertyType(Icons.house, 'Townhouse'),
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
                      const Row(
                        children: [
                          Icon(Icons.money_rounded),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Price Range Per Head',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
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
                                      focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.black38)),
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      labelText: 'From',
                                      labelStyle: const TextStyle(
                                          color: Colors.black87),
                                      prefixIcon: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
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
                                              BorderRadius.circular(10.0))),
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
                                  onChanged: (value) {
                                    setState(() {
                                      min = int.parse(value.toString());
                                    });
                                  }),
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
                                      focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.black38)),
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      labelText: 'To',
                                      labelStyle: const TextStyle(
                                          color: Colors.black87),
                                      prefixIcon: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
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
                                              BorderRadius.circular(10.0))),
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
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text(
                        'OR',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w400),
                      )),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Search by Name',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
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
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
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
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: ((context) => ShowFiltered(
                                  filtered: filtered,
                                ))));
                      },
                      label: const Text('Proceed')),
                ],
              ),
            );
          }),
        ));
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
