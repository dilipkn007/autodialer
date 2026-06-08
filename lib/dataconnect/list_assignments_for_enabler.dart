part of 'default.dart';

class ListAssignmentsForEnablerVariablesBuilder {
  String enablerUid;
  String eventId;

  final FirebaseDataConnect _dataConnect;
  ListAssignmentsForEnablerVariablesBuilder(this._dataConnect, {required  this.enablerUid,required  this.eventId,});
  Deserializer<ListAssignmentsForEnablerData> dataDeserializer = (dynamic json)  => ListAssignmentsForEnablerData.fromJson(jsonDecode(json));
  Serializer<ListAssignmentsForEnablerVariables> varsSerializer = (ListAssignmentsForEnablerVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListAssignmentsForEnablerData, ListAssignmentsForEnablerVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListAssignmentsForEnablerData, ListAssignmentsForEnablerVariables> ref() {
    ListAssignmentsForEnablerVariables vars= ListAssignmentsForEnablerVariables(enablerUid: enablerUid,eventId: eventId,);
    return _dataConnect.query("ListAssignmentsForEnabler", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListAssignmentsForEnablerAssignments {
  final String id;
  final EnumValue<AssignmentStatus> status;
  final int sortOrder;
  final ListAssignmentsForEnablerAssignmentsContact contact;
  final ListAssignmentsForEnablerAssignmentsEvent event;
  final Timestamp assignedAt;
  ListAssignmentsForEnablerAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = assignmentStatusDeserializer(json['status']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  contact = ListAssignmentsForEnablerAssignmentsContact.fromJson(json['contact']),
  event = ListAssignmentsForEnablerAssignmentsEvent.fromJson(json['event']),
  assignedAt = Timestamp.fromJson(json['assignedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEnablerAssignments otherTyped = other as ListAssignmentsForEnablerAssignments;
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

  ListAssignmentsForEnablerAssignments({
    required this.id,
    required this.status,
    required this.sortOrder,
    required this.contact,
    required this.event,
    required this.assignedAt,
  });
}

@immutable
class ListAssignmentsForEnablerAssignmentsContact {
  final String id;
  final String name;
  final String mobile;
  final String? folkId;
  final String? city;
  final String? center;
  final String? currentStatus;
  ListAssignmentsForEnablerAssignmentsContact.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']),
  city = json['city'] == null ? null : nativeFromJson<String>(json['city']),
  center = json['center'] == null ? null : nativeFromJson<String>(json['center']),
  currentStatus = json['currentStatus'] == null ? null : nativeFromJson<String>(json['currentStatus']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEnablerAssignmentsContact otherTyped = other as ListAssignmentsForEnablerAssignmentsContact;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    folkId == otherTyped.folkId && 
    city == otherTyped.city && 
    center == otherTyped.center && 
    currentStatus == otherTyped.currentStatus;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, mobile.hashCode, folkId.hashCode, city.hashCode, center.hashCode, currentStatus.hashCode]);
  

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
    if (center != null) {
      json['center'] = nativeToJson<String?>(center);
    }
    if (currentStatus != null) {
      json['currentStatus'] = nativeToJson<String?>(currentStatus);
    }
    return json;
  }

  ListAssignmentsForEnablerAssignmentsContact({
    required this.id,
    required this.name,
    required this.mobile,
    this.folkId,
    this.city,
    this.center,
    this.currentStatus,
  });
}

@immutable
class ListAssignmentsForEnablerAssignmentsEvent {
  final String id;
  final String name;
  final int? gapDuration;
  ListAssignmentsForEnablerAssignmentsEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  gapDuration = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEnablerAssignmentsEvent otherTyped = other as ListAssignmentsForEnablerAssignmentsEvent;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    gapDuration == otherTyped.gapDuration;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, gapDuration.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (gapDuration != null) {
      json['gapDuration'] = nativeToJson<int?>(gapDuration);
    }
    return json;
  }

  ListAssignmentsForEnablerAssignmentsEvent({
    required this.id,
    required this.name,
    this.gapDuration,
  });
}

@immutable
class ListAssignmentsForEnablerData {
  final List<ListAssignmentsForEnablerAssignments> assignments;
  ListAssignmentsForEnablerData.fromJson(dynamic json):
  
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => ListAssignmentsForEnablerAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEnablerData otherTyped = other as ListAssignmentsForEnablerData;
    return assignments == otherTyped.assignments;
    
  }
  @override
  int get hashCode => assignments.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    return json;
  }

  ListAssignmentsForEnablerData({
    required this.assignments,
  });
}

@immutable
class ListAssignmentsForEnablerVariables {
  final String enablerUid;
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListAssignmentsForEnablerVariables.fromJson(Map<String, dynamic> json):
  
  enablerUid = nativeFromJson<String>(json['enablerUid']),
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEnablerVariables otherTyped = other as ListAssignmentsForEnablerVariables;
    return enablerUid == otherTyped.enablerUid && 
    eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => Object.hashAll([enablerUid.hashCode, eventId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['enablerUid'] = nativeToJson<String>(enablerUid);
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  ListAssignmentsForEnablerVariables({
    required this.enablerUid,
    required this.eventId,
  });
}

