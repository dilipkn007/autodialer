part of 'default.dart';

class AddSurveyQuestionVariablesBuilder {
  String eventId;
  String questionTitle;
  QuestionType questionType;
  Optional<String> _options = Optional.optional(nativeFromJson, nativeToJson);
  int sortOrder;
  bool isRequired;

  final FirebaseDataConnect _dataConnect;  AddSurveyQuestionVariablesBuilder options(String? t) {
   _options.value = t;
   return this;
  }

  AddSurveyQuestionVariablesBuilder(this._dataConnect, {required  this.eventId,required  this.questionTitle,required  this.questionType,required  this.sortOrder,required  this.isRequired,});
  Deserializer<AddSurveyQuestionData> dataDeserializer = (dynamic json)  => AddSurveyQuestionData.fromJson(jsonDecode(json));
  Serializer<AddSurveyQuestionVariables> varsSerializer = (AddSurveyQuestionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddSurveyQuestionData, AddSurveyQuestionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddSurveyQuestionData, AddSurveyQuestionVariables> ref() {
    AddSurveyQuestionVariables vars= AddSurveyQuestionVariables(eventId: eventId,questionTitle: questionTitle,questionType: questionType,options: _options,sortOrder: sortOrder,isRequired: isRequired,);
    return _dataConnect.mutation("AddSurveyQuestion", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddSurveyQuestionSurveyQuestionInsert {
  final String id;
  AddSurveyQuestionSurveyQuestionInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddSurveyQuestionSurveyQuestionInsert otherTyped = other as AddSurveyQuestionSurveyQuestionInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddSurveyQuestionSurveyQuestionInsert({
    required this.id,
  });
}

@immutable
class AddSurveyQuestionData {
  final AddSurveyQuestionSurveyQuestionInsert surveyQuestion_insert;
  AddSurveyQuestionData.fromJson(dynamic json):
  
  surveyQuestion_insert = AddSurveyQuestionSurveyQuestionInsert.fromJson(json['surveyQuestion_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddSurveyQuestionData otherTyped = other as AddSurveyQuestionData;
    return surveyQuestion_insert == otherTyped.surveyQuestion_insert;
    
  }
  @override
  int get hashCode => surveyQuestion_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['surveyQuestion_insert'] = surveyQuestion_insert.toJson();
    return json;
  }

  AddSurveyQuestionData({
    required this.surveyQuestion_insert,
  });
}

@immutable
class AddSurveyQuestionVariables {
  final String eventId;
  final String questionTitle;
  final QuestionType questionType;
  late final Optional<String>options;
  final int sortOrder;
  final bool isRequired;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddSurveyQuestionVariables.fromJson(Map<String, dynamic> json):
  
  eventId = nativeFromJson<String>(json['eventId']),
  questionTitle = nativeFromJson<String>(json['questionTitle']),
  questionType = QuestionType.values.byName(json['questionType']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  isRequired = nativeFromJson<bool>(json['isRequired']) {
  
  
  
  
  
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

    final AddSurveyQuestionVariables otherTyped = other as AddSurveyQuestionVariables;
    return eventId == otherTyped.eventId && 
    questionTitle == otherTyped.questionTitle && 
    questionType == otherTyped.questionType && 
    options == otherTyped.options && 
    sortOrder == otherTyped.sortOrder && 
    isRequired == otherTyped.isRequired;
    
  }
  @override
  int get hashCode => Object.hashAll([eventId.hashCode, questionTitle.hashCode, questionType.hashCode, options.hashCode, sortOrder.hashCode, isRequired.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
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

  AddSurveyQuestionVariables({
    required this.eventId,
    required this.questionTitle,
    required this.questionType,
    required this.options,
    required this.sortOrder,
    required this.isRequired,
  });
}

