import 'package:flutter/material.dart';
import 'package:telenant/home/admin/addtransient.dart';
import 'package:telenant/home/admin/homepageadmin.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/admin.jpg'),
                    fit: BoxFit.cover)),
          ),
          Positioned(
              bottom: 30,
              left: 10,
              right: 10,
              child: Container(
                height: 250,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'Welcome ',
                              style: textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 35,
                              )),
                          TextSpan(
                              text: 'to ',
                              style: textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 35,
                              )),
                          TextSpan(
                              text: 'Telenant\n',
                              style: textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 35,
                              )),
                          TextSpan(
                              text:
                                  'As an admin choose an action below to start',
                              style: textTheme.titleMedium),
                        ]),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) =>
                                      const ViewTransient())));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                fixedSize: const Size(double.maxFinite, 40)),
                            child: Text(
                              'Home',
                              style: textTheme.titleMedium!
                                  .copyWith(color: colorScheme.onPrimary),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) =>
                                      const AddTransient())));
                            },
                            style: ElevatedButton.styleFrom(
                                fixedSize: const Size(double.maxFinite, 40)),
                            child: Text(
                              'Add Transient',
                              style: textTheme.titleMedium!
                                  .copyWith(color: colorScheme.onPrimary),
                            )),
                      )
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
