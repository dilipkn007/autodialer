part of 'default.dart';

class CreateEventVariablesBuilder {
  String name;
  Optional<String> _description = Optional.optional(nativeFromJson, nativeToJson);
  DateTime eventDate;
  Optional<String> _eventTime = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _audienceFilter = Optional.optional(nativeFromJson, nativeToJson);
  EventStatus status;
  Optional<int> _gapDuration = Optional.optional(nativeFromJson, nativeToJson);
  String createdByUid;

  final FirebaseDataConnect _dataConnect;  CreateEventVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  CreateEventVariablesBuilder eventTime(String? t) {
   _eventTime.value = t;
   return this;
  }
  CreateEventVariablesBuilder audienceFilter(String? t) {
   _audienceFilter.value = t;
   return this;
  }
  CreateEventVariablesBuilder gapDuration(int? t) {
   _gapDuration.value = t;
   return this;
  }

  CreateEventVariablesBuilder(this._dataConnect, {required  this.name,required  this.eventDate,required  this.status,required  this.createdByUid,});
  Deserializer<CreateEventData> dataDeserializer = (dynamic json)  => CreateEventData.fromJson(jsonDecode(json));
  Serializer<CreateEventVariables> varsSerializer = (CreateEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateEventData, CreateEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateEventData, CreateEventVariables> ref() {
    CreateEventVariables vars= CreateEventVariables(name: name,description: _description,eventDate: eventDate,eventTime: _eventTime,audienceFilter: _audienceFilter,status: status,gapDuration: _gapDuration,createdByUid: createdByUid,);
    return _dataConnect.mutation("CreateEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateEventEventInsert {
  final String id;
  CreateEventEventInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEventEventInsert otherTyped = other as CreateEventEventInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateEventEventInsert({
    required this.id,
  });
}

@immutable
class CreateEventData {
  final CreateEventEventInsert event_insert;
  CreateEventData.fromJson(dynamic json):
  
  event_insert = CreateEventEventInsert.fromJson(json['event_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEventData otherTyped = other as CreateEventData;
    return event_insert == otherTyped.event_insert;
    
  }
  @override
  int get hashCode => event_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['event_insert'] = event_insert.toJson();
    return json;
  }

  CreateEventData({
    required this.event_insert,
  });
}

@immutable
class CreateEventVariables {
  final String name;
  late final Optional<String>description;
  final DateTime eventDate;
  late final Optional<String>eventTime;
  late final Optional<String>audienceFilter;
  final EventStatus status;
  late final Optional<int>gapDuration;
  final String createdByUid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateEventVariables.fromJson(Map<String, dynamic> json):
  
  name = nativeFromJson<String>(json['name']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  status = EventStatus.values.byName(json['status']),
  createdByUid = nativeFromJson<String>(json['createdByUid']) {
  
  
  
    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  
  
  
    eventTime = Optional.optional(nativeFromJson, nativeToJson);
    eventTime.value = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']);
  
  
    audienceFilter = Optional.optional(nativeFromJson, nativeToJson);
    audienceFilter.value = json['audienceFilter'] == null ? null : nativeFromJson<String>(json['audienceFilter']);
  
  
  
    gapDuration = Optional.optional(nativeFromJson, nativeToJson);
    gapDuration.value = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEventVariables otherTyped = other as CreateEventVariables;
    return name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    audienceFilter == otherTyped.audienceFilter && 
    status == otherTyped.status && 
    gapDuration == otherTyped.gapDuration && 
    createdByUid == otherTyped.createdByUid;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, audienceFilter.hashCode, status.hashCode, gapDuration.hashCode, createdByUid.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    if(description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    json['eventDate'] = nativeToJson<DateTime>(eventDate);
    if(eventTime.state == OptionalState.set) {
      json['eventTime'] = eventTime.toJson();
    }
    if(audienceFilter.state == OptionalState.set) {
      json['audienceFilter'] = audienceFilter.toJson();
    }
    json['status'] = 
    status.name
    ;
    if(gapDuration.state == OptionalState.set) {
      json['gapDuration'] = gapDuration.toJson();
    }
    json['createdByUid'] = nativeToJson<String>(createdByUid);
    return json;
  }

  CreateEventVariables({
    required this.name,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.audienceFilter,
    required this.status,
    required this.gapDuration,
    required this.createdByUid,
  });
}

