part of 'default.dart';

class AdminDeleteUserVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  AdminDeleteUserVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<AdminDeleteUserData> dataDeserializer = (dynamic json)  => AdminDeleteUserData.fromJson(jsonDecode(json));
  Serializer<AdminDeleteUserVariables> varsSerializer = (AdminDeleteUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AdminDeleteUserData, AdminDeleteUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AdminDeleteUserData, AdminDeleteUserVariables> ref() {
    AdminDeleteUserVariables vars= AdminDeleteUserVariables(uid: uid,);
    return _dataConnect.mutation("AdminDeleteUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AdminDeleteUserUserDelete {
  final String uid;
  AdminDeleteUserUserDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminDeleteUserUserDelete otherTyped = other as AdminDeleteUserUserDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  AdminDeleteUserUserDelete({
    required this.uid,
  });
}

@immutable
class AdminDeleteUserData {
  final int surveyResponse_deleteMany;
  final int callLog_deleteMany;
  final int assignment_deleteMany;
  final AdminDeleteUserUserDelete? user_delete;
  AdminDeleteUserData.fromJson(dynamic json):
  
  surveyResponse_deleteMany = nativeFromJson<int>(json['surveyResponse_deleteMany']),
  callLog_deleteMany = nativeFromJson<int>(json['callLog_deleteMany']),
  assignment_deleteMany = nativeFromJson<int>(json['assignment_deleteMany']),
  user_delete = json['user_delete'] == null ? null : AdminDeleteUserUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminDeleteUserData otherTyped = other as AdminDeleteUserData;
    return surveyResponse_deleteMany == otherTyped.surveyResponse_deleteMany && 
    callLog_deleteMany == otherTyped.callLog_deleteMany && 
    assignment_deleteMany == otherTyped.assignment_deleteMany && 
    user_delete == otherTyped.user_delete;
    
  }
  @override
  int get hashCode => Object.hashAll([surveyResponse_deleteMany.hashCode, callLog_deleteMany.hashCode, assignment_deleteMany.hashCode, user_delete.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['surveyResponse_deleteMany'] = nativeToJson<int>(surveyResponse_deleteMany);
    json['callLog_deleteMany'] = nativeToJson<int>(callLog_deleteMany);
    json['assignment_deleteMany'] = nativeToJson<int>(assignment_deleteMany);
    if (user_delete != null) {
      json['user_delete'] = user_delete!.toJson();
    }
    return json;
  }

  AdminDeleteUserData({
    required this.surveyResponse_deleteMany,
    required this.callLog_deleteMany,
    required this.assignment_deleteMany,
    this.user_delete,
  });
}

@immutable
class AdminDeleteUserVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AdminDeleteUserVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AdminDeleteUserVariables otherTyped = other as AdminDeleteUserVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  AdminDeleteUserVariables({
    required this.uid,
  });
}

