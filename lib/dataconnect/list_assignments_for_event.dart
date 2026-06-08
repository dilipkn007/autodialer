part of 'default.dart';

class ListAssignmentsForEventVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  ListAssignmentsForEventVariablesBuilder(this._dataConnect, {required  this.eventId,});
  Deserializer<ListAssignmentsForEventData> dataDeserializer = (dynamic json)  => ListAssignmentsForEventData.fromJson(jsonDecode(json));
  Serializer<ListAssignmentsForEventVariables> varsSerializer = (ListAssignmentsForEventVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListAssignmentsForEventData, ListAssignmentsForEventVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListAssignmentsForEventData, ListAssignmentsForEventVariables> ref() {
    ListAssignmentsForEventVariables vars= ListAssignmentsForEventVariables(eventId: eventId,);
    return _dataConnect.query("ListAssignmentsForEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListAssignmentsForEventAssignments {
  final String id;
  final EnumValue<AssignmentStatus> status;
  final ListAssignmentsForEventAssignmentsContact contact;
  final ListAssignmentsForEventAssignmentsEnabler enabler;
  final Timestamp assignedAt;
  ListAssignmentsForEventAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = assignmentStatusDeserializer(json['status']),
  contact = ListAssignmentsForEventAssignmentsContact.fromJson(json['contact']),
  enabler = ListAssignmentsForEventAssignmentsEnabler.fromJson(json['enabler']),
  assignedAt = Timestamp.fromJson(json['assignedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEventAssignments otherTyped = other as ListAssignmentsForEventAssignments;
    return id == otherTyped.id && 
    status == otherTyped.status && 
    contact == otherTyped.contact && 
    enabler == otherTyped.enabler && 
    assignedAt == otherTyped.assignedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, contact.hashCode, enabler.hashCode, assignedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    assignmentStatusSerializer(status)
    ;
    json['contact'] = contact.toJson();
    json['enabler'] = enabler.toJson();
    json['assignedAt'] = assignedAt.toJson();
    return json;
  }

  ListAssignmentsForEventAssignments({
    required this.id,
    required this.status,
    required this.contact,
    required this.enabler,
    required this.assignedAt,
  });
}

@immutable
class ListAssignmentsForEventAssignmentsContact {
  final String id;
  final String name;
  final String mobile;
  final String? folkId;
  ListAssignmentsForEventAssignmentsContact.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEventAssignmentsContact otherTyped = other as ListAssignmentsForEventAssignmentsContact;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    folkId == otherTyped.folkId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, mobile.hashCode, folkId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    return json;
  }

  ListAssignmentsForEventAssignmentsContact({
    required this.id,
    required this.name,
    required this.mobile,
    this.folkId,
  });
}

@immutable
class ListAssignmentsForEventAssignmentsEnabler {
  final String uid;
  final String name;
  final String phone;
  ListAssignmentsForEventAssignmentsEnabler.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  name = nativeFromJson<String>(json['name']),
  phone = nativeFromJson<String>(json['phone']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEventAssignmentsEnabler otherTyped = other as ListAssignmentsForEventAssignmentsEnabler;
    return uid == otherTyped.uid && 
    name == otherTyped.name && 
    phone == otherTyped.phone;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, name.hashCode, phone.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['name'] = nativeToJson<String>(name);
    json['phone'] = nativeToJson<String>(phone);
    return json;
  }

  ListAssignmentsForEventAssignmentsEnabler({
    required this.uid,
    required this.name,
    required this.phone,
  });
}

@immutable
class ListAssignmentsForEventData {
  final List<ListAssignmentsForEventAssignments> assignments;
  ListAssignmentsForEventData.fromJson(dynamic json):
  
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => ListAssignmentsForEventAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEventData otherTyped = other as ListAssignmentsForEventData;
    return assignments == otherTyped.assignments;
    
  }
  @override
  int get hashCode => assignments.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    return json;
  }

  ListAssignmentsForEventData({
    required this.assignments,
  });
}

@immutable
class ListAssignmentsForEventVariables {
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListAssignmentsForEventVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAssignmentsForEventVariables otherTyped = other as ListAssignmentsForEventVariables;
    return eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => eventId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  ListAssignmentsForEventVariables({
    required this.eventId,
  });
}

