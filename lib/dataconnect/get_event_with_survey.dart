part of 'default.dart';

class GetEventWithSurveyVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  GetEventWithSurveyVariablesBuilder(this._dataConnect, {required  this.eventId,});
  Deserializer<GetEventWithSurveyData> dataDeserializer = (dynamic json)  => GetEventWithSurveyData.fromJson(jsonDecode(json));
  Serializer<GetEventWithSurveyVariables> varsSerializer = (GetEventWithSurveyVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetEventWithSurveyData, GetEventWithSurveyVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetEventWithSurveyData, GetEventWithSurveyVariables> ref() {
    GetEventWithSurveyVariables vars= GetEventWithSurveyVariables(eventId: eventId,);
    return _dataConnect.query("GetEventWithSurvey", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetEventWithSurveyEvent {
  final String id;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String? eventTime;
  final EnumValue<EventStatus> status;
  final int? gapDuration;
  final String? audienceFilter;
  final GetEventWithSurveyEventCreatedBy createdBy;
  final List<GetEventWithSurveyEventSurveyQuestionsOnEvent> surveyQuestions_on_event;
  GetEventWithSurveyEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  eventTime = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']),
  status = eventStatusDeserializer(json['status']),
  gapDuration = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']),
  audienceFilter = json['audienceFilter'] == null ? null : nativeFromJson<String>(json['audienceFilter']),
  createdBy = GetEventWithSurveyEventCreatedBy.fromJson(json['createdBy']),
  surveyQuestions_on_event = (json['surveyQuestions_on_event'] as List<dynamic>)
        .map((e) => GetEventWithSurveyEventSurveyQuestionsOnEvent.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventWithSurveyEvent otherTyped = other as GetEventWithSurveyEvent;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    status == otherTyped.status && 
    gapDuration == otherTyped.gapDuration && 
    audienceFilter == otherTyped.audienceFilter && 
    createdBy == otherTyped.createdBy && 
    surveyQuestions_on_event == otherTyped.surveyQuestions_on_event;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, status.hashCode, gapDuration.hashCode, audienceFilter.hashCode, createdBy.hashCode, surveyQuestions_on_event.hashCode]);
  

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
    if (audienceFilter != null) {
      json['audienceFilter'] = nativeToJson<String?>(audienceFilter);
    }
    json['createdBy'] = createdBy.toJson();
    json['surveyQuestions_on_event'] = surveyQuestions_on_event.map((e) => e.toJson()).toList();
    return json;
  }

  GetEventWithSurveyEvent({
    required this.id,
    required this.name,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.status,
    this.gapDuration,
    this.audienceFilter,
    required this.createdBy,
    required this.surveyQuestions_on_event,
  });
}

@immutable
class GetEventWithSurveyEventCreatedBy {
  final String name;
  GetEventWithSurveyEventCreatedBy.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventWithSurveyEventCreatedBy otherTyped = other as GetEventWithSurveyEventCreatedBy;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetEventWithSurveyEventCreatedBy({
    required this.name,
  });
}

@immutable
class GetEventWithSurveyEventSurveyQuestionsOnEvent {
  final String id;
  final String questionTitle;
  final EnumValue<QuestionType> questionType;
  final String? options;
  final int sortOrder;
  final bool isRequired;
  GetEventWithSurveyEventSurveyQuestionsOnEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  questionTitle = nativeFromJson<String>(json['questionTitle']),
  questionType = questionTypeDeserializer(json['questionType']),
  options = json['options'] == null ? null : nativeFromJson<String>(json['options']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  isRequired = nativeFromJson<bool>(json['isRequired']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventWithSurveyEventSurveyQuestionsOnEvent otherTyped = other as GetEventWithSurveyEventSurveyQuestionsOnEvent;
    return id == otherTyped.id && 
    questionTitle == otherTyped.questionTitle && 
    questionType == otherTyped.questionType && 
    options == otherTyped.options && 
    sortOrder == otherTyped.sortOrder && 
    isRequired == otherTyped.isRequired;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, questionTitle.hashCode, questionType.hashCode, options.hashCode, sortOrder.hashCode, isRequired.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['questionTitle'] = nativeToJson<String>(questionTitle);
    json['questionType'] = 
    questionTypeSerializer(questionType)
    ;
    if (options != null) {
      json['options'] = nativeToJson<String?>(options);
    }
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    json['isRequired'] = nativeToJson<bool>(isRequired);
    return json;
  }

  GetEventWithSurveyEventSurveyQuestionsOnEvent({
    required this.id,
    required this.questionTitle,
    required this.questionType,
    this.options,
    required this.sortOrder,
    required this.isRequired,
  });
}

@immutable
class GetEventWithSurveyData {
  final GetEventWithSurveyEvent? event;
  GetEventWithSurveyData.fromJson(dynamic json):
  
  event = json['event'] == null ? null : GetEventWithSurveyEvent.fromJson(json['event']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventWithSurveyData otherTyped = other as GetEventWithSurveyData;
    return event == otherTyped.event;
    
  }
  @override
  int get hashCode => event.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (event != null) {
      json['event'] = event!.toJson();
    }
    return json;
  }

  GetEventWithSurveyData({
    this.event,
  });
}

@immutable
class GetEventWithSurveyVariables {
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetEventWithSurveyVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventWithSurveyVariables otherTyped = other as GetEventWithSurveyVariables;
    return eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => eventId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  GetEventWithSurveyVariables({
    required this.eventId,
  });
}

