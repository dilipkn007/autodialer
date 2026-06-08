part of 'default.dart';

class SetUserActiveStatusVariablesBuilder {
  String uid;
  bool isActive;

  final FirebaseDataConnect _dataConnect;
  SetUserActiveStatusVariablesBuilder(this._dataConnect, {required  this.uid,required  this.isActive,});
  Deserializer<SetUserActiveStatusData> dataDeserializer = (dynamic json)  => SetUserActiveStatusData.fromJson(jsonDecode(json));
  Serializer<SetUserActiveStatusVariables> varsSerializer = (SetUserActiveStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SetUserActiveStatusData, SetUserActiveStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SetUserActiveStatusData, SetUserActiveStatusVariables> ref() {
    SetUserActiveStatusVariables vars= SetUserActiveStatusVariables(uid: uid,isActive: isActive,);
    return _dataConnect.mutation("SetUserActiveStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SetUserActiveStatusUserUpdate {
  final String uid;
  SetUserActiveStatusUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetUserActiveStatusUserUpdate otherTyped = other as SetUserActiveStatusUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  SetUserActiveStatusUserUpdate({
    required this.uid,
  });
}

@immutable
class SetUserActiveStatusData {
  final SetUserActiveStatusUserUpdate? user_update;
  SetUserActiveStatusData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : SetUserActiveStatusUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetUserActiveStatusData otherTyped = other as SetUserActiveStatusData;
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

  SetUserActiveStatusData({
    this.user_update,
  });
}

@immutable
class SetUserActiveStatusVariables {
  final String uid;
  final bool isActive;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SetUserActiveStatusVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
  isActive = nativeFromJson<bool>(json['isActive']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetUserActiveStatusVariables otherTyped = other as SetUserActiveStatusVariables;
    return uid == otherTyped.uid && 
    isActive == otherTyped.isActive;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, isActive.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['isActive'] = nativeToJson<bool>(isActive);
    return json;
  }

  SetUserActiveStatusVariables({
    required this.uid,
    required this.isActive,
  });
}

