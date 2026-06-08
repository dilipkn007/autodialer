part of 'default.dart';

class ListEnablersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListEnablersVariablesBuilder(this._dataConnect, );
  Deserializer<ListEnablersData> dataDeserializer = (dynamic json)  => ListEnablersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListEnablersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListEnablersData, void> ref() {
    
    return _dataConnect.query("ListEnablers", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListEnablersUsers {
  final String uid;
  final String phone;
  final String name;
  final String? email;
  final String? avatarInitials;
  final bool isActive;
  final Timestamp createdAt;
  ListEnablersUsers.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  avatarInitials = json['avatarInitials'] == null ? null : nativeFromJson<String>(json['avatarInitials']),
  isActive = nativeFromJson<bool>(json['isActive']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnablersUsers otherTyped = other as ListEnablersUsers;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    avatarInitials == otherTyped.avatarInitials && 
    isActive == otherTyped.isActive && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode, name.hashCode, email.hashCode, avatarInitials.hashCode, isActive.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['phone'] = nativeToJson<String>(phone);
    json['name'] = nativeToJson<String>(name);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (avatarInitials != null) {
      json['avatarInitials'] = nativeToJson<String?>(avatarInitials);
    }
    json['isActive'] = nativeToJson<bool>(isActive);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListEnablersUsers({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    this.avatarInitials,
    required this.isActive,
    required this.createdAt,
  });
}

@immutable
class ListEnablersData {
  final List<ListEnablersUsers> users;
  ListEnablersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListEnablersUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnablersData otherTyped = other as ListEnablersData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListEnablersData({
    required this.users,
  });
}

