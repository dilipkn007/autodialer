part of 'default.dart';

class GetContactStatsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetContactStatsVariablesBuilder(this._dataConnect, );
  Deserializer<GetContactStatsData> dataDeserializer = (dynamic json)  => GetContactStatsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetContactStatsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetContactStatsData, void> ref() {
    
    return _dataConnect.query("GetContactStats", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetContactStatsTotalContacts {
  final String id;
  GetContactStatsTotalContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetContactStatsTotalContacts otherTyped = other as GetContactStatsTotalContacts;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetContactStatsTotalContacts({
    required this.id,
  });
}

@immutable
class GetContactStatsActiveContacts {
  final String id;
  GetContactStatsActiveContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetContactStatsActiveContacts otherTyped = other as GetContactStatsActiveContacts;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetContactStatsActiveContacts({
    required this.id,
  });
}

@immutable
class GetContactStatsDormantContacts {
  final String id;
  GetContactStatsDormantContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetContactStatsDormantContacts otherTyped = other as GetContactStatsDormantContacts;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetContactStatsDormantContacts({
    required this.id,
  });
}

@immutable
class GetContactStatsData {
  final List<GetContactStatsTotalContacts> totalContacts;
  final List<GetContactStatsActiveContacts> activeContacts;
  final List<GetContactStatsDormantContacts> dormantContacts;
  GetContactStatsData.fromJson(dynamic json):
  
  totalContacts = (json['totalContacts'] as List<dynamic>)
        .map((e) => GetContactStatsTotalContacts.fromJson(e))
        .toList(),
  activeContacts = (json['activeContacts'] as List<dynamic>)
        .map((e) => GetContactStatsActiveContacts.fromJson(e))
        .toList(),
  dormantContacts = (json['dormantContacts'] as List<dynamic>)
        .map((e) => GetContactStatsDormantContacts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetContactStatsData otherTyped = other as GetContactStatsData;
    return totalContacts == otherTyped.totalContacts && 
    activeContacts == otherTyped.activeContacts && 
    dormantContacts == otherTyped.dormantContacts;
    
  }
  @override
  int get hashCode => Object.hashAll([totalContacts.hashCode, activeContacts.hashCode, dormantContacts.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['totalContacts'] = totalContacts.map((e) => e.toJson()).toList();
    json['activeContacts'] = activeContacts.map((e) => e.toJson()).toList();
    json['dormantContacts'] = dormantContacts.map((e) => e.toJson()).toList();
    return json;
  }

  GetContactStatsData({
    required this.totalContacts,
    required this.activeContacts,
    required this.dormantContacts,
  });
}

