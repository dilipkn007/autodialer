part of 'default.dart';

class ListContactsVariablesBuilder {
  Optional<String> _search = Optional.optional(nativeFromJson, nativeToJson);
  int limit;
  int offset;

  final FirebaseDataConnect _dataConnect;
  ListContactsVariablesBuilder search(String? t) {
   _search.value = t;
   return this;
  }

  ListContactsVariablesBuilder(this._dataConnect, {required  this.limit,required  this.offset,});
  Deserializer<ListContactsData> dataDeserializer = (dynamic json)  => ListContactsData.fromJson(jsonDecode(json));
  Serializer<ListContactsVariables> varsSerializer = (ListContactsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListContactsData, ListContactsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListContactsData, ListContactsVariables> ref() {
    ListContactsVariables vars= ListContactsVariables(search: _search,limit: limit,offset: offset,);
    return _dataConnect.query("ListContacts", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListContactsContacts {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? folkId;
  final String? city;
  final String? center;
  final String? currentStatus;
  final String? folkGuide;
  final String? folkLevel;
  final Timestamp createdAt;
  ListContactsContacts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  folkId = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']),
  city = json['city'] == null ? null : nativeFromJson<String>(json['city']),
  center = json['center'] == null ? null : nativeFromJson<String>(json['center']),
  currentStatus = json['currentStatus'] == null ? null : nativeFromJson<String>(json['currentStatus']),
  folkGuide = json['folkGuide'] == null ? null : nativeFromJson<String>(json['folkGuide']),
  folkLevel = json['folkLevel'] == null ? null : nativeFromJson<String>(json['folkLevel']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListContactsContacts otherTyped = other as ListContactsContacts;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    email == otherTyped.email && 
    folkId == otherTyped.folkId && 
    city == otherTyped.city && 
    center == otherTyped.center && 
    currentStatus == otherTyped.currentStatus && 
    folkGuide == otherTyped.folkGuide && 
    folkLevel == otherTyped.folkLevel && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, mobile.hashCode, email.hashCode, folkId.hashCode, city.hashCode, center.hashCode, currentStatus.hashCode, folkGuide.hashCode, folkLevel.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (folkId != null) {
      json['folkId'] = nativeToJson<String?>(folkId);
    }
    if (city != null) {
      json['city'] = nativeToJson<String?>(city);
    }
    if (center != null) {
      json['center'] = nativeToJson<String?>(center);
    }
    if (currentStatus != null) {
      json['currentStatus'] = nativeToJson<String?>(currentStatus);
    }
    if (folkGuide != null) {
      json['folkGuide'] = nativeToJson<String?>(folkGuide);
    }
    if (folkLevel != null) {
      json['folkLevel'] = nativeToJson<String?>(folkLevel);
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListContactsContacts({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.folkId,
    this.city,
    this.center,
    this.currentStatus,
    this.folkGuide,
    this.folkLevel,
    required this.createdAt,
  });
}

@immutable
class ListContactsData {
  final List<ListContactsContacts> contacts;
  ListContactsData.fromJson(dynamic json):
  
  contacts = (json['contacts'] as List<dynamic>)
        .map((e) => ListContactsContacts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListContactsData otherTyped = other as ListContactsData;
    return contacts == otherTyped.contacts;
    
  }
  @override
  int get hashCode => contacts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['contacts'] = contacts.map((e) => e.toJson()).toList();
    return json;
  }

  ListContactsData({
    required this.contacts,
  });
}

@immutable
class ListContactsVariables {
  late final Optional<String>search;
  final int limit;
  final int offset;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListContactsVariables.fromJson(Map<String, dynamic> json):
  
  limit = nativeFromJson<int>(json['limit']),
  offset = nativeFromJson<int>(json['offset']) {
  
  
    search = Optional.optional(nativeFromJson, nativeToJson);
    search.value = json['search'] == null ? null : nativeFromJson<String>(json['search']);
  
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListContactsVariables otherTyped = other as ListContactsVariables;
    return search == otherTyped.search && 
    limit == otherTyped.limit && 
    offset == otherTyped.offset;
    
  }
  @override
  int get hashCode => Object.hashAll([search.hashCode, limit.hashCode, offset.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(search.state == OptionalState.set) {
      json['search'] = search.toJson();
    }
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    return json;
  }

  ListContactsVariables({
    required this.search,
    required this.limit,
    required this.offset,
  });
}

