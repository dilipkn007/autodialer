part of 'default.dart';

class DeleteEventVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteEventVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteEventData> dataDeserializer = (dynamic json)  => DeleteEventData.fromJson(jsonDecode(json));
  Serializer<DeleteEventVariables> varsSerializer = (DeleteEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteEventData, DeleteEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteEventData, DeleteEventVariables> ref() {
    DeleteEventVariables vars= DeleteEventVariables(id: id,);
    return _dataConnect.mutation("DeleteEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteEventEventDelete {
  final String id;
  DeleteEventEventDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEventEventDelete otherTyped = other as DeleteEventEventDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteEventEventDelete({
    required this.id,
  });
}

@immutable
class DeleteEventData {
  final int surveyResponse_deleteMany;
  final int callLog_deleteMany;
  final int assignment_deleteMany;
  final int surveyQuestion_deleteMany;
  final DeleteEventEventDelete? event_delete;
  DeleteEventData.fromJson(dynamic json):
  
  surveyResponse_deleteMany = nativeFromJson<int>(json['surveyResponse_deleteMany']),
  callLog_deleteMany = nativeFromJson<int>(json['callLog_deleteMany']),
  assignment_deleteMany = nativeFromJson<int>(json['assignment_deleteMany']),
  surveyQuestion_deleteMany = nativeFromJson<int>(json['surveyQuestion_deleteMany']),
  event_delete = json['event_delete'] == null ? null : DeleteEventEventDelete.fromJson(json['event_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEventData otherTyped = other as DeleteEventData;
    return surveyResponse_deleteMany == otherTyped.surveyResponse_deleteMany && 
    callLog_deleteMany == otherTyped.callLog_deleteMany && 
    assignment_deleteMany == otherTyped.assignment_deleteMany && 
    surveyQuestion_deleteMany == otherTyped.surveyQuestion_deleteMany && 
    event_delete == otherTyped.event_delete;
    
  }
  @override
  int get hashCode => Object.hashAll([surveyResponse_deleteMany.hashCode, callLog_deleteMany.hashCode, assignment_deleteMany.hashCode, surveyQuestion_deleteMany.hashCode, event_delete.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['surveyResponse_deleteMany'] = nativeToJson<int>(surveyResponse_deleteMany);
    json['callLog_deleteMany'] = nativeToJson<int>(callLog_deleteMany);
    json['assignment_deleteMany'] = nativeToJson<int>(assignment_deleteMany);
    json['surveyQuestion_deleteMany'] = nativeToJson<int>(surveyQuestion_deleteMany);
    if (event_delete != null) {
      json['event_delete'] = event_delete!.toJson();
    }
    return json;
  }

  DeleteEventData({
    required this.surveyResponse_deleteMany,
    required this.callLog_deleteMany,
    required this.assignment_deleteMany,
    required this.surveyQuestion_deleteMany,
    this.event_delete,
  });
}

@immutable
class DeleteEventVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteEventVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEventVariables otherTyped = other as DeleteEventVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteEventVariables({
    required this.id,
  });
}

