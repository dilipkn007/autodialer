part of 'default.dart';

class GetRecentActivityVariablesBuilder {
  int limit;

  final FirebaseDataConnect _dataConnect;
  GetRecentActivityVariablesBuilder(this._dataConnect, {required  this.limit,});
  Deserializer<GetRecentActivityData> dataDeserializer = (dynamic json)  => GetRecentActivityData.fromJson(jsonDecode(json));
  Serializer<GetRecentActivityVariables> varsSerializer = (GetRecentActivityVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetRecentActivityData, GetRecentActivityVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetRecentActivityData, GetRecentActivityVariables> ref() {
    GetRecentActivityVariables vars= GetRecentActivityVariables(limit: limit,);
    return _dataConnect.query("GetRecentActivity", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetRecentActivityCallLogs {
  final String id;
  final EnumValue<CallOutcome> callOutcome;
  final EnumValue<FollowUpStatus>? followUpStatus;
  final Timestamp calledAt;
  final GetRecentActivityCallLogsContact contact;
  final GetRecentActivityCallLogsEnabler enabler;
  final GetRecentActivityCallLogsEvent event;
  GetRecentActivityCallLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  callOutcome = callOutcomeDeserializer(json['callOutcome']),
  followUpStatus = json['followUpStatus'] == null ? null : followUpStatusDeserializer(json['followUpStatus']),
  calledAt = Timestamp.fromJson(json['calledAt']),
  contact = GetRecentActivityCallLogsContact.fromJson(json['contact']),
  enabler = GetRecentActivityCallLogsEnabler.fromJson(json['enabler']),
  event = GetRecentActivityCallLogsEvent.fromJson(json['event']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityCallLogs otherTyped = other as GetRecentActivityCallLogs;
    return id == otherTyped.id && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus && 
    calledAt == otherTyped.calledAt && 
    contact == otherTyped.contact && 
    enabler == otherTyped.enabler && 
    event == otherTyped.event;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, callOutcome.hashCode, followUpStatus.hashCode, calledAt.hashCode, contact.hashCode, enabler.hashCode, event.hashCode]);
  

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
    json['calledAt'] = calledAt.toJson();
    json['contact'] = contact.toJson();
    json['enabler'] = enabler.toJson();
    json['event'] = event.toJson();
    return json;
  }

  GetRecentActivityCallLogs({
    required this.id,
    required this.callOutcome,
    this.followUpStatus,
    required this.calledAt,
    required this.contact,
    required this.enabler,
    required this.event,
  });
}

@immutable
class GetRecentActivityCallLogsContact {
  final String name;
  final String? folkId;
  GetRecentActivityCallLogsContact.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityCallLogsContact otherTyped = other as GetRecentActivityCallLogsContact;
    return name == otherTyped.name && 
    folkId == otherTyped.folkId;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, folkId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    return json;
  }

  GetRecentActivityCallLogsContact({
    required this.name,
    this.folkId,
  });
}

@immutable
class GetRecentActivityCallLogsEnabler {
  final String name;
  GetRecentActivityCallLogsEnabler.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityCallLogsEnabler otherTyped = other as GetRecentActivityCallLogsEnabler;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetRecentActivityCallLogsEnabler({
    required this.name,
  });
}

@immutable
class GetRecentActivityCallLogsEvent {
  final String name;
  GetRecentActivityCallLogsEvent.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityCallLogsEvent otherTyped = other as GetRecentActivityCallLogsEvent;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetRecentActivityCallLogsEvent({
    required this.name,
  });
}

@immutable
class GetRecentActivityData {
  final List<GetRecentActivityCallLogs> callLogs;
  GetRecentActivityData.fromJson(dynamic json):
  
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => GetRecentActivityCallLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityData otherTyped = other as GetRecentActivityData;
    return callLogs == otherTyped.callLogs;
    
  }
  @override
  int get hashCode => callLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    return json;
  }

  GetRecentActivityData({
    required this.callLogs,
  });
}

@immutable
class GetRecentActivityVariables {
  final int limit;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetRecentActivityVariables.fromJson(Map<String, dynamic> json):
  
  limit = nativeFromJson<int>(json['limit']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentActivityVariables otherTyped = other as GetRecentActivityVariables;
    return limit == otherTyped.limit;
    
  }
  @override
  int get hashCode => limit.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['limit'] = nativeToJson<int>(limit);
    return json;
  }

  GetRecentActivityVariables({
    required this.limit,
  });
}

