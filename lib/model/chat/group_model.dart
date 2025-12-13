class GroupModel {
  GroupModel({
    bool? status,
    String? message,
    GroupData? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  GroupModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? GroupData.fromJson(json['data']) : null;
  }

  bool? _status;
  String? _message;
  GroupData? _data;

  bool? get status => _status;
  String? get message => _message;
  GroupData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data!.toJson();
    }
    return map;
  }
}


class GroupData {

  GroupData({
    this.id,
    this.name,
    this.status,
    this.date,
    this.time,
  });

  GroupData.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    status = json['status'];
    date = json['date'];
    time = json['time'];
  }

  int? id;
  String? name;
  String? status;
  String? date;
  String? time;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['status'] = status;
    map['date'] = date;
    map['time'] = time;
    return map;
  }
}
