# folk_autodialer_dataconnect SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
DefaultConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetCurrentUser
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.getCurrentUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCurrentUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getCurrentUser();
GetCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.getCurrentUser().ref();
ref.execute();

ref.subscribe(...);
```


### GetUserByPhone
#### Required Arguments
```dart
String phone = ...;
DefaultConnector.instance.getUserByPhone(
  phone: phone,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserByPhoneData, GetUserByPhoneVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getUserByPhone(
  phone: phone,
);
GetUserByPhoneData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String phone = ...;

final ref = DefaultConnector.instance.getUserByPhone(
  phone: phone,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListEnablers
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listEnablers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListEnablersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listEnablers();
ListEnablersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listEnablers().ref();
ref.execute();

ref.subscribe(...);
```


### ListContacts
#### Required Arguments
```dart
int limit = ...;
int offset = ...;
DefaultConnector.instance.listContacts(
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListContacts, we created `ListContactsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListContactsVariablesBuilder {
  ...
 
  ListContactsVariablesBuilder search(String? t) {
   _search.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.listContacts(
  limit: limit,
  offset: offset,
)
.search(search)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListContactsData, ListContactsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listContacts(
  limit: limit,
  offset: offset,
);
ListContactsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int limit = ...;
int offset = ...;

final ref = DefaultConnector.instance.listContacts(
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetContactDetails
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.getContactDetails(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetContactDetailsData, GetContactDetailsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getContactDetails(
  id: id,
);
GetContactDetailsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.getContactDetails(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListEvents
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listEvents().execute();
```

#### Optional Arguments
We return a builder for each query. For ListEvents, we created `ListEventsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListEventsVariablesBuilder {
  ...
 
  ListEventsVariablesBuilder status(EventStatus? t) {
   _status.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.listEvents()
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListEventsData, ListEventsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listEvents();
ListEventsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listEvents().ref();
ref.execute();

ref.subscribe(...);
```


### GetEventWithSurvey
#### Required Arguments
```dart
String eventId = ...;
DefaultConnector.instance.getEventWithSurvey(
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetEventWithSurveyData, GetEventWithSurveyVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getEventWithSurvey(
  eventId: eventId,
);
GetEventWithSurveyData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;

final ref = DefaultConnector.instance.getEventWithSurvey(
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListAssignmentsForEnabler
#### Required Arguments
```dart
String enablerUid = ...;
String eventId = ...;
DefaultConnector.instance.listAssignmentsForEnabler(
  enablerUid: enablerUid,
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAssignmentsForEnablerData, ListAssignmentsForEnablerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listAssignmentsForEnabler(
  enablerUid: enablerUid,
  eventId: eventId,
);
ListAssignmentsForEnablerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String enablerUid = ...;
String eventId = ...;

final ref = DefaultConnector.instance.listAssignmentsForEnabler(
  enablerUid: enablerUid,
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListAllAssignmentsForEnabler
#### Required Arguments
```dart
String enablerUid = ...;
DefaultConnector.instance.listAllAssignmentsForEnabler(
  enablerUid: enablerUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllAssignmentsForEnablerData, ListAllAssignmentsForEnablerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listAllAssignmentsForEnabler(
  enablerUid: enablerUid,
);
ListAllAssignmentsForEnablerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String enablerUid = ...;

final ref = DefaultConnector.instance.listAllAssignmentsForEnabler(
  enablerUid: enablerUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListAssignmentsForEvent
#### Required Arguments
```dart
String eventId = ...;
DefaultConnector.instance.listAssignmentsForEvent(
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAssignmentsForEventData, ListAssignmentsForEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listAssignmentsForEvent(
  eventId: eventId,
);
ListAssignmentsForEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;

final ref = DefaultConnector.instance.listAssignmentsForEvent(
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListCallLogs
#### Required Arguments
```dart
String enablerUid = ...;
String eventId = ...;
DefaultConnector.instance.listCallLogs(
  enablerUid: enablerUid,
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListCallLogsData, ListCallLogsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listCallLogs(
  enablerUid: enablerUid,
  eventId: eventId,
);
ListCallLogsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String enablerUid = ...;
String eventId = ...;

final ref = DefaultConnector.instance.listCallLogs(
  enablerUid: enablerUid,
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetCallLogWithResponses
#### Required Arguments
```dart
String callLogId = ...;
DefaultConnector.instance.getCallLogWithResponses(
  callLogId: callLogId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCallLogWithResponsesData, GetCallLogWithResponsesVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getCallLogWithResponses(
  callLogId: callLogId,
);
GetCallLogWithResponsesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String callLogId = ...;

final ref = DefaultConnector.instance.getCallLogWithResponses(
  callLogId: callLogId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetContactStats
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.getContactStats().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetContactStatsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getContactStats();
GetContactStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.getContactStats().ref();
ref.execute();

ref.subscribe(...);
```


### GetEnablerEventStats
#### Required Arguments
```dart
String enablerUid = ...;
String eventId = ...;
DefaultConnector.instance.getEnablerEventStats(
  enablerUid: enablerUid,
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetEnablerEventStatsData, GetEnablerEventStatsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getEnablerEventStats(
  enablerUid: enablerUid,
  eventId: eventId,
);
GetEnablerEventStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String enablerUid = ...;
String eventId = ...;

final ref = DefaultConnector.instance.getEnablerEventStats(
  enablerUid: enablerUid,
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetRecentActivity
#### Required Arguments
```dart
int limit = ...;
DefaultConnector.instance.getRecentActivity(
  limit: limit,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetRecentActivityData, GetRecentActivityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getRecentActivity(
  limit: limit,
);
GetRecentActivityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int limit = ...;

final ref = DefaultConnector.instance.getRecentActivity(
  limit: limit,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListAllContactsForExport
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listAllContactsForExport().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllContactsForExportData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listAllContactsForExport();
ListAllContactsForExportData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listAllContactsForExport().ref();
ref.execute();

ref.subscribe(...);
```


### ListAllCallLogsForExport
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listAllCallLogsForExport().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllCallLogsForExportData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listAllCallLogsForExport();
ListAllCallLogsForExportData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listAllCallLogsForExport().ref();
ref.execute();

ref.subscribe(...);
```


### ListEnablersWithStats
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listEnablersWithStats().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListEnablersWithStatsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.listEnablersWithStats();
ListEnablersWithStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listEnablersWithStats().ref();
ref.execute();

ref.subscribe(...);
```


### GetEventCallStats
#### Required Arguments
```dart
String eventId = ...;
DefaultConnector.instance.getEventCallStats(
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetEventCallStatsData, GetEventCallStatsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await DefaultConnector.instance.getEventCallStats(
  eventId: eventId,
);
GetEventCallStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;

final ref = DefaultConnector.instance.getEventCallStats(
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### UpsertUser
#### Required Arguments
```dart
String uid = ...;
String phone = ...;
String name = ...;
DefaultConnector.instance.upsertUser(
  uid: uid,
  phone: phone,
  name: name,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertUser, we created `UpsertUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertUserVariablesBuilder {
  ...
   UpsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  UpsertUserVariablesBuilder avatarInitials(String? t) {
   _avatarInitials.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertUser(
  uid: uid,
  phone: phone,
  name: name,
)
.email(email)
.avatarInitials(avatarInitials)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertUserData, UpsertUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertUser(
  uid: uid,
  phone: phone,
  name: name,
);
UpsertUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;
String phone = ...;
String name = ...;

final ref = DefaultConnector.instance.upsertUser(
  uid: uid,
  phone: phone,
  name: name,
).ref();
ref.execute();
```


### SetUserActiveStatus
#### Required Arguments
```dart
String uid = ...;
bool isActive = ...;
DefaultConnector.instance.setUserActiveStatus(
  uid: uid,
  isActive: isActive,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<SetUserActiveStatusData, SetUserActiveStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.setUserActiveStatus(
  uid: uid,
  isActive: isActive,
);
SetUserActiveStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;
bool isActive = ...;

final ref = DefaultConnector.instance.setUserActiveStatus(
  uid: uid,
  isActive: isActive,
).ref();
ref.execute();
```


### InsertContact
#### Required Arguments
```dart
String name = ...;
String mobile = ...;
DefaultConnector.instance.insertContact(
  name: name,
  mobile: mobile,
).execute();
```

#### Optional Arguments
We return a builder for each query. For InsertContact, we created `InsertContactBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class InsertContactVariablesBuilder {
  ...
 
  InsertContactVariablesBuilder syncStatus(String? t) {
   _syncStatus.value = t;
   return this;
  }
  InsertContactVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  InsertContactVariablesBuilder whatsapp(String? t) {
   _whatsapp.value = t;
   return this;
  }
  InsertContactVariablesBuilder dateOfBirth(String? t) {
   _dateOfBirth.value = t;
   return this;
  }
  InsertContactVariablesBuilder age(int? t) {
   _age.value = t;
   return this;
  }
  InsertContactVariablesBuilder folkAge(String? t) {
   _folkAge.value = t;
   return this;
  }
  InsertContactVariablesBuilder gender(String? t) {
   _gender.value = t;
   return this;
  }
  InsertContactVariablesBuilder folkId(String? t) {
   _folkId.value = t;
   return this;
  }
  InsertContactVariablesBuilder folkGuide(String? t) {
   _folkGuide.value = t;
   return this;
  }
  InsertContactVariablesBuilder folkLevel(String? t) {
   _folkLevel.value = t;
   return this;
  }
  InsertContactVariablesBuilder occupation(String? t) {
   _occupation.value = t;
   return this;
  }
  InsertContactVariablesBuilder maritalStatus(String? t) {
   _maritalStatus.value = t;
   return this;
  }
  InsertContactVariablesBuilder language(String? t) {
   _language.value = t;
   return this;
  }
  InsertContactVariablesBuilder livingStatus(String? t) {
   _livingStatus.value = t;
   return this;
  }
  InsertContactVariablesBuilder address(String? t) {
   _address.value = t;
   return this;
  }
  InsertContactVariablesBuilder permanentAddress(String? t) {
   _permanentAddress.value = t;
   return this;
  }
  InsertContactVariablesBuilder city(String? t) {
   _city.value = t;
   return this;
  }
  InsertContactVariablesBuilder state(String? t) {
   _state.value = t;
   return this;
  }
  InsertContactVariablesBuilder country(String? t) {
   _country.value = t;
   return this;
  }
  InsertContactVariablesBuilder higherQualification(String? t) {
   _higherQualification.value = t;
   return this;
  }
  InsertContactVariablesBuilder academicInstitution(String? t) {
   _academicInstitution.value = t;
   return this;
  }
  InsertContactVariablesBuilder institutionLocation(String? t) {
   _institutionLocation.value = t;
   return this;
  }
  InsertContactVariablesBuilder organization(String? t) {
   _organization.value = t;
   return this;
  }
  InsertContactVariablesBuilder designation(String? t) {
   _designation.value = t;
   return this;
  }
  InsertContactVariablesBuilder organizationLocation(String? t) {
   _organizationLocation.value = t;
   return this;
  }
  InsertContactVariablesBuilder residencyInterest(String? t) {
   _residencyInterest.value = t;
   return this;
  }
  InsertContactVariablesBuilder origin(String? t) {
   _origin.value = t;
   return this;
  }
  InsertContactVariablesBuilder journey(String? t) {
   _journey.value = t;
   return this;
  }
  InsertContactVariablesBuilder currentStatus(String? t) {
   _currentStatus.value = t;
   return this;
  }
  InsertContactVariablesBuilder lastActivityType(String? t) {
   _lastActivityType.value = t;
   return this;
  }
  InsertContactVariablesBuilder lastActivity(String? t) {
   _lastActivity.value = t;
   return this;
  }
  InsertContactVariablesBuilder lastSeen(String? t) {
   _lastSeen.value = t;
   return this;
  }
  InsertContactVariablesBuilder yfhId(String? t) {
   _yfhId.value = t;
   return this;
  }
  InsertContactVariablesBuilder yfhCity(String? t) {
   _yfhCity.value = t;
   return this;
  }
  InsertContactVariablesBuilder center(String? t) {
   _center.value = t;
   return this;
  }
  InsertContactVariablesBuilder stay(String? t) {
   _stay.value = t;
   return this;
  }
  InsertContactVariablesBuilder stream(String? t) {
   _stream.value = t;
   return this;
  }
  InsertContactVariablesBuilder highestQualification(String? t) {
   _highestQualification.value = t;
   return this;
  }
  InsertContactVariablesBuilder source(String? t) {
   _source.value = t;
   return this;
  }
  InsertContactVariablesBuilder talents(String? t) {
   _talents.value = t;
   return this;
  }
  InsertContactVariablesBuilder folkResidencyInterest(String? t) {
   _folkResidencyInterest.value = t;
   return this;
  }
  InsertContactVariablesBuilder contactAddress(String? t) {
   _contactAddress.value = t;
   return this;
  }
  InsertContactVariablesBuilder tShirtSize(String? t) {
   _tShirtSize.value = t;
   return this;
  }
  InsertContactVariablesBuilder sent(String? t) {
   _sent.value = t;
   return this;
  }
  InsertContactVariablesBuilder isEnabler(String? t) {
   _isEnabler.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.insertContact(
  name: name,
  mobile: mobile,
)
.syncStatus(syncStatus)
.email(email)
.whatsapp(whatsapp)
.dateOfBirth(dateOfBirth)
.age(age)
.folkAge(folkAge)
.gender(gender)
.folkId(folkId)
.folkGuide(folkGuide)
.folkLevel(folkLevel)
.occupation(occupation)
.maritalStatus(maritalStatus)
.language(language)
.livingStatus(livingStatus)
.address(address)
.permanentAddress(permanentAddress)
.city(city)
.state(state)
.country(country)
.higherQualification(higherQualification)
.academicInstitution(academicInstitution)
.institutionLocation(institutionLocation)
.organization(organization)
.designation(designation)
.organizationLocation(organizationLocation)
.residencyInterest(residencyInterest)
.origin(origin)
.journey(journey)
.currentStatus(currentStatus)
.lastActivityType(lastActivityType)
.lastActivity(lastActivity)
.lastSeen(lastSeen)
.yfhId(yfhId)
.yfhCity(yfhCity)
.center(center)
.stay(stay)
.stream(stream)
.highestQualification(highestQualification)
.source(source)
.talents(talents)
.folkResidencyInterest(folkResidencyInterest)
.contactAddress(contactAddress)
.tShirtSize(tShirtSize)
.sent(sent)
.isEnabler(isEnabler)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<InsertContactData, InsertContactVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.insertContact(
  name: name,
  mobile: mobile,
);
InsertContactData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
String mobile = ...;

final ref = DefaultConnector.instance.insertContact(
  name: name,
  mobile: mobile,
).ref();
ref.execute();
```


### CreateEvent
#### Required Arguments
```dart
String name = ...;
DateTime eventDate = ...;
EventStatus status = ...;
String createdByUid = ...;
DefaultConnector.instance.createEvent(
  name: name,
  eventDate: eventDate,
  status: status,
  createdByUid: createdByUid,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateEvent, we created `CreateEventBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateEventVariablesBuilder {
  ...
   CreateEventVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  CreateEventVariablesBuilder eventTime(String? t) {
   _eventTime.value = t;
   return this;
  }
  CreateEventVariablesBuilder audienceFilter(String? t) {
   _audienceFilter.value = t;
   return this;
  }
  CreateEventVariablesBuilder gapDuration(int? t) {
   _gapDuration.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.createEvent(
  name: name,
  eventDate: eventDate,
  status: status,
  createdByUid: createdByUid,
)
.description(description)
.eventTime(eventTime)
.audienceFilter(audienceFilter)
.gapDuration(gapDuration)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateEventData, CreateEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createEvent(
  name: name,
  eventDate: eventDate,
  status: status,
  createdByUid: createdByUid,
);
CreateEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
DateTime eventDate = ...;
EventStatus status = ...;
String createdByUid = ...;

final ref = DefaultConnector.instance.createEvent(
  name: name,
  eventDate: eventDate,
  status: status,
  createdByUid: createdByUid,
).ref();
ref.execute();
```


### AddSurveyQuestion
#### Required Arguments
```dart
String eventId = ...;
String questionTitle = ...;
QuestionType questionType = ...;
int sortOrder = ...;
bool isRequired = ...;
DefaultConnector.instance.addSurveyQuestion(
  eventId: eventId,
  questionTitle: questionTitle,
  questionType: questionType,
  sortOrder: sortOrder,
  isRequired: isRequired,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AddSurveyQuestion, we created `AddSurveyQuestionBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AddSurveyQuestionVariablesBuilder {
  ...
   AddSurveyQuestionVariablesBuilder options(String? t) {
   _options.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.addSurveyQuestion(
  eventId: eventId,
  questionTitle: questionTitle,
  questionType: questionType,
  sortOrder: sortOrder,
  isRequired: isRequired,
)
.options(options)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AddSurveyQuestionData, AddSurveyQuestionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.addSurveyQuestion(
  eventId: eventId,
  questionTitle: questionTitle,
  questionType: questionType,
  sortOrder: sortOrder,
  isRequired: isRequired,
);
AddSurveyQuestionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;
String questionTitle = ...;
QuestionType questionType = ...;
int sortOrder = ...;
bool isRequired = ...;

final ref = DefaultConnector.instance.addSurveyQuestion(
  eventId: eventId,
  questionTitle: questionTitle,
  questionType: questionType,
  sortOrder: sortOrder,
  isRequired: isRequired,
).ref();
ref.execute();
```


### AssignContact
#### Required Arguments
```dart
String contactId = ...;
String enablerUid = ...;
String eventId = ...;
int sortOrder = ...;
String assignedByUid = ...;
DefaultConnector.instance.assignContact(
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  sortOrder: sortOrder,
  assignedByUid: assignedByUid,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AssignContactData, AssignContactVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.assignContact(
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  sortOrder: sortOrder,
  assignedByUid: assignedByUid,
);
AssignContactData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String contactId = ...;
String enablerUid = ...;
String eventId = ...;
int sortOrder = ...;
String assignedByUid = ...;

final ref = DefaultConnector.instance.assignContact(
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  sortOrder: sortOrder,
  assignedByUid: assignedByUid,
).ref();
ref.execute();
```


### UpdateAssignmentStatus
#### Required Arguments
```dart
String id = ...;
AssignmentStatus status = ...;
DefaultConnector.instance.updateAssignmentStatus(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateAssignmentStatusData, UpdateAssignmentStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateAssignmentStatus(
  id: id,
  status: status,
);
UpdateAssignmentStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
AssignmentStatus status = ...;

final ref = DefaultConnector.instance.updateAssignmentStatus(
  id: id,
  status: status,
).ref();
ref.execute();
```


### DeleteAssignmentsForEvent
#### Required Arguments
```dart
String eventId = ...;
DefaultConnector.instance.deleteAssignmentsForEvent(
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAssignmentsForEventData, DeleteAssignmentsForEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteAssignmentsForEvent(
  eventId: eventId,
);
DeleteAssignmentsForEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;

final ref = DefaultConnector.instance.deleteAssignmentsForEvent(
  eventId: eventId,
).ref();
ref.execute();
```


### RecordCallLog
#### Required Arguments
```dart
String assignmentId = ...;
String contactId = ...;
String enablerUid = ...;
String eventId = ...;
CallOutcome callOutcome = ...;
DefaultConnector.instance.recordCallLog(
  assignmentId: assignmentId,
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  callOutcome: callOutcome,
).execute();
```

#### Optional Arguments
We return a builder for each query. For RecordCallLog, we created `RecordCallLogBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class RecordCallLogVariablesBuilder {
  ...
   RecordCallLogVariablesBuilder followUpStatus(FollowUpStatus? t) {
   _followUpStatus.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder followUpNotes(String? t) {
   _followUpNotes.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder nextCallDate(DateTime? t) {
   _nextCallDate.value = t;
   return this;
  }
  RecordCallLogVariablesBuilder callDuration(int? t) {
   _callDuration.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.recordCallLog(
  assignmentId: assignmentId,
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  callOutcome: callOutcome,
)
.followUpStatus(followUpStatus)
.followUpNotes(followUpNotes)
.nextCallDate(nextCallDate)
.callDuration(callDuration)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<RecordCallLogData, RecordCallLogVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.recordCallLog(
  assignmentId: assignmentId,
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  callOutcome: callOutcome,
);
RecordCallLogData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String assignmentId = ...;
String contactId = ...;
String enablerUid = ...;
String eventId = ...;
CallOutcome callOutcome = ...;

final ref = DefaultConnector.instance.recordCallLog(
  assignmentId: assignmentId,
  contactId: contactId,
  enablerUid: enablerUid,
  eventId: eventId,
  callOutcome: callOutcome,
).ref();
ref.execute();
```


### RecordSurveyResponse
#### Required Arguments
```dart
String callLogId = ...;
String questionId = ...;
String answer = ...;
DefaultConnector.instance.recordSurveyResponse(
  callLogId: callLogId,
  questionId: questionId,
  answer: answer,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RecordSurveyResponseData, RecordSurveyResponseVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.recordSurveyResponse(
  callLogId: callLogId,
  questionId: questionId,
  answer: answer,
);
RecordSurveyResponseData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String callLogId = ...;
String questionId = ...;
String answer = ...;

final ref = DefaultConnector.instance.recordSurveyResponse(
  callLogId: callLogId,
  questionId: questionId,
  answer: answer,
).ref();
ref.execute();
```


### DeleteUserByPhone
#### Required Arguments
```dart
String uid = ...;
String phone = ...;
DefaultConnector.instance.deleteUserByPhone(
  uid: uid,
  phone: phone,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteUserByPhoneData, DeleteUserByPhoneVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteUserByPhone(
  uid: uid,
  phone: phone,
);
DeleteUserByPhoneData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;
String phone = ...;

final ref = DefaultConnector.instance.deleteUserByPhone(
  uid: uid,
  phone: phone,
).ref();
ref.execute();
```


### AdminUpsertUser
#### Required Arguments
```dart
String uid = ...;
String phone = ...;
String name = ...;
UserRole role = ...;
bool isActive = ...;
DefaultConnector.instance.adminUpsertUser(
  uid: uid,
  phone: phone,
  name: name,
  role: role,
  isActive: isActive,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AdminUpsertUser, we created `AdminUpsertUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AdminUpsertUserVariablesBuilder {
  ...
   AdminUpsertUserVariablesBuilder email(String? t) {
   _email.value = t;
   return this;
  }
  AdminUpsertUserVariablesBuilder avatarInitials(String? t) {
   _avatarInitials.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.adminUpsertUser(
  uid: uid,
  phone: phone,
  name: name,
  role: role,
  isActive: isActive,
)
.email(email)
.avatarInitials(avatarInitials)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AdminUpsertUserData, AdminUpsertUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.adminUpsertUser(
  uid: uid,
  phone: phone,
  name: name,
  role: role,
  isActive: isActive,
);
AdminUpsertUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;
String phone = ...;
String name = ...;
UserRole role = ...;
bool isActive = ...;

final ref = DefaultConnector.instance.adminUpsertUser(
  uid: uid,
  phone: phone,
  name: name,
  role: role,
  isActive: isActive,
).ref();
ref.execute();
```


### DeleteEvent
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.deleteEvent(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteEventData, DeleteEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteEvent(
  id: id,
);
DeleteEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.deleteEvent(
  id: id,
).ref();
ref.execute();
```

