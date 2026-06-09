part of 'default.dart';

class GetCallOutcomeDistributionVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCallOutcomeDistributionVariablesBuilder(this._dataConnect, );
  Deserializer<GetCallOutcomeDistributionData> dataDeserializer = (dynamic json)  => GetCallOutcomeDistributionData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCallOutcomeDistributionData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetCallOutcomeDistributionData, void> ref() {
    
    return _dataConnect.query("GetCallOutcomeDistribution", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCallOutcomeDistributionCallLogs {
  final EnumValue<CallOutcome> callOutcome;
  GetCallOutcomeDistributionCallLogs.fromJson(dynamic json):
  
  callOutcome = callOutcomeDeserializer(json['callOutcome']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallOutcomeDistributionCallLogs otherTyped = other as GetCallOutcomeDistributionCallLogs;
    return callOutcome == otherTyped.callOutcome;
    
  }
  @override
  int get hashCode => callOutcome.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callOutcome'] = 
    callOutcomeSerializer(callOutcome)
    ;
    return json;
  }

  GetCallOutcomeDistributionCallLogs({
    required this.callOutcome,
  });
}

@immutable
class GetCallOutcomeDistributionData {
  final List<GetCallOutcomeDistributionCallLogs> callLogs;
  GetCallOutcomeDistributionData.fromJson(dynamic json):
  
  callLogs = (json['callLogs'] as List<dynamic>)
        .map((e) => GetCallOutcomeDistributionCallLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCallOutcomeDistributionData otherTyped = other as GetCallOutcomeDistributionData;
    return callLogs == otherTyped.callLogs;
    
  }
  @override
  int get hashCode => callLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['callLogs'] = callLogs.map((e) => e.toJson()).toList();
    return json;
  }

  GetCallOutcomeDistributionData({
    required this.callLogs,
  });
}

