class PincodeModel {
  final String status;
  final String pincode;
  final PincodeData data;

  PincodeModel({
    required this.status,
    required this.pincode,
    required this.data,
  });

  factory PincodeModel.fromJson(Map<String, dynamic> json) {
    return PincodeModel(
      status: json['status'],
      pincode: json['pincode'],
      data: PincodeData.fromJson(json['data']),
    );
  }
}

class PincodeData {
  final List<PostOffice> postOffices;
  final String message;
  final String status;

  PincodeData({
    required this.postOffices,
    required this.message,
    required this.status,
  });

  factory PincodeData.fromJson(Map<String, dynamic> json) {
    return PincodeData(
      postOffices: (json['post_offices'] as List)
          .map((i) => PostOffice.fromJson(i))
          .toList(),
      message: json['message'],
      status: json['status'],
    );
  }
}

class PostOffice {
  final String name;
  final String? district;
  final String? state;

  PostOffice({
    required this.name,
    this.district,
    this.state,
  });

  factory PostOffice.fromJson(Map<String, dynamic> json) {
    return PostOffice(
      name: json['Name'],
      district: json['District'],
      state: json['State'],
    );
  }
}
