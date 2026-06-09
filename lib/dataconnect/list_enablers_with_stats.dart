part of 'default.dart';

class ListEnablersWithStatsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListEnablersWithStatsVariablesBuilder(this._dataConnect, );
  Deserializer<ListEnablersWithStatsData> dataDeserializer = (dynamic json)  => ListEnablersWithStatsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListEnablersWithStatsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListEnablersWithStatsData, void> ref() {
    
    return _dataConnect.query("ListEnablersWithStats", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListEnablersWithStatsUsers {
  final String uid;
  final String phone;
  final String name;
  final String? email;
  final String? avatarInitials;
  final bool isActive;
  final Timestamp createdAt;
  final List<ListEnablersWithStatsUsersAssignmentsOnEnabler> assignments_on_enabler;
  ListEnablersWithStatsUsers.fromJson(dynamic json):
  
  uid = nativeFromJson<String>(json['uid']),
  phone = nativeFromJson<String>(json['phone']),
  name = nativeFromJson<String>(json['name']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  avatarInitials = json['avatarInitials'] == null ? null : nativeFromJson<String>(json['avatarInitials']),
  isActive = nativeFromJson<bool>(json['isActive']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  assignments_on_enabler = (json['assignments_on_enabler'] as List<dynamic>)
        .map((e) => ListEnablersWithStatsUsersAssignmentsOnEnabler.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnablersWithStatsUsers otherTyped = other as ListEnablersWithStatsUsers;
    return uid == otherTyped.uid && 
    phone == otherTyped.phone && 
    name == otherTyped.name && 
    email == otherTyped.email && 
    avatarInitials == otherTyped.avatarInitials && 
    isActive == otherTyped.isActive && 
    createdAt == otherTyped.createdAt && 
    assignments_on_enabler == otherTyped.assignments_on_enabler;
    
  }
  @override
  int get hashCode => Object.hashAll([uid.hashCode, phone.hashCode, name.hashCode, email.hashCode, avatarInitials.hashCode, isActive.hashCode, createdAt.hashCode, assignments_on_enabler.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    json['phone'] = nativeToJson<String>(phone);
    json['name'] = nativeToJson<String>(name);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (avatarInitials != null) {
      json['avatarInitials'] = nativeToJson<String?>(avatarInitials);
    }
    json['isActive'] = nativeToJson<bool>(isActive);
    json['createdAt'] = createdAt.toJson();
    json['assignments_on_enabler'] = assignments_on_enabler.map((e) => e.toJson()).toList();
    return json;
  }

  ListEnablersWithStatsUsers({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    this.avatarInitials,
    required this.isActive,
    required this.createdAt,
    required this.assignments_on_enabler,
  });
}

@immutable
class ListEnablersWithStatsUsersAssignmentsOnEnabler {
  final String id;
  final EnumValue<AssignmentStatus> status;
  ListEnablersWithStatsUsersAssignmentsOnEnabler.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = assignmentStatusDeserializer(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnablersWithStatsUsersAssignmentsOnEnabler otherTyped = other as ListEnablersWithStatsUsersAssignmentsOnEnabler;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    assignmentStatusSerializer(status)
    ;
    return json;
  }

  ListEnablersWithStatsUsersAssignmentsOnEnabler({
    required this.id,
    required this.status,
  });
}

@immutable
class ListEnablersWithStatsData {
  final List<ListEnablersWithStatsUsers> users;
  ListEnablersWithStatsData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListEnablersWithStatsUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnablersWithStatsData otherTyped = other as ListEnablersWithStatsData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListEnablersWithStatsData({
    required this.users,
  });
}

