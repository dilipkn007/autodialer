part of 'default.dart';

class GetEventCallStatsVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  GetEventCallStatsVariablesBuilder(this._dataConnect, {required  this.eventId,});
  Deserializer<GetEventCallStatsData> dataDeserializer = (dynamic json)  => GetEventCallStatsData.fromJson(jsonDecode(json));
  Serializer<GetEventCallStatsVariables> varsSerializer = (GetEventCallStatsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetEventCallStatsData, GetEventCallStatsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetEventCallStatsData, GetEventCallStatsVariables> ref() {
    GetEventCallStatsVariables vars= GetEventCallStatsVariables(eventId: eventId,);
    return _dataConnect.query("GetEventCallStats", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetEventCallStatsEvent {
  final String id;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String? eventTime;
  final EnumValue<EventStatus> status;
  GetEventCallStatsEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  eventTime = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']),
  status = eventStatusDeserializer(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventCallStatsEvent otherTyped = other as GetEventCallStatsEvent;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    json['eventDate'] = nativeToJson<DateTime>(eventDate);
    if (eventTime != null) {
      json['eventTime'] = nativeToJson<String?>(eventTime);
    }
    json['status'] = 
    eventStatusSerializer(status)
    ;
    return json;
  }

  GetEventCallStatsEvent({
    required this.id,
    required this.name,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.status,
  });
}

@immutable
class GetEventCallStatsCallLogs {
  final String id;
  final EnumValue<CallOutcome> callOutcome;
  final EnumValue<FollowUpStatus>? followUpStatus;
  GetEventCallStatsCallLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  callOutcome = callOutcomeDeserializer(json['callOutcome']),
  followUpStatus = json['followUpStatus'] == null ? null : followUpStatusDeserializer(json['followUpStatus']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventCallStatsCallLogs otherTyped = other as GetEventCallStatsCallLogs;
    return id == otherTyped.id && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, callOutcome.hashCode, followUpStatus.hashCode]);
  

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
    return json;
  }

  GetEventCallStatsCallLogs({
    required this.id,
    required this.callOutcome,
    this.followUpStatus,
  });
}

@immutable
class GetEventCallStatsAssignments {
  final String id;
  final EnumValue<AssignmentStatus> status;
  GetEventCallStatsAssignments.fromJson(dynamic json):
  
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

    final GetEventCallStatsAssignments otherTyped = other as GetEventCallStatsAssignments;
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

  GetEventCallStatsAssignments({
    required this.id,
    required this.status,
  });
}

@immutable
class GetEventCallStatsData {
  final GetEventCallStatsEvent? event;
  final List<GetEventCallStatsCallLogs> callLogs;
  final List<GetEventCallStatsAssignments> assignments;
  GetEventCallStatsData.fromJson(dynamic json):
  
  event = json['event'] == null ? null : GetEventCallStatsEvent.fromJson(json['event']),
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => GetEventCallStatsCallLogs.fromJson(e))
        .toList(),
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => GetEventCallStatsAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventCallStatsData otherTyped = other as GetEventCallStatsData;
    return event == otherTyped.event && 
    callLogs == otherTyped.callLogs && 
    assignments == otherTyped.assignments;
    
  }
  @override
  int get hashCode => Object.hashAll([event.hashCode, callLogs.hashCode, assignments.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (event != null) {
      json['event'] = event!.toJson();
    }
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    return json;
  }

  GetEventCallStatsData({
    this.event,
    required this.callLogs,
    required this.assignments,
  });
}

@immutable
class GetEventCallStatsVariables {
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetEventCallStatsVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventCallStatsVariables otherTyped = other as GetEventCallStatsVariables;
    return eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => eventId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  GetEventCallStatsVariables({
    required this.eventId,
  });
}

