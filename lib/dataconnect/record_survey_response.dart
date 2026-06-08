part of 'default.dart';

class RecordSurveyResponseVariablesBuilder {
  String callLogId;
  String questionId;
  String answer;

  final FirebaseDataConnect _dataConnect;
  RecordSurveyResponseVariablesBuilder(this._dataConnect, {required  this.callLogId,required  this.questionId,required  this.answer,});
  Deserializer<RecordSurveyResponseData> dataDeserializer = (dynamic json)  => RecordSurveyResponseData.fromJson(jsonDecode(json));
  Serializer<RecordSurveyResponseVariables> varsSerializer = (RecordSurveyResponseVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RecordSurveyResponseData, RecordSurveyResponseVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RecordSurveyResponseData, RecordSurveyResponseVariables> ref() {
    RecordSurveyResponseVariables vars= RecordSurveyResponseVariables(callLogId: callLogId,questionId: questionId,answer: answer,);
    return _dataConnect.mutation("RecordSurveyResponse", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class RecordSurveyResponseSurveyResponseInsert {
  final String id;
  RecordSurveyResponseSurveyResponseInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordSurveyResponseSurveyResponseInsert otherTyped = other as RecordSurveyResponseSurveyResponseInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RecordSurveyResponseSurveyResponseInsert({
    required this.id,
  });
}

@immutable
class RecordSurveyResponseData {
  final RecordSurveyResponseSurveyResponseInsert surveyResponse_insert;
  RecordSurveyResponseData.fromJson(dynamic json):
  
  surveyResponse_insert = RecordSurveyResponseSurveyResponseInsert.fromJson(json['surveyResponse_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordSurveyResponseData otherTyped = other as RecordSurveyResponseData;
    return surveyResponse_insert == otherTyped.surveyResponse_insert;
    
  }
  @override
  int get hashCode => surveyResponse_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['surveyResponse_insert'] = surveyResponse_insert.toJson();
    return json;
  }

  RecordSurveyResponseData({
    required this.surveyResponse_insert,
  });
}

@immutable
class RecordSurveyResponseVariables {
  final String callLogId;
  final String questionId;
  final String answer;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  RecordSurveyResponseVariables.fromJson(Map<String, dynamic> json):
  
  callLogId = nativeFromJson<String>(json['callLogId']),
  questionId = nativeFromJson<String>(json['questionId']),
  answer = nativeFromJson<String>(json['answer']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RecordSurveyResponseVariables otherTyped = other as RecordSurveyResponseVariables;
    return callLogId == otherTyped.callLogId && 
    questionId == otherTyped.questionId && 
    answer == otherTyped.answer;
    
  }
  @override
  int get hashCode => Object.hashAll([callLogId.hashCode, questionId.hashCode, answer.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogId'] = nativeToJson<String>(callLogId);
    json['questionId'] = nativeToJson<String>(questionId);
    json['answer'] = nativeToJson<String>(answer);
    return json;
  }

  RecordSurveyResponseVariables({
    required this.callLogId,
    required this.questionId,
    required this.answer,
  });
}

