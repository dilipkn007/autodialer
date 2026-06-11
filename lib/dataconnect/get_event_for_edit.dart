part of 'default.dart';

class GetEventForEditVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  GetEventForEditVariablesBuilder(this._dataConnect, {required  this.eventId,});
  Deserializer<GetEventForEditData> dataDeserializer = (dynamic json)  => GetEventForEditData.fromJson(jsonDecode(json));
  Serializer<GetEventForEditVariables> varsSerializer = (GetEventForEditVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetEventForEditData, GetEventForEditVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetEventForEditData, GetEventForEditVariables> ref() {
    GetEventForEditVariables vars= GetEventForEditVariables(eventId: eventId,);
    return _dataConnect.query("GetEventForEdit", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetEventForEditEvent {
  final String id;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String? eventTime;
  final String? audienceFilter;
  final EnumValue<EventStatus> status;
  final int? gapDuration;
  final List<GetEventForEditEventSurveyQuestionsOnEvent> surveyQuestions_on_event;
  GetEventForEditEvent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  eventDate = nativeFromJson<DateTime>(json['eventDate']),
  eventTime = json['eventTime'] == null ? null : nativeFromJson<String>(json['eventTime']),
  audienceFilter = json['audienceFilter'] == null ? null : nativeFromJson<String>(json['audienceFilter']),
  status = eventStatusDeserializer(json['status']),
  gapDuration = json['gapDuration'] == null ? null : nativeFromJson<int>(json['gapDuration']),
  surveyQuestions_on_event = (json['surveyQuestions_on_event'] as List<dynamic>)
        .map((e) => GetEventForEditEventSurveyQuestionsOnEvent.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventForEditEvent otherTyped = other as GetEventForEditEvent;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    eventDate == otherTyped.eventDate && 
    eventTime == otherTyped.eventTime && 
    audienceFilter == otherTyped.audienceFilter && 
    status == otherTyped.status && 
    gapDuration == otherTyped.gapDuration && 
    surveyQuestions_on_event == otherTyped.surveyQuestions_on_event;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, description.hashCode, eventDate.hashCode, eventTime.hashCode, audienceFilter.hashCode, status.hashCode, gapDuration.hashCode, surveyQuestions_on_event.hashCode]);
  

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
    if (audienceFilter != null) {
      json['audienceFilter'] = nativeToJson<String?>(audienceFilter);
    }
    json['status'] = 
    eventStatusSerializer(status)
    ;
    if (gapDuration != null) {
      json['gapDuration'] = nativeToJson<int?>(gapDuration);
    }
    json['surveyQuestions_on_event'] = surveyQuestions_on_event.map((e) => e.toJson()).toList();
    return json;
  }

  GetEventForEditEvent({
    required this.id,
    required this.name,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.audienceFilter,
    required this.status,
    this.gapDuration,
    required this.surveyQuestions_on_event,
  });
}

@immutable
class GetEventForEditEventSurveyQuestionsOnEvent {
  final String id;
  final String questionTitle;
  final EnumValue<QuestionType> questionType;
  final String? options;
  final int sortOrder;
  final bool isRequired;
  GetEventForEditEventSurveyQuestionsOnEvent.fromJson(dynamic json):
  
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

    final GetEventForEditEventSurveyQuestionsOnEvent otherTyped = other as GetEventForEditEventSurveyQuestionsOnEvent;
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

  GetEventForEditEventSurveyQuestionsOnEvent({
    required this.id,
    required this.questionTitle,
    required this.questionType,
    this.options,
    required this.sortOrder,
    required this.isRequired,
  });
}

@immutable
class GetEventForEditData {
  final GetEventForEditEvent? event;
  GetEventForEditData.fromJson(dynamic json):
  
  event = json['event'] == null ? null : GetEventForEditEvent.fromJson(json['event']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventForEditData otherTyped = other as GetEventForEditData;
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

  GetEventForEditData({
    this.event,
  });
}

@immutable
class GetEventForEditVariables {
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetEventForEditVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetEventForEditVariables otherTyped = other as GetEventForEditVariables;
    return eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => eventId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  GetEventForEditVariables({
    required this.eventId,
  });
}

