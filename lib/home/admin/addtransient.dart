import 'package:flutter/material.dart';

class AddTransient extends StatefulWidget {
  const AddTransient({super.key});

  @override
  State<AddTransient> createState() => _AddTransientState();
}

class _AddTransientState extends State<AddTransient> {
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
              textWithField('Transient Name'),
              textWithField('Location'),
              textWithField('Contact'),
              textWithField('Website URL'),
              priceRange('Price Range'),
              textWithField('Cover Page'),
              textWithField('Location'),
            ],
          ),
        ),
      ),
    );
  }

  Column textWithField(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54))),
        )
      ],
    );
  }

  Column priceRange(String name) {
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
