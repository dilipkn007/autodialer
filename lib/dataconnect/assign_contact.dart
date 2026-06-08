part of 'default.dart';

class AssignContactVariablesBuilder {
  String contactId;
  String enablerUid;
  String eventId;
  int sortOrder;
  String assignedByUid;

  final FirebaseDataConnect _dataConnect;
  AssignContactVariablesBuilder(this._dataConnect, {required  this.contactId,required  this.enablerUid,required  this.eventId,required  this.sortOrder,required  this.assignedByUid,});
  Deserializer<AssignContactData> dataDeserializer = (dynamic json)  => AssignContactData.fromJson(jsonDecode(json));
  Serializer<AssignContactVariables> varsSerializer = (AssignContactVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AssignContactData, AssignContactVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AssignContactData, AssignContactVariables> ref() {
    AssignContactVariables vars= AssignContactVariables(contactId: contactId,enablerUid: enablerUid,eventId: eventId,sortOrder: sortOrder,assignedByUid: assignedByUid,);
    return _dataConnect.mutation("AssignContact", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AssignContactAssignmentInsert {
  final String id;
  AssignContactAssignmentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AssignContactAssignmentInsert otherTyped = other as AssignContactAssignmentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AssignContactAssignmentInsert({
    required this.id,
  });
}

@immutable
class AssignContactData {
  final AssignContactAssignmentInsert assignment_insert;
  AssignContactData.fromJson(dynamic json):
  
  assignment_insert = AssignContactAssignmentInsert.fromJson(json['assignment_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AssignContactData otherTyped = other as AssignContactData;
    return assignment_insert == otherTyped.assignment_insert;
    
  }
  @override
  int get hashCode => assignment_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignment_insert'] = assignment_insert.toJson();
    return json;
  }

  AssignContactData({
    required this.assignment_insert,
  });
}

@immutable
class AssignContactVariables {
  final String contactId;
  final String enablerUid;
  final String eventId;
  final int sortOrder;
  final String assignedByUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AssignContactVariables.fromJson(Map<String, dynamic> json):
  
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

    final AssignContactVariables otherTyped = other as AssignContactVariables;
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

  AssignContactVariables({
    required this.contactId,
    required this.enablerUid,
    required this.eventId,
    required this.sortOrder,
    required this.assignedByUid,
  });
}

