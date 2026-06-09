part of 'default.dart';

class ListAllCallLogsForExportVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllCallLogsForExportVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllCallLogsForExportData> dataDeserializer = (dynamic json)  => ListAllCallLogsForExportData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllCallLogsForExportData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllCallLogsForExportData, void> ref() {
    
    return _dataConnect.query("ListAllCallLogsForExport", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllCallLogsForExportCallLogs {
  final String id;
  final EnumValue<CallOutcome> callOutcome;
  final EnumValue<FollowUpStatus>? followUpStatus;
  final String? followUpNotes;
  final DateTime? nextCallDate;
  final int? callDuration;
  final Timestamp calledAt;
  final ListAllCallLogsForExportCallLogsContact contact;
  final ListAllCallLogsForExportCallLogsEnabler enabler;
  final ListAllCallLogsForExportCallLogsEvent event;
  final List<ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog> surveyResponses_on_callLog;
  ListAllCallLogsForExportCallLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  callOutcome = callOutcomeDeserializer(json['callOutcome']),
  followUpStatus = json['followUpStatus'] == null ? null : followUpStatusDeserializer(json['followUpStatus']),
  followUpNotes = json['followUpNotes'] == null ? null : nativeFromJson<String>(json['followUpNotes']),
  nextCallDate = json['nextCallDate'] == null ? null : nativeFromJson<DateTime>(json['nextCallDate']),
  callDuration = json['callDuration'] == null ? null : nativeFromJson<int>(json['callDuration']),
  calledAt = Timestamp.fromJson(json['calledAt']),
  contact = ListAllCallLogsForExportCallLogsContact.fromJson(json['contact']),
  enabler = ListAllCallLogsForExportCallLogsEnabler.fromJson(json['enabler']),
  event = ListAllCallLogsForExportCallLogsEvent.fromJson(json['event']),
  surveyResponses_on_callLog = (json['surveyResponses_on_callLog'] as List<dynamic>)
        .map((e) => ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogs otherTyped = other as ListAllCallLogsForExportCallLogs;
    return id == otherTyped.id && 
    callOutcome == otherTyped.callOutcome && 
    followUpStatus == otherTyped.followUpStatus && 
    followUpNotes == otherTyped.followUpNotes && 
    nextCallDate == otherTyped.nextCallDate && 
    callDuration == otherTyped.callDuration && 
    calledAt == otherTyped.calledAt && 
    contact == otherTyped.contact && 
    enabler == otherTyped.enabler && 
    event == otherTyped.event && 
    surveyResponses_on_callLog == otherTyped.surveyResponses_on_callLog;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, callOutcome.hashCode, followUpStatus.hashCode, followUpNotes.hashCode, nextCallDate.hashCode, callDuration.hashCode, calledAt.hashCode, contact.hashCode, enabler.hashCode, event.hashCode, surveyResponses_on_callLog.hashCode]);
  

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
    json['enabler'] = enabler.toJson();
    json['event'] = event.toJson();
    json['surveyResponses_on_callLog'] = surveyResponses_on_callLog.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllCallLogsForExportCallLogs({
    required this.id,
    required this.callOutcome,
    this.followUpStatus,
    this.followUpNotes,
    this.nextCallDate,
    this.callDuration,
    required this.calledAt,
    required this.contact,
    required this.enabler,
    required this.event,
    required this.surveyResponses_on_callLog,
  });
}

@immutable
class ListAllCallLogsForExportCallLogsContact {
  final String name;
  final String mobile;
  final String? folkId;
  final String? folkGuide;
  ListAllCallLogsForExportCallLogsContact.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']),
  folkGuide = json['folkGuide'] == null ? null : nativeFromJson<String>(json['folkGuide']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogsContact otherTyped = other as ListAllCallLogsForExportCallLogsContact;
    return name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    folkId == otherTyped.folkId && 
    folkGuide == otherTyped.folkGuide;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, mobile.hashCode, folkId.hashCode, folkGuide.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    if (folkGuide != null) {
      json['folkGuide'] = nativeToJson<String?>(folkGuide);
    }
    return json;
  }

  ListAllCallLogsForExportCallLogsContact({
    required this.name,
    required this.mobile,
    this.folkId,
    this.folkGuide,
  });
}

@immutable
class ListAllCallLogsForExportCallLogsEnabler {
  final String name;
  final String phone;
  ListAllCallLogsForExportCallLogsEnabler.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  phone = nativeFromJson<String>(json['phone']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogsEnabler otherTyped = other as ListAllCallLogsForExportCallLogsEnabler;
    return name == otherTyped.name && 
    phone == otherTyped.phone;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, phone.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['phone'] = nativeToJson<String>(phone);
    return json;
  }

  ListAllCallLogsForExportCallLogsEnabler({
    required this.name,
    required this.phone,
  });
}

@immutable
class ListAllCallLogsForExportCallLogsEvent {
  final String name;
  ListAllCallLogsForExportCallLogsEvent.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogsEvent otherTyped = other as ListAllCallLogsForExportCallLogsEvent;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListAllCallLogsForExportCallLogsEvent({
    required this.name,
  });
}

@immutable
class ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog {
  final String answer;
  final ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion question;
  ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog.fromJson(dynamic json):
  
  answer = nativeFromJson<String>(json['answer']),
  question = ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion.fromJson(json['question']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog otherTyped = other as ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog;
    return answer == otherTyped.answer && 
    question == otherTyped.question;
    
  }
  @override
  int get hashCode => Object.hashAll([answer.hashCode, question.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['answer'] = nativeToJson<String>(answer);
    json['question'] = question.toJson();
    return json;
  }

  ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLog({
    required this.answer,
    required this.question,
  });
}

@immutable
class ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion {
  final String questionTitle;
  ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion.fromJson(dynamic json):
  
  questionTitle = nativeFromJson<String>(json['questionTitle']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion otherTyped = other as ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion;
    return questionTitle == otherTyped.questionTitle;
    
  }
  @override
  int get hashCode => questionTitle.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['questionTitle'] = nativeToJson<String>(questionTitle);
    return json;
  }

  ListAllCallLogsForExportCallLogsSurveyResponsesOnCallLogQuestion({
    required this.questionTitle,
  });
}

@immutable
class ListAllCallLogsForExportData {
  final List<ListAllCallLogsForExportCallLogs> callLogs;
  ListAllCallLogsForExportData.fromJson(dynamic json):
  
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => ListAllCallLogsForExportCallLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllCallLogsForExportData otherTyped = other as ListAllCallLogsForExportData;
    return callLogs == otherTyped.callLogs;
    
  }
  @override
  int get hashCode => callLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllCallLogsForExportData({
    required this.callLogs,
  });
}

