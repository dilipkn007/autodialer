part of 'default.dart';

class GetEnablerEventStatsVariablesBuilder {
  String enablerUid;
  String eventId;

  final FirebaseDataConnect _dataConnect;
  GetEnablerEventStatsVariablesBuilder(this._dataConnect, {required  this.enablerUid,required  this.eventId,});
  Deserializer<GetEnablerEventStatsData> dataDeserializer = (dynamic json)  => GetEnablerEventStatsData.fromJson(jsonDecode(json));
  Serializer<GetEnablerEventStatsVariables> varsSerializer = (GetEnablerEventStatsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetEnablerEventStatsData, GetEnablerEventStatsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetEnablerEventStatsData, GetEnablerEventStatsVariables> ref() {
    GetEnablerEventStatsVariables vars= GetEnablerEventStatsVariables(enablerUid: enablerUid,eventId: eventId,);
    return _dataConnect.query("GetEnablerEventStats", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetEnablerEventStatsTotalAssignments {
  final String id;
  GetEnablerEventStatsTotalAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnablerEventStatsTotalAssignments otherTyped = other as GetEnablerEventStatsTotalAssignments;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetEnablerEventStatsTotalAssignments({
    required this.id,
  });
}

@immutable
class GetEnablerEventStatsCompletedAssignments {
  final String id;
  GetEnablerEventStatsCompletedAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnablerEventStatsCompletedAssignments otherTyped = other as GetEnablerEventStatsCompletedAssignments;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetEnablerEventStatsCompletedAssignments({
    required this.id,
  });
}

@immutable
class GetEnablerEventStatsPendingAssignments {
  final String id;
  GetEnablerEventStatsPendingAssignments.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnablerEventStatsPendingAssignments otherTyped = other as GetEnablerEventStatsPendingAssignments;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetEnablerEventStatsPendingAssignments({
    required this.id,
  });
}

@immutable
class GetEnablerEventStatsData {
  final List<GetEnablerEventStatsTotalAssignments> totalAssignments;
  final List<GetEnablerEventStatsCompletedAssignments> completedAssignments;
  final List<GetEnablerEventStatsPendingAssignments> pendingAssignments;
  GetEnablerEventStatsData.fromJson(dynamic json):
  
  totalAssignments = (json['totalAssignments'] as List<dynamic>)
        .map((e) => GetEnablerEventStatsTotalAssignments.fromJson(e))
        .toList(),
  completedAssignments = (json['completedAssignments'] as List<dynamic>)
        .map((e) => GetEnablerEventStatsCompletedAssignments.fromJson(e))
        .toList(),
  pendingAssignments = (json['pendingAssignments'] as List<dynamic>)
        .map((e) => GetEnablerEventStatsPendingAssignments.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEnablerEventStatsData otherTyped = other as GetEnablerEventStatsData;
    return totalAssignments == otherTyped.totalAssignments && 
    completedAssignments == otherTyped.completedAssignments && 
    pendingAssignments == otherTyped.pendingAssignments;
    
  }
  @override
  int get hashCode => Object.hashAll([totalAssignments.hashCode, completedAssignments.hashCode, pendingAssignments.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['totalAssignments'] = totalAssignments.map((e) => e.toJson()).toList();
    json['completedAssignments'] = completedAssignments.map((e) => e.toJson()).toList();
    json['pendingAssignments'] = pendingAssignments.map((e) => e.toJson()).toList();
    return json;
  }

  GetEnablerEventStatsData({
    required this.totalAssignments,
    required this.completedAssignments,
    required this.pendingAssignments,
  });
}

@immutable
class GetEnablerEventStatsVariables {
  final String enablerUid;
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetEnablerEventStatsVariables.fromJson(Map<String, dynamic> json):
  
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

    final GetEnablerEventStatsVariables otherTyped = other as GetEnablerEventStatsVariables;
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

  GetEnablerEventStatsVariables({
    required this.enablerUid,
    required this.eventId,
  });
}

