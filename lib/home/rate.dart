import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:telenant/models/RateModel.dart';

import '../FirebaseServices/services.dart';

class RateService extends StatefulWidget {
  final String transient;
  const RateService({super.key, required this.transient});

  @override
  State<RateService> createState() => _RateServiceState();
}

class _RateServiceState extends State<RateService> {
  double _ratingStar = 3.5;
  final TextEditingController _commentController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transient),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5.0,
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rating: $_ratingStar',
                        style: const TextStyle(fontSize: 25),
                      ),
                      AnimatedRatingStars(
                        initialRating: 3.5,
                        minRating: 0.0,
                        maxRating: 5.0,
                        filledColor: Colors.amber,
                        emptyColor: Colors.grey,
                        filledIcon: Icons.star,
                        halfFilledIcon: Icons.star_half,
                        emptyIcon: Icons.star_border,
                        onChanged: (double rating) {
                          // Handle the rating change here
                          print('Rating: $rating');
                          setState(() {
                            _ratingStar = rating;
                          });
                        },
                        displayRatingValue: true,
                        interactiveTooltips: true,
                        customFilledIcon: Icons.star,
                        customHalfFilledIcon: Icons.star_half,
                        customEmptyIcon: Icons.star_border,
                        starSize: 30.0,
                        animationDuration: const Duration(milliseconds: 300),
                        animationCurve: Curves.easeInOut,
                        readOnly: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment',
                  style: TextStyle(fontSize: 25),
                ),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0),
                  )),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              RateModel details = RateModel(
                user: user!.email,
                rating: _ratingStar,
                comment: _commentController.text,
                establishment: widget.transient,
              );
              try {
                await FirebaseFirestoreService.instance.addRating(details);
                _commentController.clear();
                const snackBar = SnackBar(
                  content: Text('Thank you for the feedback!'),
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } on FirebaseException catch (ex) {
                throw ex.message.toString();
              }
            },
            style: ElevatedButton.styleFrom(
                fixedSize: const Size(200, 45), elevation: 5.0),
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }
}
