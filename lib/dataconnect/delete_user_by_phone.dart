part of 'default.dart';

class DeleteUserByPhoneVariablesBuilder {
  String uid;
  String phone;

  final FirebaseDataConnect _dataConnect;
  DeleteUserByPhoneVariablesBuilder(this._dataConnect, {required  this.uid,required  this.phone,});
  Deserializer<DeleteUserByPhoneData> dataDeserializer = (dynamic json)  => DeleteUserByPhoneData.fromJson(jsonDecode(json));
  Serializer<DeleteUserByPhoneVariables> varsSerializer = (DeleteUserByPhoneVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteUserByPhoneData, DeleteUserByPhoneVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteUserByPhoneData, DeleteUserByPhoneVariables> ref() {
    DeleteUserByPhoneVariables vars= DeleteUserByPhoneVariables(uid: uid,phone: phone,);
    return _dataConnect.mutation("DeleteUserByPhone", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteUserByPhoneUserDelete {
  final String uid;
  DeleteUserByPhoneUserDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserByPhoneUserDelete otherTyped = other as DeleteUserByPhoneUserDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  DeleteUserByPhoneUserDelete({
    required this.uid,
  });
}

@immutable
class DeleteUserByPhoneData {
  final DeleteUserByPhoneUserDelete? user_delete;
  DeleteUserByPhoneData.fromJson(dynamic json):
  
  user_delete = json['user_delete'] == null ? null : DeleteUserByPhoneUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserByPhoneData otherTyped = other as DeleteUserByPhoneData;
    return user_delete == otherTyped.user_delete;
    
  }
  @override
  int get hashCode => user_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_delete != null) {
      json['user_delete'] = user_delete!.toJson();
    }
    return json;
  }

  DeleteUserByPhoneData({
    this.user_delete,
  });
}

@immutable
class DeleteUserByPhoneVariables {
  final String uid;
  final String phone;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteUserByPhoneVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteUserByPhoneVariables otherTyped = other as DeleteUserByPhoneVariables;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['phone'] = nativeToJson<String>(phone);
    return json;
  }

  DeleteUserByPhoneVariables({
    required this.uid,
    required this.phone,
  });
}

