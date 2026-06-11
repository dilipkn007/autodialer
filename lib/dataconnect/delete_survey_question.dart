part of 'default.dart';

class DeleteSurveyQuestionVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteSurveyQuestionVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteSurveyQuestionData> dataDeserializer = (dynamic json)  => DeleteSurveyQuestionData.fromJson(jsonDecode(json));
  Serializer<DeleteSurveyQuestionVariables> varsSerializer = (DeleteSurveyQuestionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSurveyQuestionData, DeleteSurveyQuestionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSurveyQuestionData, DeleteSurveyQuestionVariables> ref() {
    DeleteSurveyQuestionVariables vars= DeleteSurveyQuestionVariables(id: id,);
    return _dataConnect.mutation("DeleteSurveyQuestion", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSurveyQuestionSurveyQuestionDelete {
  final String id;
  DeleteSurveyQuestionSurveyQuestionDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSurveyQuestionSurveyQuestionDelete otherTyped = other as DeleteSurveyQuestionSurveyQuestionDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSurveyQuestionSurveyQuestionDelete({
    required this.id,
  });
}

@immutable
class DeleteSurveyQuestionData {
  final DeleteSurveyQuestionSurveyQuestionDelete? surveyQuestion_delete;
  DeleteSurveyQuestionData.fromJson(dynamic json):
  
  surveyQuestion_delete = json['surveyQuestion_delete'] == null ? null : DeleteSurveyQuestionSurveyQuestionDelete.fromJson(json['surveyQuestion_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSurveyQuestionData otherTyped = other as DeleteSurveyQuestionData;
    return surveyQuestion_delete == otherTyped.surveyQuestion_delete;
    
  }
  @override
  int get hashCode => surveyQuestion_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (surveyQuestion_delete != null) {
      json['surveyQuestion_delete'] = surveyQuestion_delete!.toJson();
    }
    return json;
  }

  DeleteSurveyQuestionData({
    this.surveyQuestion_delete,
  });
}

@immutable
class DeleteSurveyQuestionVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSurveyQuestionVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSurveyQuestionVariables otherTyped = other as DeleteSurveyQuestionVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSurveyQuestionVariables({
    required this.id,
  });
}

