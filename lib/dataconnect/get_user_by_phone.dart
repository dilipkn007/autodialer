part of 'default.dart';

class GetUserByPhoneVariablesBuilder {
  String phone;

  final FirebaseDataConnect _dataConnect;
  GetUserByPhoneVariablesBuilder(this._dataConnect, {required  this.phone,});
  Deserializer<GetUserByPhoneData> dataDeserializer = (dynamic json)  => GetUserByPhoneData.fromJson(jsonDecode(json));
  Serializer<GetUserByPhoneVariables> varsSerializer = (GetUserByPhoneVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUserByPhoneData, GetUserByPhoneVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetUserByPhoneData, GetUserByPhoneVariables> ref() {
    GetUserByPhoneVariables vars= GetUserByPhoneVariables(phone: phone,);
    return _dataConnect.query("GetUserByPhone", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUserByPhoneUsers {
  final String uid;
  final String phone;
  final String name;
  final String? email;
  final EnumValue<UserRole> role;
  final String? avatarInitials;
  final bool isActive;
  GetUserByPhoneUsers.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  role = userRoleDeserializer(json['role']),
  avatarInitials = json['avatarInitials'] == null ? null : nativeFromJson<String>(json['avatarInitials']),
  isActive = nativeFromJson<bool>(json['isActive']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByPhoneUsers otherTyped = other as GetUserByPhoneUsers;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    role == otherTyped.role && 
    avatarInitials == otherTyped.avatarInitials && 
    isActive == otherTyped.isActive;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode, name.hashCode, email.hashCode, role.hashCode, avatarInitials.hashCode, isActive.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['phone'] = nativeToJson<String>(phone);
    json['name'] = nativeToJson<String>(name);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    json['role'] = 
    userRoleSerializer(role)
    ;
    if (avatarInitials != null) {
      json['avatarInitials'] = nativeToJson<String?>(avatarInitials);
    }
    json['isActive'] = nativeToJson<bool>(isActive);
    return json;
  }

  GetUserByPhoneUsers({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    this.avatarInitials,
    required this.isActive,
  });
}

@immutable
class GetUserByPhoneData {
  final List<GetUserByPhoneUsers> users;
  GetUserByPhoneData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => GetUserByPhoneUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByPhoneData otherTyped = other as GetUserByPhoneData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  GetUserByPhoneData({
    required this.users,
  });
}

@immutable
class GetUserByPhoneVariables {
  final String phone;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUserByPhoneVariables.fromJson(Map<String, dynamic> json):
  
  phone = nativeFromJson<String>(json['phone']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByPhoneVariables otherTyped = other as GetUserByPhoneVariables;
    return phone == otherTyped.phone;
    
  }
  @override
  int get hashCode => phone.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['phone'] = nativeToJson<String>(phone);
    return json;
  }

  GetUserByPhoneVariables({
    required this.phone,
  });
}

