part of 'default.dart';

class ListEventsVariablesBuilder {
  Optional<EventStatus> _status = Optional.optional((data) => EventStatus.values.byName(data), enumSerializer);

  final FirebaseDataConnect _dataConnect;
  ListEventsVariablesBuilder status(EventStatus? t) {
   _status.value = t;
   return this;
  }

  ListEventsVariablesBuilder(this._dataConnect, );
  Deserializer<ListEventsData> dataDeserializer = (dynamic json)  => ListEventsData.fromJson(jsonDecode(json));
  Serializer<ListEventsVariables> varsSerializer = (ListEventsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListEventsData, ListEventsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListEventsData, ListEventsVariables> ref() {
    ListEventsVariables vars= ListEventsVariables(status: _status,);
    return _dataConnect.query("ListEvents", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListEventsEvents {
  final String id;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String? eventTime;
  final EnumValue<EventStatus> status;
  final int? gapDuration;
  final ListEventsEventsCreatedBy createdBy;
  final Timestamp createdAt;
  ListEventsEvents.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  eventTime = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']),
  status = eventStatusDeserializer(json['status']),
  gapDuration = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']),
  createdBy = ListEventsEventsCreatedBy.fromJson(json['createdBy']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEventsEvents otherTyped = other as ListEventsEvents;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    status == otherTyped.status && 
    gapDuration == otherTyped.gapDuration && 
    createdBy == otherTyped.createdBy && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, status.hashCode, gapDuration.hashCode, createdBy.hashCode, createdAt.hashCode]);
  

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
    if (gapDuration != null) {
      json['gapDuration'] = nativeToJson<int?>(gapDuration);
    }
    json['createdBy'] = createdBy.toJson();
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListEventsEvents({
    required this.id,
    required this.name,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.status,
    this.gapDuration,
    required this.createdBy,
    required this.createdAt,
  });
}

@immutable
class ListEventsEventsCreatedBy {
  final String name;
  ListEventsEventsCreatedBy.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEventsEventsCreatedBy otherTyped = other as ListEventsEventsCreatedBy;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListEventsEventsCreatedBy({
    required this.name,
  });
}

@immutable
class ListEventsData {
  final List<ListEventsEvents> events;
  ListEventsData.fromJson(dynamic json):
  
  events = (json['events'] as List<dynamic>)
        .map((e) => ListEventsEvents.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEventsData otherTyped = other as ListEventsData;
    return events == otherTyped.events;
    
  }
  @override
  int get hashCode => events.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['events'] = events.map((e) => e.toJson()).toList();
    return json;
  }

  ListEventsData({
    required this.events,
  });
}

@immutable
class ListEventsVariables {
  late final Optional<EventStatus>status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListEventsVariables.fromJson(Map<String, dynamic> json) {
  
  
    status = Optional.optional((data) => EventStatus.values.byName(data), enumSerializer);
    status.value = json['status'] == null ? null : EventStatus.values.byName(json['status']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEventsVariables otherTyped = other as ListEventsVariables;
    return status == otherTyped.status;
    
  }
  @override
  int get hashCode => status.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  ListEventsVariables({
    required this.status,
  });
}

