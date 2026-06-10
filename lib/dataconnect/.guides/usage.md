# Basic Usage

```dart
DefaultConnector.instance.UpsertUser(upsertUserVariables).execute();
DefaultConnector.instance.UpdateUserProfile(updateUserProfileVariables).execute();
DefaultConnector.instance.SetUserActiveStatus(setUserActiveStatusVariables).execute();
DefaultConnector.instance.InsertContact(insertContactVariables).execute();
DefaultConnector.instance.CreateEvent(createEventVariables).execute();
DefaultConnector.instance.AddSurveyQuestion(addSurveyQuestionVariables).execute();
DefaultConnector.instance.AssignContact(assignContactVariables).execute();
DefaultConnector.instance.ReassignContact(reassignContactVariables).execute();
DefaultConnector.instance.UnassignContact(unassignContactVariables).execute();
DefaultConnector.instance.UpdateAssignmentStatus(updateAssignmentStatusVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await DefaultConnector.instance.ListEvents({ ... })
.status(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

