import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telenant/models/chatmodel.dart';
import 'package:telenant/models/model.dart';

import '../models/RateModel.dart';

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

  Stream<QuerySnapshot<Object?>> retrieveChatMessages(String name) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
          .doc(name)
          .collection('messages')
          .orderBy('timepressed')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Stream<QuerySnapshot<Object?>> testretrieveChatMessages(String name) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
          .doc(name)
          .collection('messages')
          .orderBy('timepressed')
          .snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  Stream<QuerySnapshot<Object?>> readFeedbacks() {
    try {
      return FirebaseFirestore.instance.collection('feedbacks').snapshots();
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  sendChatMessages(String name, MessageModel message) {
    try {
      return FirebaseFirestore.instance
          .collection("chatMessaging")
          .doc(name)
          .collection('messages')
          .doc()
          .set(message.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addTransient(details detail) {
    try {
      return FirebaseFirestore.instance
          .collection("transientDetails")
          .doc()
          .set(detail.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }

  addRating(RateModel detail) {
    try {
      return FirebaseFirestore.instance
          .collection("ratings")
          .doc()
          .set(detail.toJson());
    } on FirebaseException catch (ex) {
      throw ex.message.toString();
    }
  }
}
