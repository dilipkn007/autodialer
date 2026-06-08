part of 'default.dart';

class GetCurrentUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentUserData> dataDeserializer = (dynamic json)  => GetCurrentUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentUserData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetCurrentUserData, void> ref() {
    
    return _dataConnect.query("GetCurrentUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentUserUser {
  final String uid;
  final String phone;
  final String name;
  final String? email;
  final EnumValue<UserRole> role;
  final String? avatarInitials;
  final bool isActive;
  final Timestamp createdAt;
  GetCurrentUserUser.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  role = userRoleDeserializer(json['role']),
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

    final GetCurrentUserUser otherTyped = other as GetCurrentUserUser;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    role == otherTyped.role && 
    avatarInitials == otherTyped.avatarInitials && 
    isActive == otherTyped.isActive && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode, name.hashCode, email.hashCode, role.hashCode, avatarInitials.hashCode, isActive.hashCode, createdAt.hashCode]);
  

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
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetCurrentUserUser({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    this.avatarInitials,
    required this.isActive,
    required this.createdAt,
  });
}

@immutable
class GetCurrentUserData {
  final GetCurrentUserUser? user;
  GetCurrentUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetCurrentUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserData otherTyped = other as GetCurrentUserData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetCurrentUserData({
    this.user,
  });
}

