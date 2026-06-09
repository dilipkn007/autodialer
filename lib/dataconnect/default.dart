library folk_autodialer_dataconnect;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'upsert_user.dart';

part 'set_user_active_status.dart';

part 'insert_contact.dart';

part 'create_event.dart';

part 'add_survey_question.dart';

part 'assign_contact.dart';

part 'update_assignment_status.dart';

part 'delete_assignments_for_event.dart';

part 'record_call_log.dart';

part 'record_survey_response.dart';

part 'delete_user_by_phone.dart';

part 'admin_upsert_user.dart';

part 'delete_event.dart';

part 'get_current_user.dart';

part 'get_user_by_phone.dart';

part 'list_enablers.dart';

part 'list_contacts.dart';

part 'get_contact_details.dart';

part 'list_events.dart';

part 'get_event_with_survey.dart';

part 'list_assignments_for_enabler.dart';

part 'list_all_assignments_for_enabler.dart';

part 'list_assignments_for_event.dart';

part 'list_call_logs.dart';

part 'get_call_log_with_responses.dart';

part 'get_contact_stats.dart';

part 'get_enabler_event_stats.dart';

part 'get_recent_activity.dart';

part 'list_all_contacts_for_export.dart';

part 'list_all_call_logs_for_export.dart';

part 'list_enablers_with_stats.dart';

