part of 'default.dart';

class DeleteAssignmentsForEventVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  DeleteAssignmentsForEventVariablesBuilder(this._dataConnect, {required  this.eventId,});
  Deserializer<DeleteAssignmentsForEventData> dataDeserializer = (dynamic json)  => DeleteAssignmentsForEventData.fromJson(jsonDecode(json));
  Serializer<DeleteAssignmentsForEventVariables> varsSerializer = (DeleteAssignmentsForEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAssignmentsForEventData, DeleteAssignmentsForEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAssignmentsForEventData, DeleteAssignmentsForEventVariables> ref() {
    DeleteAssignmentsForEventVariables vars= DeleteAssignmentsForEventVariables(eventId: eventId,);
    return _dataConnect.mutation("DeleteAssignmentsForEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAssignmentsForEventData {
  final int assignment_deleteMany;
  DeleteAssignmentsForEventData.fromJson(dynamic json):
  
  assignment_deleteMany = nativeFromJson<int>(json['assignment_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAssignmentsForEventData otherTyped = other as DeleteAssignmentsForEventData;
    return assignment_deleteMany == otherTyped.assignment_deleteMany;
    
  }
  @override
  int get hashCode => assignment_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignment_deleteMany'] = nativeToJson<int>(assignment_deleteMany);
    return json;
  }

  DeleteAssignmentsForEventData({
    required this.assignment_deleteMany,
  });
}

@immutable
class DeleteAssignmentsForEventVariables {
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAssignmentsForEventVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAssignmentsForEventVariables otherTyped = other as DeleteAssignmentsForEventVariables;
    return eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => eventId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  DeleteAssignmentsForEventVariables({
    required this.eventId,
  });
}

