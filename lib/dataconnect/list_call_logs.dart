part of 'default.dart';

class ListCallLogsVariablesBuilder {
  String enablerUid;
  String eventId;

  final FirebaseDataConnect _dataConnect;
  ListCallLogsVariablesBuilder(this._dataConnect, {required  this.enablerUid,required  this.eventId,});
  Deserializer<ListCallLogsData> dataDeserializer = (dynamic json)  => ListCallLogsData.fromJson(jsonDecode(json));
  Serializer<ListCallLogsVariables> varsSerializer = (ListCallLogsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListCallLogsData, ListCallLogsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListCallLogsData, ListCallLogsVariables> ref() {
    ListCallLogsVariables vars= ListCallLogsVariables(enablerUid: enablerUid,eventId: eventId,);
    return _dataConnect.query("ListCallLogs", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListCallLogsCallLogs {
  final String id;
  final EnumValue<CallOutcome> callOutcome;
  final EnumValue<FollowUpStatus>? followUpStatus;
  final String? followUpNotes;
  final DateTime? nextCallDate;
  final int? callDuration;
  final Timestamp calledAt;
  final ListCallLogsCallLogsContact contact;
  final ListCallLogsCallLogsAssignment assignment;
  ListCallLogsCallLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  callOutcome = callOutcomeDeserializer(json['callOutcome']),
  followUpStatus = json['followUpStatus'] == null ? null : followUpStatusDeserializer(json['followUpStatus']),
  followUpNotes = json['followUpNotes'] == null ? null : nativeFromJson<String>(json['followUpNotes']),
  nextCallDate = json['nextCallDate'] == null ? null : nativeFromJson<DateTime>(json['nextCallDate']),
  callDuration = json['callDuration'] == null ? null : nativeFromJson<int>(json['callDuration']),
  calledAt = Timestamp.fromJson(json['calledAt']),
  contact = ListCallLogsCallLogsContact.fromJson(json['contact']),
  assignment = ListCallLogsCallLogsAssignment.fromJson(json['assignment']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListCallLogsCallLogs otherTyped = other as ListCallLogsCallLogs;
    return id == otherTyped.id && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus && 
    followUpNotes == otherTyped.followUpNotes && 
    nextCallDate == otherTyped.nextCallDate && 
    callDuration == otherTyped.callDuration && 
    calledAt == otherTyped.calledAt && 
    contact == otherTyped.contact && 
    assignment == otherTyped.assignment;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, callOutcome.hashCode, followUpStatus.hashCode, followUpNotes.hashCode, nextCallDate.hashCode, callDuration.hashCode, calledAt.hashCode, contact.hashCode, assignment.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['callOutcome'] = 
    callOutcomeSerializer(callOutcome)
    ;
    if (followUpStatus != null) {
      json['followUpStatus'] = 
    followUpStatusSerializer(followUpStatus!)
    ;
    }
    if (followUpNotes != null) {
      json['followUpNotes'] = nativeToJson<String?>(followUpNotes);
    }
    if (nextCallDate != null) {
      json['nextCallDate'] = nativeToJson<DateTime?>(nextCallDate);
    }
    if (callDuration != null) {
      json['callDuration'] = nativeToJson<int?>(callDuration);
    }
    json['calledAt'] = calledAt.toJson();
    json['contact'] = contact.toJson();
    json['assignment'] = assignment.toJson();
    return json;
  }

  ListCallLogsCallLogs({
    required this.id,
    required this.callOutcome,
    this.followUpStatus,
    this.followUpNotes,
    this.nextCallDate,
    this.callDuration,
    required this.calledAt,
    required this.contact,
    required this.assignment,
  });
}

@immutable
class ListCallLogsCallLogsContact {
  final String id;
  final String name;
  final String mobile;
  final String? folkId;
  ListCallLogsCallLogsContact.fromJson(dynamic json):
  
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

    final ListCallLogsCallLogsContact otherTyped = other as ListCallLogsCallLogsContact;
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

  ListCallLogsCallLogsContact({
    required this.id,
    required this.name,
    required this.mobile,
    this.folkId,
  });
}

@immutable
class ListCallLogsCallLogsAssignment {
  final String id;
  final EnumValue<AssignmentStatus> status;
  ListCallLogsCallLogsAssignment.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = assignmentStatusDeserializer(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListCallLogsCallLogsAssignment otherTyped = other as ListCallLogsCallLogsAssignment;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    assignmentStatusSerializer(status)
    ;
    return json;
  }

  ListCallLogsCallLogsAssignment({
    required this.id,
    required this.status,
  });
}

@immutable
class ListCallLogsData {
  final List<ListCallLogsCallLogs> callLogs;
  ListCallLogsData.fromJson(dynamic json):
  
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => ListCallLogsCallLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListCallLogsData otherTyped = other as ListCallLogsData;
    return callLogs == otherTyped.callLogs;
    
  }
  @override
  int get hashCode => callLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    return json;
  }

  ListCallLogsData({
    required this.callLogs,
  });
}

@immutable
class ListCallLogsVariables {
  final String enablerUid;
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListCallLogsVariables.fromJson(Map<String, dynamic> json):
  
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

    final ListCallLogsVariables otherTyped = other as ListCallLogsVariables;
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

  ListCallLogsVariables({
    required this.enablerUid,
    required this.eventId,
  });
}

