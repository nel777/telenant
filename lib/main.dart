import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/home/admin/landingpage.dart';
import 'package:telenant/home/homepage.dart';

import 'authentication/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loggedIn = false;
  String email = '';
  @override
  void initState() {
    fetchData();
    super.initState();
  }

  void fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('userEmail'));
    if (prefs.getString('userEmail') != null) {
      setState(() {
        loggedIn = true;
        email = prefs.getString('userEmail').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: loggedIn
          ? email.contains('telenant.admin.com')
              ? const AdminHomeView()
              : const HomePage()
          : const LoginPage(),
    );
  }
}
