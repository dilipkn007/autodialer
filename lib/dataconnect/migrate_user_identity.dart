part of 'default.dart';

class MigrateUserIdentityVariablesBuilder {
  String oldUid;
  String newUid;
  String phone;
  String dummyPhone;
  String name;
  UserRole role;
  bool isActive;

  final FirebaseDataConnect _dataConnect;
  MigrateUserIdentityVariablesBuilder(this._dataConnect, {required  this.oldUid,required  this.newUid,required  this.phone,required  this.dummyPhone,required  this.name,required  this.role,required  this.isActive,});
  Deserializer<MigrateUserIdentityData> dataDeserializer = (dynamic json)  => MigrateUserIdentityData.fromJson(jsonDecode(json));
  Serializer<MigrateUserIdentityVariables> varsSerializer = (MigrateUserIdentityVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MigrateUserIdentityData, MigrateUserIdentityVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MigrateUserIdentityData, MigrateUserIdentityVariables> ref() {
    MigrateUserIdentityVariables vars= MigrateUserIdentityVariables(oldUid: oldUid,newUid: newUid,phone: phone,dummyPhone: dummyPhone,name: name,role: role,isActive: isActive,);
    return _dataConnect.mutation("MigrateUserIdentity", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MigrateUserIdentityUserUpdate {
  final String uid;
  MigrateUserIdentityUserUpdate.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserIdentityUserUpdate otherTyped = other as MigrateUserIdentityUserUpdate;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  MigrateUserIdentityUserUpdate({
    required this.uid,
  });
}

@immutable
class MigrateUserIdentityUserInsert {
  final String uid;
  MigrateUserIdentityUserInsert.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserIdentityUserInsert otherTyped = other as MigrateUserIdentityUserInsert;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  MigrateUserIdentityUserInsert({
    required this.uid,
  });
}

@immutable
class MigrateUserIdentityUserDelete {
  final String uid;
  MigrateUserIdentityUserDelete.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserIdentityUserDelete otherTyped = other as MigrateUserIdentityUserDelete;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  MigrateUserIdentityUserDelete({
    required this.uid,
  });
}

@immutable
class MigrateUserIdentityData {
  final MigrateUserIdentityUserUpdate? user_update;
  final MigrateUserIdentityUserInsert user_insert;
  final int assignment_updateMany;
  final int callLog_updateMany;
  final MigrateUserIdentityUserDelete? user_delete;
  MigrateUserIdentityData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : MigrateUserIdentityUserUpdate.fromJson(json['user_update']),
  user_insert = MigrateUserIdentityUserInsert.fromJson(json['user_insert']),
  assignment_updateMany = nativeFromJson<int>(json['assignment_updateMany']),
  callLog_updateMany = nativeFromJson<int>(json['callLog_updateMany']),
  user_delete = json['user_delete'] == null ? null : MigrateUserIdentityUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserIdentityData otherTyped = other as MigrateUserIdentityData;
    return user_update == otherTyped.user_update && 
    user_insert == otherTyped.user_insert && 
    assignment_updateMany == otherTyped.assignment_updateMany && 
    callLog_updateMany == otherTyped.callLog_updateMany && 
    user_delete == otherTyped.user_delete;
    
  }
  @override
  int get hashCode => Object.hashAll([user_update.hashCode, user_insert.hashCode, assignment_updateMany.hashCode, callLog_updateMany.hashCode, user_delete.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    json['user_insert'] = user_insert.toJson();
    json['assignment_updateMany'] = nativeToJson<int>(assignment_updateMany);
    json['callLog_updateMany'] = nativeToJson<int>(callLog_updateMany);
    if (user_delete != null) {
      json['user_delete'] = user_delete!.toJson();
    }
    return json;
  }

  MigrateUserIdentityData({
    this.user_update,
    required this.user_insert,
    required this.assignment_updateMany,
    required this.callLog_updateMany,
    this.user_delete,
  });
}

@immutable
class MigrateUserIdentityVariables {
  final String oldUid;
  final String newUid;
  final String phone;
  final String dummyPhone;
  final String name;
  final UserRole role;
  final bool isActive;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MigrateUserIdentityVariables.fromJson(Map<String, dynamic> json):
  
  oldUid = nativeFromJson<String>(json['oldUid']),
  newUid = nativeFromJson<String>(json['newUid']),
  phone = nativeFromJson<String>(json['phone']),
  dummyPhone = nativeFromJson<String>(json['dummyPhone']),
  name = nativeFromJson<String>(json['name']),
  role = UserRole.values.byName(json['role']),
  isActive = nativeFromJson<bool>(json['isActive']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserIdentityVariables otherTyped = other as MigrateUserIdentityVariables;
    return oldUid == otherTyped.oldUid && 
    newUid == otherTyped.newUid && 
    phone == otherTyped.phone && 
    dummyPhone == otherTyped.dummyPhone && 
    name == otherTyped.name && 
    role == otherTyped.role && 
    isActive == otherTyped.isActive;
    
  }
  @override
  int get hashCode => Object.hashAll([oldUid.hashCode, newUid.hashCode, phone.hashCode, dummyPhone.hashCode, name.hashCode, role.hashCode, isActive.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['oldUid'] = nativeToJson<String>(oldUid);
    json['newUid'] = nativeToJson<String>(newUid);
    json['phone'] = nativeToJson<String>(phone);
    json['dummyPhone'] = nativeToJson<String>(dummyPhone);
    json['name'] = nativeToJson<String>(name);
    json['role'] = 
    role.name
    ;
    json['isActive'] = nativeToJson<bool>(isActive);
    return json;
  }

  MigrateUserIdentityVariables({
    required this.oldUid,
    required this.newUid,
    required this.phone,
    required this.dummyPhone,
    required this.name,
    required this.role,
    required this.isActive,
  });
}

