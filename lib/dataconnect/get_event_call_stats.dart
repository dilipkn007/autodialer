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
class GetEventCallStatsData {
  final List<GetEventCallStatsCallLogs> callLogs;
  GetEventCallStatsData.fromJson(dynamic json):
  
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => GetEventCallStatsCallLogs.fromJson(e))
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
    return callLogs == otherTyped.callLogs;
    
  }
  @override
  int get hashCode => callLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    return json;
  }

  GetEventCallStatsData({
    required this.callLogs,
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

