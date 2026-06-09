part of 'default.dart';

class InsertContactVariablesBuilder {
  Optional<String> _syncStatus = Optional.optional(nativeFromJson, nativeToJson);
  String name;
  String mobile;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _whatsapp = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _dateOfBirth = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _age = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _folkAge = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _gender = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _folkId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _folkGuide = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _folkLevel = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _occupation = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _maritalStatus = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _language = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _livingStatus = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _address = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _permanentAddress = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _city = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _state = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _country = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _higherQualification = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _academicInstitution = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _institutionLocation = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _organization = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _designation = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _organizationLocation = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _residencyInterest = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _origin = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _journey = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _currentStatus = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastActivityType = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastActivity = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _lastSeen = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _yfhId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _yfhCity = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _center = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _stay = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _stream = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _highestQualification = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _source = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _talents = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _folkResidencyInterest = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _contactAddress = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _tShirtSize = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _sent = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _isEnabler = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
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

  InsertContactVariablesBuilder(this._dataConnect, {required  this.name,required  this.mobile,});
  Deserializer<InsertContactData> dataDeserializer = (dynamic json)  => InsertContactData.fromJson(jsonDecode(json));
  Serializer<InsertContactVariables> varsSerializer = (InsertContactVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<InsertContactData, InsertContactVariables>> execute() {
    return ref().execute();
  }

  MutationRef<InsertContactData, InsertContactVariables> ref() {
    InsertContactVariables vars= InsertContactVariables(syncStatus: _syncStatus,name: name,mobile: mobile,email: _email,whatsapp: _whatsapp,dateOfBirth: _dateOfBirth,age: _age,folkAge: _folkAge,gender: _gender,folkId: _folkId,folkGuide: _folkGuide,folkLevel: _folkLevel,occupation: _occupation,maritalStatus: _maritalStatus,language: _language,livingStatus: _livingStatus,address: _address,permanentAddress: _permanentAddress,city: _city,state: _state,country: _country,higherQualification: _higherQualification,academicInstitution: _academicInstitution,institutionLocation: _institutionLocation,organization: _organization,designation: _designation,organizationLocation: _organizationLocation,residencyInterest: _residencyInterest,origin: _origin,journey: _journey,currentStatus: _currentStatus,lastActivityType: _lastActivityType,lastActivity: _lastActivity,lastSeen: _lastSeen,yfhId: _yfhId,yfhCity: _yfhCity,center: _center,stay: _stay,stream: _stream,highestQualification: _highestQualification,source: _source,talents: _talents,folkResidencyInterest: _folkResidencyInterest,contactAddress: _contactAddress,tShirtSize: _tShirtSize,sent: _sent,isEnabler: _isEnabler,);
    return _dataConnect.mutation("InsertContact", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class InsertContactContactInsert {
  final String id;
  InsertContactContactInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertContactContactInsert otherTyped = other as InsertContactContactInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  InsertContactContactInsert({
    required this.id,
  });
}

@immutable
class InsertContactData {
  final InsertContactContactInsert contact_insert;
  InsertContactData.fromJson(dynamic json):
  
  contact_insert = InsertContactContactInsert.fromJson(json['contact_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertContactData otherTyped = other as InsertContactData;
    return contact_insert == otherTyped.contact_insert;
    
  }
  @override
  int get hashCode => contact_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['contact_insert'] = contact_insert.toJson();
    return json;
  }

  InsertContactData({
    required this.contact_insert,
  });
}

@immutable
class InsertContactVariables {
  late final Optional<String>syncStatus;
  final String name;
  final String mobile;
  late final Optional<String>email;
  late final Optional<String>whatsapp;
  late final Optional<String>dateOfBirth;
  late final Optional<int>age;
  late final Optional<String>folkAge;
  late final Optional<String>gender;
  late final Optional<String>folkId;
  late final Optional<String>folkGuide;
  late final Optional<String>folkLevel;
  late final Optional<String>occupation;
  late final Optional<String>maritalStatus;
  late final Optional<String>language;
  late final Optional<String>livingStatus;
  late final Optional<String>address;
  late final Optional<String>permanentAddress;
  late final Optional<String>city;
  late final Optional<String>state;
  late final Optional<String>country;
  late final Optional<String>higherQualification;
  late final Optional<String>academicInstitution;
  late final Optional<String>institutionLocation;
  late final Optional<String>organization;
  late final Optional<String>designation;
  late final Optional<String>organizationLocation;
  late final Optional<String>residencyInterest;
  late final Optional<String>origin;
  late final Optional<String>journey;
  late final Optional<String>currentStatus;
  late final Optional<String>lastActivityType;
  late final Optional<String>lastActivity;
  late final Optional<String>lastSeen;
  late final Optional<String>yfhId;
  late final Optional<String>yfhCity;
  late final Optional<String>center;
  late final Optional<String>stay;
  late final Optional<String>stream;
  late final Optional<String>highestQualification;
  late final Optional<String>source;
  late final Optional<String>talents;
  late final Optional<String>folkResidencyInterest;
  late final Optional<String>contactAddress;
  late final Optional<String>tShirtSize;
  late final Optional<String>sent;
  late final Optional<String>isEnabler;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  InsertContactVariables.fromJson(Map<String, dynamic> json):
  
  name = nativeFromJson<String>(json['name']),
  mobile = nativeFromJson<String>(json['mobile']) {
  
  
    syncStatus = Optional.optional(nativeFromJson, nativeToJson);
    syncStatus.value = json['syncStatus'] == null ? null : nativeFromJson<String>(json['syncStatus']);
  
  
  
  
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value = json['email'] == null ? null : nativeFromJson<String>(json['email']);
  
  
    whatsapp = Optional.optional(nativeFromJson, nativeToJson);
    whatsapp.value = json['whatsapp'] == null ? null : nativeFromJson<String>(json['whatsapp']);
  
  
    dateOfBirth = Optional.optional(nativeFromJson, nativeToJson);
    dateOfBirth.value = json['dateOfBirth'] == null ? null : nativeFromJson<String>(json['dateOfBirth']);
  
  
    age = Optional.optional(nativeFromJson, nativeToJson);
    age.value = json['age'] == null ? null : nativeFromJson<int>(json['age']);
  
  
    folkAge = Optional.optional(nativeFromJson, nativeToJson);
    folkAge.value = json['folkAge'] == null ? null : nativeFromJson<String>(json['folkAge']);
  
  
    gender = Optional.optional(nativeFromJson, nativeToJson);
    gender.value = json['gender'] == null ? null : nativeFromJson<String>(json['gender']);
  
  
    folkId = Optional.optional(nativeFromJson, nativeToJson);
    folkId.value = json['folkId'] == null ? null : nativeFromJson<String>(json['folkId']);
  
  
    folkGuide = Optional.optional(nativeFromJson, nativeToJson);
    folkGuide.value = json['folkGuide'] == null ? null : nativeFromJson<String>(json['folkGuide']);
  
  
    folkLevel = Optional.optional(nativeFromJson, nativeToJson);
    folkLevel.value = json['folkLevel'] == null ? null : nativeFromJson<String>(json['folkLevel']);
  
  
    occupation = Optional.optional(nativeFromJson, nativeToJson);
    occupation.value = json['occupation'] == null ? null : nativeFromJson<String>(json['occupation']);
  
  
    maritalStatus = Optional.optional(nativeFromJson, nativeToJson);
    maritalStatus.value = json['maritalStatus'] == null ? null : nativeFromJson<String>(json['maritalStatus']);
  
  
    language = Optional.optional(nativeFromJson, nativeToJson);
    language.value = json['language'] == null ? null : nativeFromJson<String>(json['language']);
  
  
    livingStatus = Optional.optional(nativeFromJson, nativeToJson);
    livingStatus.value = json['livingStatus'] == null ? null : nativeFromJson<String>(json['livingStatus']);
  
  
    address = Optional.optional(nativeFromJson, nativeToJson);
    address.value = json['address'] == null ? null : nativeFromJson<String>(json['address']);
  
  
    permanentAddress = Optional.optional(nativeFromJson, nativeToJson);
    permanentAddress.value = json['permanentAddress'] == null ? null : nativeFromJson<String>(json['permanentAddress']);
  
  
    city = Optional.optional(nativeFromJson, nativeToJson);
    city.value = json['city'] == null ? null : nativeFromJson<String>(json['city']);
  
  
    state = Optional.optional(nativeFromJson, nativeToJson);
    state.value = json['state'] == null ? null : nativeFromJson<String>(json['state']);
  
  
    country = Optional.optional(nativeFromJson, nativeToJson);
    country.value = json['country'] == null ? null : nativeFromJson<String>(json['country']);
  
  
    higherQualification = Optional.optional(nativeFromJson, nativeToJson);
    higherQualification.value = json['higherQualification'] == null ? null : nativeFromJson<String>(json['higherQualification']);
  
  
    academicInstitution = Optional.optional(nativeFromJson, nativeToJson);
    academicInstitution.value = json['academicInstitution'] == null ? null : nativeFromJson<String>(json['academicInstitution']);
  
  
    institutionLocation = Optional.optional(nativeFromJson, nativeToJson);
    institutionLocation.value = json['institutionLocation'] == null ? null : nativeFromJson<String>(json['institutionLocation']);
  
  
    organization = Optional.optional(nativeFromJson, nativeToJson);
    organization.value = json['organization'] == null ? null : nativeFromJson<String>(json['organization']);
  
  
    designation = Optional.optional(nativeFromJson, nativeToJson);
    designation.value = json['designation'] == null ? null : nativeFromJson<String>(json['designation']);
  
  
    organizationLocation = Optional.optional(nativeFromJson, nativeToJson);
    organizationLocation.value = json['organizationLocation'] == null ? null : nativeFromJson<String>(json['organizationLocation']);
  
  
    residencyInterest = Optional.optional(nativeFromJson, nativeToJson);
    residencyInterest.value = json['residencyInterest'] == null ? null : nativeFromJson<String>(json['residencyInterest']);
  
  
    origin = Optional.optional(nativeFromJson, nativeToJson);
    origin.value = json['origin'] == null ? null : nativeFromJson<String>(json['origin']);
  
  
    journey = Optional.optional(nativeFromJson, nativeToJson);
    journey.value = json['journey'] == null ? null : nativeFromJson<String>(json['journey']);
  
  
    currentStatus = Optional.optional(nativeFromJson, nativeToJson);
    currentStatus.value = json['currentStatus'] == null ? null : nativeFromJson<String>(json['currentStatus']);
  
  
    lastActivityType = Optional.optional(nativeFromJson, nativeToJson);
    lastActivityType.value = json['lastActivityType'] == null ? null : nativeFromJson<String>(json['lastActivityType']);
  
  
    lastActivity = Optional.optional(nativeFromJson, nativeToJson);
    lastActivity.value = json['lastActivity'] == null ? null : nativeFromJson<String>(json['lastActivity']);
  
  
    lastSeen = Optional.optional(nativeFromJson, nativeToJson);
    lastSeen.value = json['lastSeen'] == null ? null : nativeFromJson<String>(json['lastSeen']);
  
  
    yfhId = Optional.optional(nativeFromJson, nativeToJson);
    yfhId.value = json['yfhId'] == null ? null : nativeFromJson<String>(json['yfhId']);
  
  
    yfhCity = Optional.optional(nativeFromJson, nativeToJson);
    yfhCity.value = json['yfhCity'] == null ? null : nativeFromJson<String>(json['yfhCity']);
  
  
    center = Optional.optional(nativeFromJson, nativeToJson);
    center.value = json['center'] == null ? null : nativeFromJson<String>(json['center']);
  
  
    stay = Optional.optional(nativeFromJson, nativeToJson);
    stay.value = json['stay'] == null ? null : nativeFromJson<String>(json['stay']);
  
  
    stream = Optional.optional(nativeFromJson, nativeToJson);
    stream.value = json['stream'] == null ? null : nativeFromJson<String>(json['stream']);
  
  
    highestQualification = Optional.optional(nativeFromJson, nativeToJson);
    highestQualification.value = json['highestQualification'] == null ? null : nativeFromJson<String>(json['highestQualification']);
  
  
    source = Optional.optional(nativeFromJson, nativeToJson);
    source.value = json['source'] == null ? null : nativeFromJson<String>(json['source']);
  
  
    talents = Optional.optional(nativeFromJson, nativeToJson);
    talents.value = json['talents'] == null ? null : nativeFromJson<String>(json['talents']);
  
  
    folkResidencyInterest = Optional.optional(nativeFromJson, nativeToJson);
    folkResidencyInterest.value = json['folkResidencyInterest'] == null ? null : nativeFromJson<String>(json['folkResidencyInterest']);
  
  
    contactAddress = Optional.optional(nativeFromJson, nativeToJson);
    contactAddress.value = json['contactAddress'] == null ? null : nativeFromJson<String>(json['contactAddress']);
  
  
    tShirtSize = Optional.optional(nativeFromJson, nativeToJson);
    tShirtSize.value = json['tShirtSize'] == null ? null : nativeFromJson<String>(json['tShirtSize']);
  
  
    sent = Optional.optional(nativeFromJson, nativeToJson);
    sent.value = json['sent'] == null ? null : nativeFromJson<String>(json['sent']);
  
  
    isEnabler = Optional.optional(nativeFromJson, nativeToJson);
    isEnabler.value = json['isEnabler'] == null ? null : nativeFromJson<String>(json['isEnabler']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final InsertContactVariables otherTyped = other as InsertContactVariables;
    return syncStatus == otherTyped.syncStatus && 
    name == otherTyped.name && 
    mobile == otherTyped.mobile && 
    email == otherTyped.email && 
    whatsapp == otherTyped.whatsapp && 
    dateOfBirth == otherTyped.dateOfBirth && 
    age == otherTyped.age && 
    folkAge == otherTyped.folkAge && 
    gender == otherTyped.gender && 
    folkId == otherTyped.folkId && 
    folkGuide == otherTyped.folkGuide && 
    folkLevel == otherTyped.folkLevel && 
    occupation == otherTyped.occupation && 
    maritalStatus == otherTyped.maritalStatus && 
    language == otherTyped.language && 
    livingStatus == otherTyped.livingStatus && 
    address == otherTyped.address && 
    permanentAddress == otherTyped.permanentAddress && 
    city == otherTyped.city && 
    state == otherTyped.state && 
    country == otherTyped.country && 
    higherQualification == otherTyped.higherQualification && 
    academicInstitution == otherTyped.academicInstitution && 
    institutionLocation == otherTyped.institutionLocation && 
    organization == otherTyped.organization && 
    designation == otherTyped.designation && 
    organizationLocation == otherTyped.organizationLocation && 
    residencyInterest == otherTyped.residencyInterest && 
    origin == otherTyped.origin && 
    journey == otherTyped.journey && 
    currentStatus == otherTyped.currentStatus && 
    lastActivityType == otherTyped.lastActivityType && 
    lastActivity == otherTyped.lastActivity && 
    lastSeen == otherTyped.lastSeen && 
    yfhId == otherTyped.yfhId && 
    yfhCity == otherTyped.yfhCity && 
    center == otherTyped.center && 
    stay == otherTyped.stay && 
    stream == otherTyped.stream && 
    highestQualification == otherTyped.highestQualification && 
    source == otherTyped.source && 
    talents == otherTyped.talents && 
    folkResidencyInterest == otherTyped.folkResidencyInterest && 
    contactAddress == otherTyped.contactAddress && 
    tShirtSize == otherTyped.tShirtSize && 
    sent == otherTyped.sent && 
    isEnabler == otherTyped.isEnabler;
    
  }
  @override
  int get hashCode => Object.hashAll([syncStatus.hashCode, name.hashCode, mobile.hashCode, email.hashCode, whatsapp.hashCode, dateOfBirth.hashCode, age.hashCode, folkAge.hashCode, gender.hashCode, folkId.hashCode, folkGuide.hashCode, folkLevel.hashCode, occupation.hashCode, maritalStatus.hashCode, language.hashCode, livingStatus.hashCode, address.hashCode, permanentAddress.hashCode, city.hashCode, state.hashCode, country.hashCode, higherQualification.hashCode, academicInstitution.hashCode, institutionLocation.hashCode, organization.hashCode, designation.hashCode, organizationLocation.hashCode, residencyInterest.hashCode, origin.hashCode, journey.hashCode, currentStatus.hashCode, lastActivityType.hashCode, lastActivity.hashCode, lastSeen.hashCode, yfhId.hashCode, yfhCity.hashCode, center.hashCode, stay.hashCode, stream.hashCode, highestQualification.hashCode, source.hashCode, talents.hashCode, folkResidencyInterest.hashCode, contactAddress.hashCode, tShirtSize.hashCode, sent.hashCode, isEnabler.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(syncStatus.state == OptionalState.set) {
      json['syncStatus'] = syncStatus.toJson();
    }
    json['name'] = nativeToJson<String>(name);
    json['mobile'] = nativeToJson<String>(mobile);
    if(email.state == OptionalState.set) {
      json['email'] = email.toJson();
    }
    if(whatsapp.state == OptionalState.set) {
      json['whatsapp'] = whatsapp.toJson();
    }
    if(dateOfBirth.state == OptionalState.set) {
      json['dateOfBirth'] = dateOfBirth.toJson();
    }
    if(age.state == OptionalState.set) {
      json['age'] = age.toJson();
    }
    if(folkAge.state == OptionalState.set) {
      json['folkAge'] = folkAge.toJson();
    }
    if(gender.state == OptionalState.set) {
      json['gender'] = gender.toJson();
    }
    if(folkId.state == OptionalState.set) {
      json['folkId'] = folkId.toJson();
    }
    if(folkGuide.state == OptionalState.set) {
      json['folkGuide'] = folkGuide.toJson();
    }
    if(folkLevel.state == OptionalState.set) {
      json['folkLevel'] = folkLevel.toJson();
    }
    if(occupation.state == OptionalState.set) {
      json['occupation'] = occupation.toJson();
    }
    if(maritalStatus.state == OptionalState.set) {
      json['maritalStatus'] = maritalStatus.toJson();
    }
    if(language.state == OptionalState.set) {
      json['language'] = language.toJson();
    }
    if(livingStatus.state == OptionalState.set) {
      json['livingStatus'] = livingStatus.toJson();
    }
    if(address.state == OptionalState.set) {
      json['address'] = address.toJson();
    }
    if(permanentAddress.state == OptionalState.set) {
      json['permanentAddress'] = permanentAddress.toJson();
    }
    if(city.state == OptionalState.set) {
      json['city'] = city.toJson();
    }
    if(state.state == OptionalState.set) {
      json['state'] = state.toJson();
    }
    if(country.state == OptionalState.set) {
      json['country'] = country.toJson();
    }
    if(higherQualification.state == OptionalState.set) {
      json['higherQualification'] = higherQualification.toJson();
    }
    if(academicInstitution.state == OptionalState.set) {
      json['academicInstitution'] = academicInstitution.toJson();
    }
    if(institutionLocation.state == OptionalState.set) {
      json['institutionLocation'] = institutionLocation.toJson();
    }
    if(organization.state == OptionalState.set) {
      json['organization'] = organization.toJson();
    }
    if(designation.state == OptionalState.set) {
      json['designation'] = designation.toJson();
    }
    if(organizationLocation.state == OptionalState.set) {
      json['organizationLocation'] = organizationLocation.toJson();
    }
    if(residencyInterest.state == OptionalState.set) {
      json['residencyInterest'] = residencyInterest.toJson();
    }
    if(origin.state == OptionalState.set) {
      json['origin'] = origin.toJson();
    }
    if(journey.state == OptionalState.set) {
      json['journey'] = journey.toJson();
    }
    if(currentStatus.state == OptionalState.set) {
      json['currentStatus'] = currentStatus.toJson();
    }
    if(lastActivityType.state == OptionalState.set) {
      json['lastActivityType'] = lastActivityType.toJson();
    }
    if(lastActivity.state == OptionalState.set) {
      json['lastActivity'] = lastActivity.toJson();
    }
    if(lastSeen.state == OptionalState.set) {
      json['lastSeen'] = lastSeen.toJson();
    }
    if(yfhId.state == OptionalState.set) {
      json['yfhId'] = yfhId.toJson();
    }
    if(yfhCity.state == OptionalState.set) {
      json['yfhCity'] = yfhCity.toJson();
    }
    if(center.state == OptionalState.set) {
      json['center'] = center.toJson();
    }
    if(stay.state == OptionalState.set) {
      json['stay'] = stay.toJson();
    }
    if(stream.state == OptionalState.set) {
      json['stream'] = stream.toJson();
    }
    if(highestQualification.state == OptionalState.set) {
      json['highestQualification'] = highestQualification.toJson();
    }
    if(source.state == OptionalState.set) {
      json['source'] = source.toJson();
    }
    if(talents.state == OptionalState.set) {
      json['talents'] = talents.toJson();
    }
    if(folkResidencyInterest.state == OptionalState.set) {
      json['folkResidencyInterest'] = folkResidencyInterest.toJson();
    }
    if(contactAddress.state == OptionalState.set) {
      json['contactAddress'] = contactAddress.toJson();
    }
    if(tShirtSize.state == OptionalState.set) {
      json['tShirtSize'] = tShirtSize.toJson();
    }
    if(sent.state == OptionalState.set) {
      json['sent'] = sent.toJson();
    }
    if(isEnabler.state == OptionalState.set) {
      json['isEnabler'] = isEnabler.toJson();
    }
    return json;
  }

  InsertContactVariables({
    required this.syncStatus,
    required this.name,
    required this.mobile,
    required this.email,
    required this.whatsapp,
    required this.dateOfBirth,
    required this.age,
    required this.folkAge,
    required this.gender,
    required this.folkId,
    required this.folkGuide,
    required this.folkLevel,
    required this.occupation,
    required this.maritalStatus,
    required this.language,
    required this.livingStatus,
    required this.address,
    required this.permanentAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.higherQualification,
    required this.academicInstitution,
    required this.institutionLocation,
    required this.organization,
    required this.designation,
    required this.organizationLocation,
    required this.residencyInterest,
    required this.origin,
    required this.journey,
    required this.currentStatus,
    required this.lastActivityType,
    required this.lastActivity,
    required this.lastSeen,
    required this.yfhId,
    required this.yfhCity,
    required this.center,
    required this.stay,
    required this.stream,
    required this.highestQualification,
    required this.source,
    required this.talents,
    required this.folkResidencyInterest,
    required this.contactAddress,
    required this.tShirtSize,
    required this.sent,
    required this.isEnabler,
  });
}

