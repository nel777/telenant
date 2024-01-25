class RateModel {
  double? rating;
  String? comment;
  String? user;
  String? establishment;

  RateModel({this.rating, this.comment, this.user, this.establishment});

  RateModel.fromJson(Map<String, dynamic> json) {
    rating = json['rating'];
    comment = json['comment'];
    user = json['user'];
    establishment = json['establishment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rating'] = rating;
    data['comment'] = comment;
    data['user'] = user;
    data['establishment'] = establishment;
    return data;
  }
}
