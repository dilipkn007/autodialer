part of 'default.dart';

class UpdateUserProfileVariablesBuilder {
  String uid;
  String name;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _avatarInitials = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateUserProfileVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpdateUserProfileVariablesBuilder avatarInitials(String? t) {
   _avatarInitials.value = t;
   return this;
  }

  UpdateUserProfileVariablesBuilder(this._dataConnect, {required  this.uid,required  this.name,});
  Deserializer<UpdateUserProfileData> dataDeserializer = (dynamic json)  => UpdateUserProfileData.fromJson(jsonDecode(json));
  Serializer<UpdateUserProfileVariables> varsSerializer = (UpdateUserProfileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserProfileData, UpdateUserProfileVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserProfileData, UpdateUserProfileVariables> ref() {
    UpdateUserProfileVariables vars= UpdateUserProfileVariables(uid: uid,name: name,email: _email,avatarInitials: _avatarInitials,);
    return _dataConnect.mutation("UpdateUserProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateUserProfileUserUpdate {
  final String uid;
  UpdateUserProfileUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserProfileUserUpdate otherTyped = other as UpdateUserProfileUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  UpdateUserProfileUserUpdate({
    required this.uid,
  });
}

@immutable
class UpdateUserProfileData {
  final UpdateUserProfileUserUpdate? user_update;
  UpdateUserProfileData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateUserProfileUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserProfileData otherTyped = other as UpdateUserProfileData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateUserProfileData({
    this.user_update,
  });
}

@immutable
class UpdateUserProfileVariables {
  final String uid;
  final String name;
  late final Optional<String>email;
  late final Optional<String>avatarInitials;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserProfileVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
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

    final UpdateUserProfileVariables otherTyped = other as UpdateUserProfileVariables;
    return uid == otherTyped.uid && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    avatarInitials == otherTyped.avatarInitials;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, name.hashCode, email.hashCode, avatarInitials.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['name'] = nativeToJson<String>(name);
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if(avatarInitials.state == OptionalState.set) {
      json['avatarInitials'] = avatarInitials.toJson();
    }
    return json;
  }

  UpdateUserProfileVariables({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarInitials,
  });
}

