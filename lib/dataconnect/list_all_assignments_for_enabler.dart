part of 'default.dart';

class ListAllAssignmentsForEnablerVariablesBuilder {
  String enablerUid;

  final FirebaseDataConnect _dataConnect;
  ListAllAssignmentsForEnablerVariablesBuilder(this._dataConnect, {required  this.enablerUid,});
  Deserializer<ListAllAssignmentsForEnablerData> dataDeserializer = (dynamic json)  => ListAllAssignmentsForEnablerData.fromJson(jsonDecode(json));
  Serializer<ListAllAssignmentsForEnablerVariables> varsSerializer = (ListAllAssignmentsForEnablerVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListAllAssignmentsForEnablerData, ListAllAssignmentsForEnablerVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllAssignmentsForEnablerData, ListAllAssignmentsForEnablerVariables> ref() {
    ListAllAssignmentsForEnablerVariables vars= ListAllAssignmentsForEnablerVariables(enablerUid: enablerUid,);
    return _dataConnect.query("ListAllAssignmentsForEnabler", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListAllAssignmentsForEnablerAssignments {
  final String id;
  final EnumValue<AssignmentStatus> status;
  final int sortOrder;
  final ListAllAssignmentsForEnablerAssignmentsContact contact;
  final ListAllAssignmentsForEnablerAssignmentsEvent event;
  final Timestamp assignedAt;
  ListAllAssignmentsForEnablerAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = assignmentStatusDeserializer(json['status']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  contact = ListAllAssignmentsForEnablerAssignmentsContact.fromJson(json['contact']),
  event = ListAllAssignmentsForEnablerAssignmentsEvent.fromJson(json['event']),
  assignedAt = Timestamp.fromJson(json['assignedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForEnablerAssignments otherTyped = other as ListAllAssignmentsForEnablerAssignments;
    return id == otherTyped.id && 
    status == otherTyped.status && 
    sortOrder == otherTyped.sortOrder && 
    contact == otherTyped.contact && 
    event == otherTyped.event && 
    assignedAt == otherTyped.assignedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, sortOrder.hashCode, contact.hashCode, event.hashCode, assignedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    assignmentStatusSerializer(status)
    ;
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    json['contact'] = contact.toJson();
    json['event'] = event.toJson();
    json['assignedAt'] = assignedAt.toJson();
    return json;
  }

  ListAllAssignmentsForEnablerAssignments({
    required this.id,
    required this.status,
    required this.sortOrder,
    required this.contact,
    required this.event,
    required this.assignedAt,
  });
}

@immutable
class ListAllAssignmentsForEnablerAssignmentsContact {
  final String id;
  final String name;
  final String mobile;
  final String? folkId;
  final String? city;
  final String? currentStatus;
  ListAllAssignmentsForEnablerAssignmentsContact.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']),
  city = json['city'] == null ? null : nativeFromJson<String>(json['city']),
  currentStatus = json['currentStatus'] == null ? null : nativeFromJson<String>(json['currentStatus']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForEnablerAssignmentsContact otherTyped = other as ListAllAssignmentsForEnablerAssignmentsContact;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    folkId == otherTyped.folkId && 
    city == otherTyped.city && 
    currentStatus == otherTyped.currentStatus;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, mobile.hashCode, folkId.hashCode, city.hashCode, currentStatus.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    if (city != null) {
      json['city'] = nativeToJson<String?>(city);
    }
    if (currentStatus != null) {
      json['currentStatus'] = nativeToJson<String?>(currentStatus);
    }
    return json;
  }

  ListAllAssignmentsForEnablerAssignmentsContact({
    required this.id,
    required this.name,
    required this.mobile,
    this.folkId,
    this.city,
    this.currentStatus,
  });
}

@immutable
class ListAllAssignmentsForEnablerAssignmentsEvent {
  final String id;
  final String name;
  final DateTime eventDate;
  final int? gapDuration;
  ListAllAssignmentsForEnablerAssignmentsEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  gapDuration = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForEnablerAssignmentsEvent otherTyped = other as ListAllAssignmentsForEnablerAssignmentsEvent;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    eventDate == otherTyped.eventDate && 
    gapDuration == otherTyped.gapDuration;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, eventDate.hashCode, gapDuration.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['eventDate'] = nativeToJson<DateTime>(eventDate);
    if (gapDuration != null) {
      json['gapDuration'] = nativeToJson<int?>(gapDuration);
    }
    return json;
  }

  ListAllAssignmentsForEnablerAssignmentsEvent({
    required this.id,
    required this.name,
    required this.eventDate,
    this.gapDuration,
  });
}

@immutable
class ListAllAssignmentsForEnablerData {
  final List<ListAllAssignmentsForEnablerAssignments> assignments;
  ListAllAssignmentsForEnablerData.fromJson(dynamic json):
  
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => ListAllAssignmentsForEnablerAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForEnablerData otherTyped = other as ListAllAssignmentsForEnablerData;
    return assignments == otherTyped.assignments;
    
  }
  @override
  int get hashCode => assignments.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllAssignmentsForEnablerData({
    required this.assignments,
  });
}

@immutable
class ListAllAssignmentsForEnablerVariables {
  final String enablerUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListAllAssignmentsForEnablerVariables.fromJson(Map<String, dynamic> json):
  
  enablerUid = nativeFromJson<String>(json['enablerUid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllAssignmentsForEnablerVariables otherTyped = other as ListAllAssignmentsForEnablerVariables;
    return enablerUid == otherTyped.enablerUid;
    
  }
  @override
  int get hashCode => enablerUid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['enablerUid'] = nativeToJson<String>(enablerUid);
    return json;
  }

  ListAllAssignmentsForEnablerVariables({
    required this.enablerUid,
  });
}

