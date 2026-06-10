part of 'default.dart';

class GetDashboardOverviewStatsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetDashboardOverviewStatsVariablesBuilder(this._dataConnect, );
  Deserializer<GetDashboardOverviewStatsData> dataDeserializer = (dynamic json)  => GetDashboardOverviewStatsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetDashboardOverviewStatsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetDashboardOverviewStatsData, void> ref() {
    
    return _dataConnect.query("GetDashboardOverviewStats", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetDashboardOverviewStatsTotalContacts {
  final String id;
  GetDashboardOverviewStatsTotalContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsTotalContacts otherTyped = other as GetDashboardOverviewStatsTotalContacts;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetDashboardOverviewStatsTotalContacts({
    required this.id,
  });
}

@immutable
class GetDashboardOverviewStatsActiveContacts {
  final String id;
  GetDashboardOverviewStatsActiveContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsActiveContacts otherTyped = other as GetDashboardOverviewStatsActiveContacts;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetDashboardOverviewStatsActiveContacts({
    required this.id,
  });
}

@immutable
class GetDashboardOverviewStatsTotalEnablers {
  final String uid;
  GetDashboardOverviewStatsTotalEnablers.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsTotalEnablers otherTyped = other as GetDashboardOverviewStatsTotalEnablers;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetDashboardOverviewStatsTotalEnablers({
    required this.uid,
  });
}

@immutable
class GetDashboardOverviewStatsTotalEvents {
  final String id;
  GetDashboardOverviewStatsTotalEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsTotalEvents otherTyped = other as GetDashboardOverviewStatsTotalEvents;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetDashboardOverviewStatsTotalEvents({
    required this.id,
  });
}

@immutable
class GetDashboardOverviewStatsActiveEvents {
  final String id;
  GetDashboardOverviewStatsActiveEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsActiveEvents otherTyped = other as GetDashboardOverviewStatsActiveEvents;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetDashboardOverviewStatsActiveEvents({
    required this.id,
  });
}

@immutable
class GetDashboardOverviewStatsTotalCalls {
  final String id;
  GetDashboardOverviewStatsTotalCalls.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsTotalCalls otherTyped = other as GetDashboardOverviewStatsTotalCalls;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetDashboardOverviewStatsTotalCalls({
    required this.id,
  });
}

@immutable
class GetDashboardOverviewStatsData {
  final List<GetDashboardOverviewStatsTotalContacts> totalContacts;
  final List<GetDashboardOverviewStatsActiveContacts> activeContacts;
  final List<GetDashboardOverviewStatsTotalEnablers> totalEnablers;
  final List<GetDashboardOverviewStatsTotalEvents> totalEvents;
  final List<GetDashboardOverviewStatsActiveEvents> activeEvents;
  final List<GetDashboardOverviewStatsTotalCalls> totalCalls;
  GetDashboardOverviewStatsData.fromJson(dynamic json):
  
  totalContacts = (json['totalContacts'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsTotalContacts.fromJson(e))
        .toList(),
  activeContacts = (json['activeContacts'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsActiveContacts.fromJson(e))
        .toList(),
  totalEnablers = (json['totalEnablers'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsTotalEnablers.fromJson(e))
        .toList(),
  totalEvents = (json['totalEvents'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsTotalEvents.fromJson(e))
        .toList(),
  activeEvents = (json['activeEvents'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsActiveEvents.fromJson(e))
        .toList(),
  totalCalls = (json['totalCalls'] as List<dynamic>)
        .map((e) => GetDashboardOverviewStatsTotalCalls.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetDashboardOverviewStatsData otherTyped = other as GetDashboardOverviewStatsData;
    return totalContacts == otherTyped.totalContacts && 
    activeContacts == otherTyped.activeContacts && 
    totalEnablers == otherTyped.totalEnablers && 
    totalEvents == otherTyped.totalEvents && 
    activeEvents == otherTyped.activeEvents && 
    totalCalls == otherTyped.totalCalls;
    
  }
  @override
  int get hashCode => Object.hashAll([totalContacts.hashCode, activeContacts.hashCode, totalEnablers.hashCode, totalEvents.hashCode, activeEvents.hashCode, totalCalls.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['totalContacts'] = totalContacts.map((e) => e.toJson()).toList();
    json['activeContacts'] = activeContacts.map((e) => e.toJson()).toList();
    json['totalEnablers'] = totalEnablers.map((e) => e.toJson()).toList();
    json['totalEvents'] = totalEvents.map((e) => e.toJson()).toList();
    json['activeEvents'] = activeEvents.map((e) => e.toJson()).toList();
    json['totalCalls'] = totalCalls.map((e) => e.toJson()).toList();
    return json;
  }

  GetDashboardOverviewStatsData({
    required this.totalContacts,
    required this.activeContacts,
    required this.totalEnablers,
    required this.totalEvents,
    required this.activeEvents,
    required this.totalCalls,
  });
}

