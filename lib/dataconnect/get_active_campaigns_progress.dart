part of 'default.dart';

class GetActiveCampaignsProgressVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetActiveCampaignsProgressVariablesBuilder(this._dataConnect, );
  Deserializer<GetActiveCampaignsProgressData> dataDeserializer = (dynamic json)  => GetActiveCampaignsProgressData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetActiveCampaignsProgressData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetActiveCampaignsProgressData, void> ref() {
    
    return _dataConnect.query("GetActiveCampaignsProgress", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetActiveCampaignsProgressEvents {
  final String id;
  final String name;
  final List<GetActiveCampaignsProgressEventsAssignmentsOnEvent> assignments_on_event;
  GetActiveCampaignsProgressEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  assignments_on_event = (json['assignments_on_event'] as List<dynamic>)
        .map((e) => GetActiveCampaignsProgressEventsAssignmentsOnEvent.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveCampaignsProgressEvents otherTyped = other as GetActiveCampaignsProgressEvents;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    assignments_on_event == otherTyped.assignments_on_event;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, assignments_on_event.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['assignments_on_event'] = assignments_on_event.map((e) => e.toJson()).toList();
    return json;
  }

  GetActiveCampaignsProgressEvents({
    required this.id,
    required this.name,
    required this.assignments_on_event,
  });
}

@immutable
class GetActiveCampaignsProgressEventsAssignmentsOnEvent {
  final EnumValue<AssignmentStatus> status;
  GetActiveCampaignsProgressEventsAssignmentsOnEvent.fromJson(dynamic json):
  
  status = assignmentStatusDeserializer(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveCampaignsProgressEventsAssignmentsOnEvent otherTyped = other as GetActiveCampaignsProgressEventsAssignmentsOnEvent;
    return status == otherTyped.status;
    
  }
  @override
  int get hashCode => status.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status'] = 
    assignmentStatusSerializer(status)
    ;
    return json;
  }

  GetActiveCampaignsProgressEventsAssignmentsOnEvent({
    required this.status,
  });
}

@immutable
class GetActiveCampaignsProgressData {
  final List<GetActiveCampaignsProgressEvents> events;
  GetActiveCampaignsProgressData.fromJson(dynamic json):
  
  events = (json['events'] as List<dynamic>)
        .map((e) => GetActiveCampaignsProgressEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveCampaignsProgressData otherTyped = other as GetActiveCampaignsProgressData;
    return events == otherTyped.events;
    
  }
  @override
  int get hashCode => events.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['events'] = events.map((e) => e.toJson()).toList();
    return json;
  }

  GetActiveCampaignsProgressData({
    required this.events,
  });
}

