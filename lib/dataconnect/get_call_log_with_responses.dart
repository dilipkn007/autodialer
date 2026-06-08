part of 'default.dart';

class GetCallLogWithResponsesVariablesBuilder {
  String callLogId;

  final FirebaseDataConnect _dataConnect;
  GetCallLogWithResponsesVariablesBuilder(this._dataConnect, {required  this.callLogId,});
  Deserializer<GetCallLogWithResponsesData> dataDeserializer = (dynamic json)  => GetCallLogWithResponsesData.fromJson(jsonDecode(json));
  Serializer<GetCallLogWithResponsesVariables> varsSerializer = (GetCallLogWithResponsesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetCallLogWithResponsesData, GetCallLogWithResponsesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetCallLogWithResponsesData, GetCallLogWithResponsesVariables> ref() {
    GetCallLogWithResponsesVariables vars= GetCallLogWithResponsesVariables(callLogId: callLogId,);
    return _dataConnect.query("GetCallLogWithResponses", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetCallLogWithResponsesCallLog {
  final String id;
  final EnumValue<CallOutcome> callOutcome;
  final EnumValue<FollowUpStatus>? followUpStatus;
  final String? followUpNotes;
  final DateTime? nextCallDate;
  final int? callDuration;
  final Timestamp calledAt;
  final GetCallLogWithResponsesCallLogContact contact;
  final List<GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog> surveyResponses_on_callLog;
  GetCallLogWithResponsesCallLog.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  callOutcome = callOutcomeDeserializer(json['callOutcome']),
  followUpStatus = json['followUpStatus'] == null ? null : followUpStatusDeserializer(json['followUpStatus']),
  followUpNotes = json['followUpNotes'] == null ? null : nativeFromJson<String>(json['followUpNotes']),
  nextCallDate = json['nextCallDate'] == null ? null : nativeFromJson<DateTime>(json['nextCallDate']),
  callDuration = json['callDuration'] == null ? null : nativeFromJson<int>(json['callDuration']),
  calledAt = Timestamp.fromJson(json['calledAt']),
  contact = GetCallLogWithResponsesCallLogContact.fromJson(json['contact']),
  surveyResponses_on_callLog = (json['surveyResponses_on_callLog'] as List<dynamic>)
        .map((e) => GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesCallLog otherTyped = other as GetCallLogWithResponsesCallLog;
    return id == otherTyped.id && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus && 
    followUpNotes == otherTyped.followUpNotes && 
    nextCallDate == otherTyped.nextCallDate && 
    callDuration == otherTyped.callDuration && 
    calledAt == otherTyped.calledAt && 
    contact == otherTyped.contact && 
    surveyResponses_on_callLog == otherTyped.surveyResponses_on_callLog;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, callOutcome.hashCode, followUpStatus.hashCode, followUpNotes.hashCode, nextCallDate.hashCode, callDuration.hashCode, calledAt.hashCode, contact.hashCode, surveyResponses_on_callLog.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['callOutcome'] = 
    callOutcomeSerializer(callOutcome)
    ;
    if (followUpStatus != null) {
      json['followUpStatus'] = 
    followUpStatusSerializer(followUpStatus!)
    ;
    }
    if (followUpNotes != null) {
      json['followUpNotes'] = nativeToJson<String?>(followUpNotes);
    }
    if (nextCallDate != null) {
      json['nextCallDate'] = nativeToJson<DateTime?>(nextCallDate);
    }
    if (callDuration != null) {
      json['callDuration'] = nativeToJson<int?>(callDuration);
    }
    json['calledAt'] = calledAt.toJson();
    json['contact'] = contact.toJson();
    json['surveyResponses_on_callLog'] = surveyResponses_on_callLog.map((e) => e.toJson()).toList();
    return json;
  }

  GetCallLogWithResponsesCallLog({
    required this.id,
    required this.callOutcome,
    this.followUpStatus,
    this.followUpNotes,
    this.nextCallDate,
    this.callDuration,
    required this.calledAt,
    required this.contact,
    required this.surveyResponses_on_callLog,
  });
}

@immutable
class GetCallLogWithResponsesCallLogContact {
  final String id;
  final String name;
  final String mobile;
  final String? folkId;
  GetCallLogWithResponsesCallLogContact.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesCallLogContact otherTyped = other as GetCallLogWithResponsesCallLogContact;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    folkId == otherTyped.folkId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, mobile.hashCode, folkId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    return json;
  }

  GetCallLogWithResponsesCallLogContact({
    required this.id,
    required this.name,
    required this.mobile,
    this.folkId,
  });
}

@immutable
class GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog {
  final String id;
  final String answer;
  final GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion question;
  GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  answer = nativeFromJson<String>(json['answer']),
  question = GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion.fromJson(json['question']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog otherTyped = other as GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog;
    return id == otherTyped.id && 
    answer == otherTyped.answer && 
    question == otherTyped.question;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, answer.hashCode, question.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['answer'] = nativeToJson<String>(answer);
    json['question'] = question.toJson();
    return json;
  }

  GetCallLogWithResponsesCallLogSurveyResponsesOnCallLog({
    required this.id,
    required this.answer,
    required this.question,
  });
}

@immutable
class GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion {
  final String id;
  final String questionTitle;
  final EnumValue<QuestionType> questionType;
  final String? options;
  GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  questionTitle = nativeFromJson<String>(json['questionTitle']),
  questionType = questionTypeDeserializer(json['questionType']),
  options = json['options'] == null ? null : nativeFromJson<String>(json['options']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion otherTyped = other as GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion;
    return id == otherTyped.id && 
    questionTitle == otherTyped.questionTitle && 
    questionType == otherTyped.questionType && 
    options == otherTyped.options;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, questionTitle.hashCode, questionType.hashCode, options.hashCode]);
  

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
    return json;
  }

  GetCallLogWithResponsesCallLogSurveyResponsesOnCallLogQuestion({
    required this.id,
    required this.questionTitle,
    required this.questionType,
    this.options,
  });
}

@immutable
class GetCallLogWithResponsesData {
  final GetCallLogWithResponsesCallLog? callLog;
  GetCallLogWithResponsesData.fromJson(dynamic json):
  
  callLog = json['callLog'] == null ? null : GetCallLogWithResponsesCallLog.fromJson(json['callLog']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesData otherTyped = other as GetCallLogWithResponsesData;
    return callLog == otherTyped.callLog;
    
  }
  @override
  int get hashCode => callLog.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (callLog != null) {
      json['callLog'] = callLog!.toJson();
    }
    return json;
  }

  GetCallLogWithResponsesData({
    this.callLog,
  });
}

@immutable
class GetCallLogWithResponsesVariables {
  final String callLogId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetCallLogWithResponsesVariables.fromJson(Map<String, dynamic> json):
  
  callLogId = nativeFromJson<String>(json['callLogId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallLogWithResponsesVariables otherTyped = other as GetCallLogWithResponsesVariables;
    return callLogId == otherTyped.callLogId;
    
  }
  @override
  int get hashCode => callLogId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogId'] = nativeToJson<String>(callLogId);
    return json;
  }

  GetCallLogWithResponsesVariables({
    required this.callLogId,
  });
}

