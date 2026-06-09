part of 'default.dart';

class ReassignContactVariablesBuilder {
  String contactId;
  String enablerUid;
  String eventId;
  int sortOrder;
  String assignedByUid;

  final FirebaseDataConnect _dataConnect;
  ReassignContactVariablesBuilder(this._dataConnect, {required  this.contactId,required  this.enablerUid,required  this.eventId,required  this.sortOrder,required  this.assignedByUid,});
  Deserializer<ReassignContactData> dataDeserializer = (dynamic json)  => ReassignContactData.fromJson(jsonDecode(json));
  Serializer<ReassignContactVariables> varsSerializer = (ReassignContactVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ReassignContactData, ReassignContactVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ReassignContactData, ReassignContactVariables> ref() {
    ReassignContactVariables vars= ReassignContactVariables(contactId: contactId,enablerUid: enablerUid,eventId: eventId,sortOrder: sortOrder,assignedByUid: assignedByUid,);
    return _dataConnect.mutation("ReassignContact", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ReassignContactAssignmentInsert {
  final String id;
  ReassignContactAssignmentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReassignContactAssignmentInsert otherTyped = other as ReassignContactAssignmentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ReassignContactAssignmentInsert({
    required this.id,
  });
}

@immutable
class ReassignContactData {
  final int assignment_deleteMany;
  final ReassignContactAssignmentInsert assignment_insert;
  ReassignContactData.fromJson(dynamic json):
  
  assignment_deleteMany = nativeFromJson<int>(json['assignment_deleteMany']),
  assignment_insert = ReassignContactAssignmentInsert.fromJson(json['assignment_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReassignContactData otherTyped = other as ReassignContactData;
    return assignment_deleteMany == otherTyped.assignment_deleteMany && 
    assignment_insert == otherTyped.assignment_insert;
    
  }
  @override
  int get hashCode => Object.hashAll([assignment_deleteMany.hashCode, assignment_insert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignment_deleteMany'] = nativeToJson<int>(assignment_deleteMany);
    json['assignment_insert'] = assignment_insert.toJson();
    return json;
  }

  ReassignContactData({
    required this.assignment_deleteMany,
    required this.assignment_insert,
  });
}

@immutable
class ReassignContactVariables {
  final String contactId;
  final String enablerUid;
  final String eventId;
  final int sortOrder;
  final String assignedByUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ReassignContactVariables.fromJson(Map<String, dynamic> json):
  
  contactId = nativeFromJson<String>(json['contactId']),
  enablerUid = nativeFromJson<String>(json['enablerUid']),
  eventId = nativeFromJson<String>(json['eventId']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  assignedByUid = nativeFromJson<String>(json['assignedByUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReassignContactVariables otherTyped = other as ReassignContactVariables;
    return contactId == otherTyped.contactId && 
    enablerUid == otherTyped.enablerUid && 
    eventId == otherTyped.eventId && 
    sortOrder == otherTyped.sortOrder && 
    assignedByUid == otherTyped.assignedByUid;
    
  }
  @override
  int get hashCode => Object.hashAll([contactId.hashCode, enablerUid.hashCode, eventId.hashCode, sortOrder.hashCode, assignedByUid.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['contactId'] = nativeToJson<String>(contactId);
    json['enablerUid'] = nativeToJson<String>(enablerUid);
    json['eventId'] = nativeToJson<String>(eventId);
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    json['assignedByUid'] = nativeToJson<String>(assignedByUid);
    return json;
  }

  ReassignContactVariables({
    required this.contactId,
    required this.enablerUid,
    required this.eventId,
    required this.sortOrder,
    required this.assignedByUid,
  });
}

