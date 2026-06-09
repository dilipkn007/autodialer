part of 'default.dart';

class AdminUpsertUserVariablesBuilder {
  String uid;
  String phone;
  String name;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  UserRole role;
  Optional<String> _avatarInitials = Optional.optional(nativeFromJson, nativeToJson);
  bool isActive;

  final FirebaseDataConnect _dataConnect;  AdminUpsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  AdminUpsertUserVariablesBuilder avatarInitials(String? t) {
   _avatarInitials.value = t;
   return this;
  }

  AdminUpsertUserVariablesBuilder(this._dataConnect, {required  this.uid,required  this.phone,required  this.name,required  this.role,required  this.isActive,});
  Deserializer<AdminUpsertUserData> dataDeserializer = (dynamic json)  => AdminUpsertUserData.fromJson(jsonDecode(json));
  Serializer<AdminUpsertUserVariables> varsSerializer = (AdminUpsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AdminUpsertUserData, AdminUpsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AdminUpsertUserData, AdminUpsertUserVariables> ref() {
    AdminUpsertUserVariables vars= AdminUpsertUserVariables(uid: uid,phone: phone,name: name,email: _email,role: role,avatarInitials: _avatarInitials,isActive: isActive,);
    return _dataConnect.mutation("AdminUpsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AdminUpsertUserUserUpsert {
  final String uid;
  AdminUpsertUserUserUpsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminUpsertUserUserUpsert otherTyped = other as AdminUpsertUserUserUpsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  AdminUpsertUserUserUpsert({
    required this.uid,
  });
}

@immutable
class AdminUpsertUserData {
  final AdminUpsertUserUserUpsert user_upsert;
  AdminUpsertUserData.fromJson(dynamic json):
  
  user_upsert = AdminUpsertUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminUpsertUserData otherTyped = other as AdminUpsertUserData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  AdminUpsertUserData({
    required this.user_upsert,
  });
}

@immutable
class AdminUpsertUserVariables {
  final String uid;
  final String phone;
  final String name;
  late final Optional<String>email;
  final UserRole role;
  late final Optional<String>avatarInitials;
  final bool isActive;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AdminUpsertUserVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']),
  role = UserRole.values.byName(json['role']),
  isActive = nativeFromJson<bool>(json['isActive']) {
  
  
  
  
  
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value = json['email'] == null ? null : nativeFromJson<String>(json['email']);
  
  
  
    avatarInitials = Optional.optional(nativeFromJson, nativeToJson);
    avatarInitials.value = json['avatarInitials'] == null ? null : nativeFromJson<String>(json['avatarInitials']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminUpsertUserVariables otherTyped = other as AdminUpsertUserVariables;
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
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    json['role'] = 
    role.name
    ;
    if(avatarInitials.state == OptionalState.set) {
      json['avatarInitials'] = avatarInitials.toJson();
    }
    json['isActive'] = nativeToJson<bool>(isActive);
    return json;
  }

  AdminUpsertUserVariables({
    required this.uid,
    required this.phone,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarInitials,
    required this.isActive,
  });
}

