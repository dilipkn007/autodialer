part of 'default.dart';

class UpdateAssignmentStatusVariablesBuilder {
  String id;
  AssignmentStatus status;

  final FirebaseDataConnect _dataConnect;
  UpdateAssignmentStatusVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateAssignmentStatusData> dataDeserializer = (dynamic json)  => UpdateAssignmentStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateAssignmentStatusVariables> varsSerializer = (UpdateAssignmentStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateAssignmentStatusData, UpdateAssignmentStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateAssignmentStatusData, UpdateAssignmentStatusVariables> ref() {
    UpdateAssignmentStatusVariables vars= UpdateAssignmentStatusVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateAssignmentStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateAssignmentStatusAssignmentUpdate {
  final String id;
  UpdateAssignmentStatusAssignmentUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateAssignmentStatusAssignmentUpdate otherTyped = other as UpdateAssignmentStatusAssignmentUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateAssignmentStatusAssignmentUpdate({
    required this.id,
  });
}

@immutable
class UpdateAssignmentStatusData {
  final UpdateAssignmentStatusAssignmentUpdate? assignment_update;
  UpdateAssignmentStatusData.fromJson(dynamic json):
  
  assignment_update = json['assignment_update'] == null ? null : UpdateAssignmentStatusAssignmentUpdate.fromJson(json['assignment_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateAssignmentStatusData otherTyped = other as UpdateAssignmentStatusData;
    return assignment_update == otherTyped.assignment_update;
    
  }
  @override
  int get hashCode => assignment_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (assignment_update != null) {
      json['assignment_update'] = assignment_update!.toJson();
    }
    return json;
  }

  UpdateAssignmentStatusData({
    this.assignment_update,
  });
}

@immutable
class UpdateAssignmentStatusVariables {
  final String id;
  final AssignmentStatus status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateAssignmentStatusVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = AssignmentStatus.values.byName(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateAssignmentStatusVariables otherTyped = other as UpdateAssignmentStatusVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    status.name
    ;
    return json;
  }

  UpdateAssignmentStatusVariables({
    required this.id,
    required this.status,
  });
}

