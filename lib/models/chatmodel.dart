import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String? to;
  String? from;
  String? message;
  String? transientname;
  Timestamp? timepressed;

  MessageModel({
    this.to,
    this.from,
    this.message,
    this.transientname,
    this.timepressed,
  });

  MessageModel.fromJson(Map<String, dynamic> json) {
    to = json['to'];
    from = json['from'];
    message = json['message'];
    transientname = json['transientname'];
    timepressed = json['timepressed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to;
    data['from'] = from;
    data['message'] = message;
    data['transient_name'] = transientname;
    data['timepressed'] = timepressed;
    return data;
  }

  MessageModel.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc)
      : to = doc.data()!["to"],
        from = doc.data()!["from"],
        message = doc.data()!["message"],
        transientname = doc.data()!["transientname"],
        timepressed = doc.data()!["timepressed"];
}
