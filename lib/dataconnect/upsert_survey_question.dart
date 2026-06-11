part of 'default.dart';

class UpsertSurveyQuestionVariablesBuilder {
  Optional<String> _id = Optional.optional(nativeFromJson, nativeToJson);
  String eventId;
  String questionTitle;
  QuestionType questionType;
  Optional<String> _options = Optional.optional(nativeFromJson, nativeToJson);
  int sortOrder;
  bool isRequired;

  final FirebaseDataConnect _dataConnect;
  UpsertSurveyQuestionVariablesBuilder id(String? t) {
   _id.value = t;
   return this;
  }
  UpsertSurveyQuestionVariablesBuilder options(String? t) {
   _options.value = t;
   return this;
  }

  UpsertSurveyQuestionVariablesBuilder(this._dataConnect, {required  this.eventId,required  this.questionTitle,required  this.questionType,required  this.sortOrder,required  this.isRequired,});
  Deserializer<UpsertSurveyQuestionData> dataDeserializer = (dynamic json)  => UpsertSurveyQuestionData.fromJson(jsonDecode(json));
  Serializer<UpsertSurveyQuestionVariables> varsSerializer = (UpsertSurveyQuestionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertSurveyQuestionData, UpsertSurveyQuestionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertSurveyQuestionData, UpsertSurveyQuestionVariables> ref() {
    UpsertSurveyQuestionVariables vars= UpsertSurveyQuestionVariables(id: _id,eventId: eventId,questionTitle: questionTitle,questionType: questionType,options: _options,sortOrder: sortOrder,isRequired: isRequired,);
    return _dataConnect.mutation("UpsertSurveyQuestion", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertSurveyQuestionSurveyQuestionUpsert {
  final String id;
  UpsertSurveyQuestionSurveyQuestionUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSurveyQuestionSurveyQuestionUpsert otherTyped = other as UpsertSurveyQuestionSurveyQuestionUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertSurveyQuestionSurveyQuestionUpsert({
    required this.id,
  });
}

@immutable
class UpsertSurveyQuestionData {
  final UpsertSurveyQuestionSurveyQuestionUpsert surveyQuestion_upsert;
  UpsertSurveyQuestionData.fromJson(dynamic json):
  
  surveyQuestion_upsert = UpsertSurveyQuestionSurveyQuestionUpsert.fromJson(json['surveyQuestion_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSurveyQuestionData otherTyped = other as UpsertSurveyQuestionData;
    return surveyQuestion_upsert == otherTyped.surveyQuestion_upsert;
    
  }
  @override
  int get hashCode => surveyQuestion_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['surveyQuestion_upsert'] = surveyQuestion_upsert.toJson();
    return json;
  }

  UpsertSurveyQuestionData({
    required this.surveyQuestion_upsert,
  });
}

@immutable
class UpsertSurveyQuestionVariables {
  late final Optional<String>id;
  final String eventId;
  final String questionTitle;
  final QuestionType questionType;
  late final Optional<String>options;
  final int sortOrder;
  final bool isRequired;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertSurveyQuestionVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']),
  questionTitle = nativeFromJson<String>(json['questionTitle']),
  questionType = QuestionType.values.byName(json['questionType']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  isRequired = nativeFromJson<bool>(json['isRequired']) {
  
  
    id = Optional.optional(nativeFromJson, nativeToJson);
    id.value = json['id'] == null ? null : nativeFromJson<String>(json['id']);
  
  
  
  
  
    options = Optional.optional(nativeFromJson, nativeToJson);
    options.value = json['options'] == null ? null : nativeFromJson<String>(json['options']);
  
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSurveyQuestionVariables otherTyped = other as UpsertSurveyQuestionVariables;
    return id == otherTyped.id && 
    eventId == otherTyped.eventId && 
    questionTitle == otherTyped.questionTitle && 
    questionType == otherTyped.questionType && 
    options == otherTyped.options && 
    sortOrder == otherTyped.sortOrder && 
    isRequired == otherTyped.isRequired;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, eventId.hashCode, questionTitle.hashCode, questionType.hashCode, options.hashCode, sortOrder.hashCode, isRequired.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(id.state == OptionalState.set) {
      json['id'] = id.toJson();
    }
    json['eventId'] = nativeToJson<String>(eventId);
    json['questionTitle'] = nativeToJson<String>(questionTitle);
    json['questionType'] = 
    questionType.name
    ;
    if(options.state == OptionalState.set) {
      json['options'] = options.toJson();
    }
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    json['isRequired'] = nativeToJson<bool>(isRequired);
    return json;
  }

  UpsertSurveyQuestionVariables({
    required this.id,
    required this.eventId,
    required this.questionTitle,
    required this.questionType,
    required this.options,
    required this.sortOrder,
    required this.isRequired,
  });
}

