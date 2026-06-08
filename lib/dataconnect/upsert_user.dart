part of 'default.dart';

class UpsertUserVariablesBuilder {
  String uid;
  String phone;
  String name;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _avatarInitials = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpsertUserVariablesBuilder avatarInitials(String? t) {
   _avatarInitials.value = t;
   return this;
  }

  UpsertUserVariablesBuilder(this._dataConnect, {required  this.uid,required  this.phone,required  this.name,});
  Deserializer<UpsertUserData> dataDeserializer = (dynamic json)  => UpsertUserData.fromJson(jsonDecode(json));
  Serializer<UpsertUserVariables> varsSerializer = (UpsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserData, UpsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertUserData, UpsertUserVariables> ref() {
    UpsertUserVariables vars= UpsertUserVariables(uid: uid,phone: phone,name: name,email: _email,avatarInitials: _avatarInitials,);
    return _dataConnect.mutation("UpsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserUserUpsert {
  final String uid;
  UpsertUserUserUpsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserUserUpsert otherTyped = other as UpsertUserUserUpsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpsertUserUserUpsert({
    required this.uid,
  });
}

@immutable
class UpsertUserData {
  final UpsertUserUserUpsert user_upsert;
  UpsertUserData.fromJson(dynamic json):
  
  user_upsert = UpsertUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserData otherTyped = other as UpsertUserData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertUserData({
    required this.user_upsert,
  });
}

@immutable
class UpsertUserVariables {
  final String uid;
  final String phone;
  final String name;
  late final Optional<String>email;
  late final Optional<String>avatarInitials;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']) {
  
  
  
  
  
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

    final UpsertUserVariables otherTyped = other as UpsertUserVariables;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    avatarInitials == otherTyped.avatarInitials;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode, name.hashCode, email.hashCode, avatarInitials.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['phone'] = nativeToJson<String>(phone);
    json['name'] = nativeToJson<String>(name);
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if(avatarInitials.state == OptionalState.set) {
      json['avatarInitials'] = avatarInitials.toJson();
    }
    return json;
  }

  UpsertUserVariables({
    required this.uid,
    required this.phone,
    required this.name,
    required this.email,
    required this.avatarInitials,
  });
}

