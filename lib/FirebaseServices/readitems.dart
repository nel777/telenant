import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFirestoreService {
  FirebaseFirestoreService._();
  static final instance = FirebaseFirestoreService._();
  Stream<QuerySnapshot<Object?>> readItems() {
    try {
      return FirebaseFirestore.instance
          .collection('transientDetails')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }
}
