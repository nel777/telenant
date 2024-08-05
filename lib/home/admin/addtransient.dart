import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlng/latlng.dart';
import 'package:telenant/home/admin/gmap/map.dart';
import 'package:telenant/models/model.dart';

import '../../FirebaseServices/services.dart';

class AddTransient extends StatefulWidget {
  const AddTransient({super.key});

  @override
  State<AddTransient> createState() => _AddTransientState();
}

class _AddTransientState extends State<AddTransient> {
  List<String> list = <String>['Townhouse', 'Apartment'];
  String dropdownValue = 'Townhouse';
  ImagePicker picker = ImagePicker();
  bool loading = false;
  XFile? imagecover;
  LocationLatLng? locationLatLng;
  List<XFile>? imagealbum;
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _transient = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();
  addImage(String from) async {
    if (from == 'imagealbum') {
      try {
        var pickedfiles = await picker.pickMultiImage();
        if (pickedfiles != null) {
          imagealbum = pickedfiles;
          setState(() {});
        } else {
          print("No image is selected.");
        }
      } catch (e) {
        print("error while picking file.");
      }
      setState(() {});
    } else {
      imagecover = await picker.pickImage(source: ImageSource.gallery);
      setState(() {});
    }
  }

  Future<String> uploadFile(File image) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${user!.email.toString()}/${image.path.split('/').last}');
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask;
    return await storageReference.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              textWithField('Transient Name', _transient),
              textWithField('Location', _location),
              textWithField('Contact', _contact),
              textWithField('Website URL', _url),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  priceRange('Price Range Per Head', _min, _max),
                  const SizedBox(
                    width: 10,
                  ),
                  type()
                ],
              ),
              coverPageField('Cover Page'),
              albumPageField('Gallery'),
              const SizedBox(
                height: 50,
              ),
              ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    try {
                      var cover = '';
                      List<dynamic> album = [];
                      if (imagealbum != null) {
                        var imageUrls = await Future.wait(imagealbum!
                            .map((image) => uploadFile(File(image.path))));
                        album = imageUrls;
                      } else {}
                      if (imagecover != null) {
                        var imageUrls =
                            await uploadFile(File(imagecover!.path));
                        cover = imageUrls;
                      }
                      details detail = details(
                        name: _transient.text,
                        location: _location.text,
                        contact: _contact.text,
                        website: _url.text,
                        type: dropdownValue,
                        priceRange: PriceRange(
                          min: int.parse(_min.text),
                          max: int.parse(_max.text),
                        ),
                        locationLatLng: locationLatLng,
                        coverPage: cover.toString(),
                        gallery: album,
                        managedBy: user!.email.toString(),
                      );
                      await FirebaseFirestoreService.instance
                          .addTransient(detail);
                      setState(() {
                        loading = false;
                      });
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('Success'),
                                content: const Text('Uploaded successfully'),
                                actions: <Widget>[
                                  ElevatedButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ));
                    } catch (e) {
                      setState(() {
                        loading = false;
                      });
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('Error'),
                                content: Text(e.toString()),
                                actions: <Widget>[
                                  ElevatedButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(double.maxFinite, 45)),
                  child: loading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Transient'))
            ],
          ),
        ),
      ),
    );
  }

  Column albumPageField(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Column(
          children: [
            InkWell(
              splashColor: Colors.blue,
              onTap: () {
                addImage('imagealbum');
              },
              child: const Card(
                  shape: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(width: 1.0)),
                  child: ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Select Images From Gallery'),
                  )),
            ),
            const SizedBox(
              height: 5,
            ),
            imagealbum != null
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 100,
                            childAspectRatio: 0.5,
                            crossAxisSpacing: 0.5,
                            mainAxisSpacing: 0.5),
                    itemCount: imagealbum!.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return Container(
                        alignment: Alignment.center,
                        // decoration: BoxDecoration(
                        //     color: Colors.amber,
                        //     borderRadius: BorderRadius.circular(15)),
                        child: Image.file(
                          File(imagealbum![index].path),
                          fit: BoxFit.fill,
                        ),
                      );
                    })
                : const SizedBox.shrink()
          ],
        )
      ],
    );
  }

  Column coverPageField(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Column(
          children: [
            InkWell(
              splashColor: Colors.blue,
              onTap: () {
                addImage('imagecover');
              },
              child: const Card(
                  shape: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(width: 1.0)),
                  child: ListTile(
                    leading: Icon(Icons.camera_alt_rounded),
                    title: Text('Select Image From Gallery'),
                  )),
            ),
            imagecover != null
                ? SizedBox(
                    height: 100,
                    width: MediaQuery.of(context).size.width,
                    child: Image.file(
                      File(imagecover!.path),
                      fit: BoxFit.fill,
                    ),
                  )
                : const SizedBox.shrink()
          ],
        )
      ],
    );
  }

  Column type() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
            value: dropdownValue,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            underline: Container(
              height: 2,
              color: Colors.blue[900],
            ),
            onChanged: (String? value) {
              // This is called when the user selects an item.
              setState(() {
                dropdownValue = value!;
              });
            },
            items: list.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList()),
      ],
    );
  }

  Column textWithField(String name, TextEditingController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          controller: controller,
          readOnly: name == 'Location' ? true : false,
          decoration: InputDecoration(
              hintText:
                  name == 'Location' ? 'To select press the pin button' : null,
              contentPadding: const EdgeInsets.all(10),
              suffixIcon: name == 'Location'
                  ? IconButton(
                      onPressed: () {
                        _selectLocation(context);
                      },
                      icon: Icon(Icons.pin_drop_rounded))
                  : null,
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54))),
        )
      ],
    );
  }

  Future<void> _selectLocation(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const InteractiveMapPage(),
      ),
    );

    if (result != null) {
      // Process the returned data
      print(result.toString());
      LatLng location = result['locationLatLng'];
      setState(() {
        _location.text = result['locationText'];
        locationLatLng = LocationLatLng(
          latitude: location.latitude.degrees,
          longitude: location.longitude.degrees,
        );
      });
    }
  }

  Column priceRange(
      String name, TextEditingController min, TextEditingController max) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: min,
                decoration: const InputDecoration(
                    label: Text('min'),
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54))),
              ),
            ),
            const Text(
              '-',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: max,
                decoration: const InputDecoration(
                    label: Text('max'),
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54))),
              ),
            ),
          ],
        )
      ],
    );
  }
}
