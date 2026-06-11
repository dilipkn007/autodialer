part of 'default.dart';

class UpdateEventVariablesBuilder {
  String id;
  String name;
  Optional<String> _description = Optional.optional(nativeFromJson, nativeToJson);
  DateTime eventDate;
  Optional<String> _eventTime = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _audienceFilter = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateEventVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpdateEventVariablesBuilder eventTime(String? t) {
   _eventTime.value = t;
   return this;
  }
  UpdateEventVariablesBuilder audienceFilter(String? t) {
   _audienceFilter.value = t;
   return this;
  }

  UpdateEventVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,required  this.eventDate,});
  Deserializer<UpdateEventData> dataDeserializer = (dynamic json)  => UpdateEventData.fromJson(jsonDecode(json));
  Serializer<UpdateEventVariables> varsSerializer = (UpdateEventVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateEventData, UpdateEventVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateEventData, UpdateEventVariables> ref() {
    UpdateEventVariables vars= UpdateEventVariables(id: id,name: name,description: _description,eventDate: eventDate,eventTime: _eventTime,audienceFilter: _audienceFilter,);
    return _dataConnect.mutation("UpdateEvent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateEventEventUpdate {
  final String id;
  UpdateEventEventUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEventEventUpdate otherTyped = other as UpdateEventEventUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateEventEventUpdate({
    required this.id,
  });
}

@immutable
class UpdateEventData {
  final UpdateEventEventUpdate? event_update;
  UpdateEventData.fromJson(dynamic json):
  
  event_update = json['event_update'] == null ? null : UpdateEventEventUpdate.fromJson(json['event_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEventData otherTyped = other as UpdateEventData;
    return event_update == otherTyped.event_update;
    
  }
  @override
  int get hashCode => event_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (event_update != null) {
      json['event_update'] = event_update!.toJson();
    }
    return json;
  }

  UpdateEventData({
    this.event_update,
  });
}

@immutable
class UpdateEventVariables {
  final String id;
  final String name;
  late final Optional<String>description;
  final DateTime eventDate;
  late final Optional<String>eventTime;
  late final Optional<String>audienceFilter;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateEventVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']) {
  
  
  
  
    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  
  
  
    eventTime = Optional.optional(nativeFromJson, nativeToJson);
    eventTime.value = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']);
  
  
    audienceFilter = Optional.optional(nativeFromJson, nativeToJson);
    audienceFilter.value = json['audienceFilter'] == null ? null : nativeFromJson<String>(json['audienceFilter']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEventVariables otherTyped = other as UpdateEventVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    audienceFilter == otherTyped.audienceFilter;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, audienceFilter.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
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
    return json;
  }

  UpdateEventVariables({
    required this.id,
    required this.name,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.audienceFilter,
  });
}