part 'get_event_call_stats.dart';



  enum AssignmentStatus {
    
      PENDING,
    
      IN_PROGRESS,
    
      COMPLETED,
    
      SKIPPED,
    
  }
  
  String assignmentStatusSerializer(EnumValue<AssignmentStatus> e) {
    return e.stringValue;
  }
  EnumValue<AssignmentStatus> assignmentStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'PENDING':
        return const Known(AssignmentStatus.PENDING);
      
      case 'IN_PROGRESS':
        return const Known(AssignmentStatus.IN_PROGRESS);
      
      case 'COMPLETED':
        return const Known(AssignmentStatus.COMPLETED);
      
      case 'SKIPPED':
        return const Known(AssignmentStatus.SKIPPED);
      
      default:
        return Unknown(data);
    }
  }
  

  enum CallOutcome {
    
      ANSWERED,
    
      BUSY,
    
      NO_RESPONSE,
    
      SWITCHED_OFF,
    
      WRONG_NUMBER,
    
      NOT_REACHABLE,
    
  }
  
  String callOutcomeSerializer(EnumValue<CallOutcome> e) {
    return e.stringValue;
  }
  EnumValue<CallOutcome> callOutcomeDeserializer(dynamic data) {
    switch (data) {
      
      case 'ANSWERED':
        return const Known(CallOutcome.ANSWERED);
      
      case 'BUSY':
        return const Known(CallOutcome.BUSY);
      
      case 'NO_RESPONSE':
        return const Known(CallOutcome.NO_RESPONSE);
      
      case 'SWITCHED_OFF':
        return const Known(CallOutcome.SWITCHED_OFF);
      
      case 'WRONG_NUMBER':
        return const Known(CallOutcome.WRONG_NUMBER);
      
      case 'NOT_REACHABLE':
        return const Known(CallOutcome.NOT_REACHABLE);
      
      default:
        return Unknown(data);
    }
  }
  

  enum EventStatus {
    
      ACTIVE,
    
      COMPLETED,
    
      CANCELLED,
    
  }
  
  String eventStatusSerializer(EnumValue<EventStatus> e) {
    return e.stringValue;
  }
  EnumValue<EventStatus> eventStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'ACTIVE':
        return const Known(EventStatus.ACTIVE);
      
      case 'COMPLETED':
        return const Known(EventStatus.COMPLETED);
      
      case 'CANCELLED':
        return const Known(EventStatus.CANCELLED);
      
      default:
        return Unknown(data);
    }
  }
  

  enum FollowUpStatus {
    
      NEW,
    
      CONTACTED,
    
      INTERESTED,
    
      NOT_INTERESTED,
    
      JOINED,
    
      PENDING,
    
      DORMANT,
    
  }
  
  String followUpStatusSerializer(EnumValue<FollowUpStatus> e) {
    return e.stringValue;
  }
  EnumValue<FollowUpStatus> followUpStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'NEW':
        return const Known(FollowUpStatus.NEW);
      
      case 'CONTACTED':
        return const Known(FollowUpStatus.CONTACTED);
      
      case 'INTERESTED':
        return const Known(FollowUpStatus.INTERESTED);
      
      case 'NOT_INTERESTED':
        return const Known(FollowUpStatus.NOT_INTERESTED);
      
      case 'JOINED':
        return const Known(FollowUpStatus.JOINED);
      
      case 'PENDING':
        return const Known(FollowUpStatus.PENDING);
      
      case 'DORMANT':
        return const Known(FollowUpStatus.DORMANT);
      
      default:
        return Unknown(data);
    }
  }
  

  enum QuestionType {
    
      DROPDOWN,
    
      TEXT,
    
      DATE,
    
      MULTI_SELECT,
    
      RADIO,
    
  }
  
  String questionTypeSerializer(EnumValue<QuestionType> e) {
    return e.stringValue;
  }
  EnumValue<QuestionType> questionTypeDeserializer(dynamic data) {
    switch (data) {
      
      case 'DROPDOWN':
        return const Known(QuestionType.DROPDOWN);
      
      case 'TEXT':
        return const Known(QuestionType.TEXT);
      
      case 'DATE':
        return const Known(QuestionType.DATE);
      
      case 'MULTI_SELECT':
        return const Known(QuestionType.MULTI_SELECT);
      
      case 'RADIO':
        return const Known(QuestionType.RADIO);
      
      default:
        return Unknown(data);
    }
  }
  

  enum UserRole {
    
      ADMIN,
    
      ENABLER,
    
  }
  
  String userRoleSerializer(EnumValue<UserRole> e) {
    return e.stringValue;
  }
  EnumValue<UserRole> userRoleDeserializer(dynamic data) {
    switch (data) {
      
      case 'ADMIN':
        return const Known(UserRole.ADMIN);
      
      case 'ENABLER':
        return const Known(UserRole.ENABLER);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class DefaultConnector {
  
  
  UpsertUserVariablesBuilder upsertUser ({required String uid, required String phone, required String name, }) {
    return UpsertUserVariablesBuilder(dataConnect, uid: uid,phone: phone,name: name,);
  }
  
  
  SetUserActiveStatusVariablesBuilder setUserActiveStatus ({required String uid, required bool isActive, }) {
    return SetUserActiveStatusVariablesBuilder(dataConnect, uid: uid,isActive: isActive,);
  }
  
  
  InsertContactVariablesBuilder insertContact ({required String name, required String mobile, }) {
    return InsertContactVariablesBuilder(dataConnect, name: name,mobile: mobile,);
  }
  
  
  CreateEventVariablesBuilder createEvent ({required String name, required DateTime eventDate, required EventStatus status, required String createdByUid, }) {
    return CreateEventVariablesBuilder(dataConnect, name: name,eventDate: eventDate,status: status,createdByUid: createdByUid,);
  }
  
  
  AddSurveyQuestionVariablesBuilder addSurveyQuestion ({required String eventId, required String questionTitle, required QuestionType questionType, required int sortOrder, required bool isRequired, }) {
    return AddSurveyQuestionVariablesBuilder(dataConnect, eventId: eventId,questionTitle: questionTitle,questionType: questionType,sortOrder: sortOrder,isRequired: isRequired,);
  }
  
  
  AssignContactVariablesBuilder assignContact ({required String contactId, required String enablerUid, required String eventId, required int sortOrder, required String assignedByUid, }) {
    return AssignContactVariablesBuilder(dataConnect, contactId: contactId,enablerUid: enablerUid,eventId: eventId,sortOrder: sortOrder,assignedByUid: assignedByUid,);
  }
  
  
  UpdateAssignmentStatusVariablesBuilder updateAssignmentStatus ({required String id, required AssignmentStatus status, }) {
    return UpdateAssignmentStatusVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  DeleteAssignmentsForEventVariablesBuilder deleteAssignmentsForEvent ({required String eventId, }) {
    return DeleteAssignmentsForEventVariablesBuilder(dataConnect, eventId: eventId,);
  }
  
  
  RecordCallLogVariablesBuilder recordCallLog ({required String assignmentId, required String contactId, required String enablerUid, required String eventId, required CallOutcome callOutcome, }) {
    return RecordCallLogVariablesBuilder(dataConnect, assignmentId: assignmentId,contactId: contactId,enablerUid: enablerUid,eventId: eventId,callOutcome: callOutcome,);
  }
  
  
  RecordSurveyResponseVariablesBuilder recordSurveyResponse ({required String callLogId, required String questionId, required String answer, }) {
    return RecordSurveyResponseVariablesBuilder(dataConnect, callLogId: callLogId,questionId: questionId,answer: answer,);
  }
  
  
  DeleteUserByPhoneVariablesBuilder deleteUserByPhone ({required String uid, required String phone, }) {
    return DeleteUserByPhoneVariablesBuilder(dataConnect, uid: uid,phone: phone,);
  }
  
  
  AdminUpsertUserVariablesBuilder adminUpsertUser ({required String uid, required String phone, required String name, required UserRole role, required bool isActive, }) {
    return AdminUpsertUserVariablesBuilder(dataConnect, uid: uid,phone: phone,name: name,role: role,isActive: isActive,);
  }
  
  
  DeleteEventVariablesBuilder deleteEvent ({required String id, }) {
    return DeleteEventVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  GetUserByPhoneVariablesBuilder getUserByPhone ({required String phone, }) {
    return GetUserByPhoneVariablesBuilder(dataConnect, phone: phone,);
  }
  
  
  ListEnablersVariablesBuilder listEnablers () {
    return ListEnablersVariablesBuilder(dataConnect, );
  }
  
  
  ListContactsVariablesBuilder listContacts ({required int limit, required int offset, }) {
    return ListContactsVariablesBuilder(dataConnect, limit: limit,offset: offset,);
  }
  
  
  GetContactDetailsVariablesBuilder getContactDetails ({required String id, }) {
    return GetContactDetailsVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListEventsVariablesBuilder listEvents () {
    return ListEventsVariablesBuilder(dataConnect, );
  }
  
  
  GetEventWithSurveyVariablesBuilder getEventWithSurvey ({required String eventId, }) {
    return GetEventWithSurveyVariablesBuilder(dataConnect, eventId: eventId,);
  }
  
  
  ListAssignmentsForEnablerVariablesBuilder listAssignmentsForEnabler ({required String enablerUid, required String eventId, }) {
    return ListAssignmentsForEnablerVariablesBuilder(dataConnect, enablerUid: enablerUid,eventId: eventId,);
  }
  
  
  ListAllAssignmentsForEnablerVariablesBuilder listAllAssignmentsForEnabler ({required String enablerUid, }) {
    return ListAllAssignmentsForEnablerVariablesBuilder(dataConnect, enablerUid: enablerUid,);
  }
  
  
  ListAssignmentsForEventVariablesBuilder listAssignmentsForEvent ({required String eventId, }) {
    return ListAssignmentsForEventVariablesBuilder(dataConnect, eventId: eventId,);
  }
  
  
  ListCallLogsVariablesBuilder listCallLogs ({required String enablerUid, required String eventId, }) {
    return ListCallLogsVariablesBuilder(dataConnect, enablerUid: enablerUid,eventId: eventId,);
  }
  
  
  GetCallLogWithResponsesVariablesBuilder getCallLogWithResponses ({required String callLogId, }) {
    return GetCallLogWithResponsesVariablesBuilder(dataConnect, callLogId: callLogId,);
  }
  
  
  GetContactStatsVariablesBuilder getContactStats () {
    return GetContactStatsVariablesBuilder(dataConnect, );
  }
  
  
  GetEnablerEventStatsVariablesBuilder getEnablerEventStats ({required String enablerUid, required String eventId, }) {
    return GetEnablerEventStatsVariablesBuilder(dataConnect, enablerUid: enablerUid,eventId: eventId,);
  }
  
  
  GetRecentActivityVariablesBuilder getRecentActivity ({required int limit, }) {
    return GetRecentActivityVariablesBuilder(dataConnect, limit: limit,);
  }
  
  
  ListAllContactsForExportVariablesBuilder listAllContactsForExport () {
    return ListAllContactsForExportVariablesBuilder(dataConnect, );
  }
  
  
  ListAllCallLogsForExportVariablesBuilder listAllCallLogsForExport () {
    return ListAllCallLogsForExportVariablesBuilder(dataConnect, );
  }
  
  
  ListEnablersWithStatsVariablesBuilder listEnablersWithStats () {
    return ListEnablersWithStatsVariablesBuilder(dataConnect, );
  }
  
  
  GetEventCallStatsVariablesBuilder getEventCallStats ({required String eventId, }) {
    return GetEventCallStatsVariablesBuilder(dataConnect, eventId: eventId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-south1',
    'default',
    'folk-autodialer',
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
