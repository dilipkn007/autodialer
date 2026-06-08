part of 'default.dart';

class RecordCallLogVariablesBuilder {
  String assignmentId;
  String contactId;
  String enablerUid;
  String eventId;
  CallOutcome callOutcome;
  Optional<FollowUpStatus> _followUpStatus = Optional.optional((data) => FollowUpStatus.values.byName(data), enumSerializer);
  Optional<String> _followUpNotes = Optional.optional(nativeFromJson, nativeToJson);
  Optional<DateTime> _nextCallDate = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _callDuration = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  RecordCallLogVariablesBuilder followUpStatus(FollowUpStatus? t) {
   _followUpStatus.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder followUpNotes(String? t) {
   _followUpNotes.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder nextCallDate(DateTime? t) {
   _nextCallDate.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder callDuration(int? t) {
   _callDuration.value = t;
   return this;
  }

  RecordCallLogVariablesBuilder(this._dataConnect, {required  this.assignmentId,required  this.contactId,required  this.enablerUid,required  this.eventId,required  this.callOutcome,});
  Deserializer<RecordCallLogData> dataDeserializer = (dynamic json)  => RecordCallLogData.fromJson(jsonDecode(json));
  Serializer<RecordCallLogVariables> varsSerializer = (RecordCallLogVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RecordCallLogData, RecordCallLogVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RecordCallLogData, RecordCallLogVariables> ref() {
    RecordCallLogVariables vars= RecordCallLogVariables(assignmentId: assignmentId,contactId: contactId,enablerUid: enablerUid,eventId: eventId,callOutcome: callOutcome,followUpStatus: _followUpStatus,followUpNotes: _followUpNotes,nextCallDate: _nextCallDate,callDuration: _callDuration,);
    return _dataConnect.mutation("RecordCallLog", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class RecordCallLogCallLogInsert {
  final String id;
  RecordCallLogCallLogInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordCallLogCallLogInsert otherTyped = other as RecordCallLogCallLogInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RecordCallLogCallLogInsert({
    required this.id,
  });
}

@immutable
class RecordCallLogData {
  final RecordCallLogCallLogInsert callLog_insert;
  RecordCallLogData.fromJson(dynamic json):
  
  callLog_insert = RecordCallLogCallLogInsert.fromJson(json['callLog_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordCallLogData otherTyped = other as RecordCallLogData;
    return callLog_insert == otherTyped.callLog_insert;
    
  }
  @override
  int get hashCode => callLog_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLog_insert'] = callLog_insert.toJson();
    return json;
  }

  RecordCallLogData({
    required this.callLog_insert,
  });
}

@immutable
class RecordCallLogVariables {
  final String assignmentId;
  final String contactId;
  final String enablerUid;
  final String eventId;
  final CallOutcome callOutcome;
  late final Optional<FollowUpStatus>followUpStatus;
  late final Optional<String>followUpNotes;
  late final Optional<DateTime>nextCallDate;
  late final Optional<int>callDuration;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  RecordCallLogVariables.fromJson(Map<String, dynamic> json):
  
  assignmentId = nativeFromJson<String>(json['assignmentId']),
  contactId = nativeFromJson<String>(json['contactId']),
  enablerUid = nativeFromJson<String>(json['enablerUid']),
  eventId = nativeFromJson<String>(json['eventId']),
  callOutcome = CallOutcome.values.byName(json['callOutcome']) {
  
  
  
  
  
  
  
    followUpStatus = Optional.optional((data) => FollowUpStatus.values.byName(data), enumSerializer);
    followUpStatus.value = json['followUpStatus'] == null ? null : FollowUpStatus.values.byName(json['followUpStatus']);
  
  
    followUpNotes = Optional.optional(nativeFromJson, nativeToJson);
    followUpNotes.value = json['followUpNotes'] == null ? null : nativeFromJson<String>(json['followUpNotes']);
  
  
    nextCallDate = Optional.optional(nativeFromJson, nativeToJson);
    nextCallDate.value = json['nextCallDate'] == null ? null : nativeFromJson<DateTime>(json['nextCallDate']);
  
  
    callDuration = Optional.optional(nativeFromJson, nativeToJson);
    callDuration.value = json['callDuration'] == null ? null : nativeFromJson<int>(json['callDuration']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordCallLogVariables otherTyped = other as RecordCallLogVariables;
    return assignmentId == otherTyped.assignmentId && 
    contactId == otherTyped.contactId && 
    enablerUid == otherTyped.enablerUid && 
    eventId == otherTyped.eventId && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus && 
    followUpNotes == otherTyped.followUpNotes && 
    nextCallDate == otherTyped.nextCallDate && 
    callDuration == otherTyped.callDuration;
    
  }
  @override
  int get hashCode => Object.hashAll([assignmentId.hashCode, contactId.hashCode, enablerUid.hashCode, eventId.hashCode, callOutcome.hashCode, followUpStatus.hashCode, followUpNotes.hashCode, nextCallDate.hashCode, callDuration.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignmentId'] = nativeToJson<String>(assignmentId);
    json['contactId'] = nativeToJson<String>(contactId);
    json['enablerUid'] = nativeToJson<String>(enablerUid);
    json['eventId'] = nativeToJson<String>(eventId);
    json['callOutcome'] = 
    callOutcome.name
    ;
    if(followUpStatus.state == OptionalState.set) {
      json['followUpStatus'] = followUpStatus.toJson();
    }
    if(followUpNotes.state == OptionalState.set) {
      json['followUpNotes'] = followUpNotes.toJson();
    }
    if(nextCallDate.state == OptionalState.set) {
      json['nextCallDate'] = nextCallDate.toJson();
    }
    if(callDuration.state == OptionalState.set) {
      json['callDuration'] = callDuration.toJson();
    }
    return json;
  }

  RecordCallLogVariables({
    required this.assignmentId,
    required this.contactId,
    required this.enablerUid,
    required this.eventId,
    required this.callOutcome,
    required this.followUpStatus,
    required this.followUpNotes,
    required this.nextCallDate,
    required this.callDuration,
  });
}

