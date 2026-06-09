part of 'default.dart';

class UnassignContactVariablesBuilder {
  String contactId;
  String eventId;

  final FirebaseDataConnect _dataConnect;
  UnassignContactVariablesBuilder(this._dataConnect, {required  this.contactId,required  this.eventId,});
  Deserializer<UnassignContactData> dataDeserializer = (dynamic json)  => UnassignContactData.fromJson(jsonDecode(json));
  Serializer<UnassignContactVariables> varsSerializer = (UnassignContactVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UnassignContactData, UnassignContactVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UnassignContactData, UnassignContactVariables> ref() {
    UnassignContactVariables vars= UnassignContactVariables(contactId: contactId,eventId: eventId,);
    return _dataConnect.mutation("UnassignContact", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UnassignContactData {
  final int assignment_deleteMany;
  UnassignContactData.fromJson(dynamic json):
  
  assignment_deleteMany = nativeFromJson<int>(json['assignment_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnassignContactData otherTyped = other as UnassignContactData;
    return assignment_deleteMany == otherTyped.assignment_deleteMany;
    
  }
  @override
  int get hashCode => assignment_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['assignment_deleteMany'] = nativeToJson<int>(assignment_deleteMany);
    return json;
  }

  UnassignContactData({
    required this.assignment_deleteMany,
  });
}

@immutable
class UnassignContactVariables {
  final String contactId;
  final String eventId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UnassignContactVariables.fromJson(Map<String, dynamic> json):
  
  contactId = nativeFromJson<String>(json['contactId']),
  eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UnassignContactVariables otherTyped = other as UnassignContactVariables;
    return contactId == otherTyped.contactId && 
    eventId == otherTyped.eventId;
    
  }
  @override
  int get hashCode => Object.hashAll([contactId.hashCode, eventId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['contactId'] = nativeToJson<String>(contactId);
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  UnassignContactVariables({
    required this.contactId,
    required this.eventId,
  });
}

